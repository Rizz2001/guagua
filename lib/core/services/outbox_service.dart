import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Servicio encargado de la persistencia local de ventas y sincronización asíncrona.
class OutboxService {
  static const String _salesBoxName = 'sales_outbox';
  static late Box<String> _salesBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _salesBox = await Hive.openBox<String>(_salesBoxName);
  }

  /// Guarda una venta en Hive (con su tasa y precios inmutables) y luego intenta sincronizar.
  static Future<void> saveSaleAndTrySync(Map<String, dynamic> salePayload) async {
    final String id = salePayload['invoice_number'];
    
    // Convertimos la payload a JSON para guardarla genéricamente
    final String jsonPayload = jsonEncode(salePayload);
    
    // 1. Guardar en la caja (Cola Local Offline)
    await _salesBox.put(id, jsonPayload);
    debugPrint('Venta $id guardada en Hive (Offline Queue). Tasa Inmutable: ${salePayload['exchange_rate']}');

    // 2. Intentar sincronizar si hay internet
    _trySyncPendingSales();
  }

  /// Lee todas las ventas pendientes e intenta enviarlas a Supabase.
  static Future<void> _trySyncPendingSales() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('No hay internet. La venta se mantiene en Hive.');
      return;
    }

    final client = SupabaseService().client;
    if (client == null) return;

    final pendingKeys = _salesBox.keys.toList();
    if (pendingKeys.isEmpty) return;

    debugPrint('Iniciando sincronización de ${pendingKeys.length} ventas pendientes...');

    for (final key in pendingKeys) {
      try {
        final String? jsonPayload = _salesBox.get(key);
        if (jsonPayload == null) continue;

        final Map<String, dynamic> salePayload = jsonDecode(jsonPayload);

        // EXTRAER LA TASA Y PRECIOS INMUTABLES
        final double frozenRate = salePayload['exchange_rate'];
        
        // 1. Insertar Venta Principal
        final saleRes = await client.from('sales').insert({
          'invoice_number': salePayload['invoice_number'],
          'cashier_id': salePayload['cashier_id'],
          'total_usd': salePayload['total_usd'],
          'exchange_rate': frozenRate, // TASA CONGELADA DESDE HIVE
          'payment_method': salePayload['payment_method'],
          'payment_details': salePayload['payment_details'],
          'status': 'COMPLETED',
        }).select().single();

        final saleId = saleRes['id'];

        // 2. Insertar Ítems y Desarmar
        final List<dynamic> items = salePayload['items'];
        for (final item in items) {
          await client.from('sale_items').insert({
            'sale_id': saleId,
            'product_id': item['product_id'],
            'product_name': item['product_name'],
            'quantity': item['quantity'],
            'unit_price_usd': item['unit_price_usd'], // PRECIO USD CONGELADO
            'unit_price_bs': item['unit_price_bs'],   // PRECIO BS CONGELADO
            'subtotal_usd': item['subtotal_usd'],
          });

          // Llamada RPC de Supabase (Desarmado Automático)
          await client.rpc('desarmar_caja_si_es_necesario', params: {
            'p_product_id': item['product_id'],
            'p_qty_needed': item['quantity'],
          });
        }

        // Si tuvo éxito, borrar de Hive
        await _salesBox.delete(key);
        debugPrint('Sincronización exitosa. Venta eliminada de Hive: $key');
      } catch (e) {
        debugPrint('Error sincronizando venta $key: $e');
        // Si hay error (ej. se cayó el internet a la mitad), se mantiene en Hive para el próximo intento
      }
    }
  }

  /// Esto debería llamarse cuando la app arranca o cuando la conexión vuelve (Listener global)
  static void listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.none)) {
        debugPrint('Conexión recuperada. Intentando sincronizar...');
        _trySyncPendingSales();
      }
    });
  }
}
