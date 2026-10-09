import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

/// Servicio singleton para interactuar con la API y Base de Datos de Supabase.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Retorna la instancia del cliente Supabase de forma segura.
  SupabaseClient? get client {
    if (!SupabaseConstants.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Inicializa la conexión con Supabase en la arranque de la app.
  static Future<void> initialize() async {
    if (!SupabaseConstants.isConfigured) {
      debugPrint('ℹ️ [SupabaseService] Credenciales no configuradas. La aplicación operará en modo demostración local.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
      debugPrint('⚡ [SupabaseService] Conectado exitosamente a Supabase.');
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Error inicializando Supabase: $e');
    }
  }

  // --------------------------------------------------------------------------
  // LÓGICA DE MULTIMONEDA & TASA DEL DÍA
  // --------------------------------------------------------------------------

  /// Obtiene la tasa activa registrada en la base de datos (con fallback a 36.50).
  Future<double> getActiveExchangeRate() async {
    if (client == null) return 36.50;
    try {
      final response = await client!.rpc('obtener_tasa_activa');
      return (response as num).toDouble();
    } catch (e) {
      debugPrint('Error obteniendo tasa activa desde Supabase: $e');
      return 36.50;
    }
  }

  /// Actualiza la tasa diaria manualmente en Supabase (Solo Admin/Supervisor).
  Future<bool> updateDailyExchangeRate(double newRate, String userId) async {
    if (client == null) return true;
    try {
      final response = await client!.rpc('actualizar_tasa_diaria', params: {
        'p_rate_bcv': newRate,
        'p_user_id': userId,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error actualizando tasa diaria en Supabase: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // LÓGICA DE INVENTARIO Y COSTO PROMEDIO PONDERADO (CPP)
  // --------------------------------------------------------------------------

  /// Registra una compra de proveedor y actualiza stock + recálculo de CPP en PostgreSQL.
  Future<bool> recordSupplierPurchase({
    required String supplierName,
    required String userId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (client == null) return true;
    try {
      final response = await client!.rpc('recepcionar_compra_proveedor', params: {
        'p_supplier_name': supplierName,
        'p_user_id': userId,
        'p_items': items,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error en recepcionar_compra_proveedor: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // LÓGICA DE CRÉDITO Y CUENTAS POR COBRAR
  // --------------------------------------------------------------------------

  /// Valida si el cliente tiene cupo de crédito disponible para una venta.
  Future<bool> checkCreditLimit(String clientId, double saleAmountUsd) async {
    if (client == null) return true;
    try {
      final response = await client!.rpc('validar_cupo_credito', params: {
        'p_client_id': clientId,
        'p_new_sale_usd': saleAmountUsd,
      });
      return response == true;
    } catch (e) {
      debugPrint('Exceso de límite de crédito o error: $e');
      return false;
    }
  }
}
