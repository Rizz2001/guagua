import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PrintSpoolerService {
  static const String _boxName = 'print_queue';
  static late Box<String> _printBox;

  static Future<void> initialize() async {
    _printBox = await Hive.openBox<String>(_boxName);
  }

  /// Función simulada de impresión térmica. En el futuro conectará con la SDK de la impresora.
  static Future<bool> _printToThermalPrinter(Map<String, dynamic> payload) async {
    // Simulamos fallo (no hay impresora conectada físicamente)
    return Future.value(false);
  }

  /// Intenta imprimir el recibo de la venta. Si falla, lo guarda en la cola.
  static Future<bool> printOrSpool(String invoiceNumber, Map<String, dynamic> salePayload) async {
    try {
      final isSuccess = await _printToThermalPrinter(salePayload);

      if (!isSuccess) {
        throw Exception('Impresora no encontrada o sin papel.');
      }

      debugPrint('✅ Factura $invoiceNumber impresa correctamente.');
      return true;

    } catch (e) {
      debugPrint('⚠️ Error de impresión. Enviando a la cola local (Spooler): $e');
      await _printBox.put(invoiceNumber, jsonEncode(salePayload));
      return false; // Retornamos false para que la UI sepa que se fue a la cola
    }
  }

  static int get pendingJobsCount => _printBox.length;

  static Future<void> retryPendingJobs() async {
    if (_printBox.isEmpty) return;
    
    debugPrint('Intentando imprimir ${_printBox.length} recibos en cola...');
    final keys = _printBox.keys.toList();
    
    for (final key in keys) {
      final jsonStr = _printBox.get(key);
      if (jsonStr == null) continue;

      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Intentamos imprimir de nuevo
      final success = await _printToThermalPrinter(payload);
      
      if (success) {
        await _printBox.delete(key);
      }
    }
  }
}
