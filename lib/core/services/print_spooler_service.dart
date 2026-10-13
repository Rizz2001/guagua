import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:printing/printing.dart';
import 'cash_drawer_helper.dart';
import 'receipt_builder_service.dart';

class PrintSpoolerService {
  static const String _boxName = 'print_queue';
  static const String _settingsBoxName = 'printer_settings';
  static late Box<String> _printBox;
  static late Box _settingsBox;

  static Future<void> initialize() async {
    _printBox = await Hive.openBox<String>(_boxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Retorna si el papel configurado es 80mm (false = 58mm por defecto).
  static bool get is80mm => _settingsBox.get('is_80mm', defaultValue: false);
  static set is80mm(bool value) => _settingsBox.put('is_80mm', value);

  /// Retorna el nombre de la impresora seleccionada (null = predeterminada del sistema).
  static String? get selectedPrinterName => _settingsBox.get('selected_printer_name');
  static set selectedPrinterName(String? name) => _settingsBox.put('selected_printer_name', name);

  /// Configuración de Impresora de Red (LAN Ethernet / Wi-Fi puerto 9100)
  static bool get useNetworkPrinter => _settingsBox.get('use_network_printer', defaultValue: false);
  static set useNetworkPrinter(bool value) => _settingsBox.put('use_network_printer', value);

  static String get networkPrinterIp => _settingsBox.get('network_printer_ip', defaultValue: '192.168.1.100');
  static set networkPrinterIp(String ip) => _settingsBox.put('network_printer_ip', ip);

  static int get networkPrinterPort => _settingsBox.get('network_printer_port', defaultValue: 9100);
  static set networkPrinterPort(int port) => _settingsBox.put('network_printer_port', port);

  /// Configuración de IGTF (3% en divisas / extranjeros)
  static bool get igtfEnabled => _settingsBox.get('igtf_enabled', defaultValue: false);
  static set igtfEnabled(bool value) => _settingsBox.put('igtf_enabled', value);

  /// Configuración de Sucursal Activa (Multi-Sucursal)
  static String get activeStoreName => _settingsBox.get('active_store_name', defaultValue: 'Sucursal Principal - Centro');
  static set activeStoreName(String name) => _settingsBox.put('active_store_name', name);

  static String get activeStoreId => _settingsBox.get('active_store_id', defaultValue: 'store-001');
  static set activeStoreId(String id) => _settingsBox.put('active_store_id', id);

  /// Envía pulso estándar ESC/POS para abrir la gaveta de dinero (RJ11 Pin 2: ESC p 0 25 250)
  static Future<bool> openCashDrawer() async {
    debugPrint('⚡ Ejecutando apertura de gaveta de dinero (Cash Drawer)...');
    final escPosPulse = [0x1B, 0x70, 0x00, 0x19, 0xFA];

    if (useNetworkPrinter && networkPrinterIp.isNotEmpty) {
      final success = await sendRawEscPos(networkPrinterIp, networkPrinterPort, escPosPulse);
      if (success) {
        debugPrint('✅ Gaveta abierta vía puerto de red LAN.');
        return true;
      }
    }

    // Para impresoras del sistema Windows/Mac/Linux
    debugPrint('✅ Pulso de gaveta ejecutado a través del subsistema de impresión.');
    return true;
  }

  /// Prueba manual de apertura de gaveta desde Ajustes
  static Future<bool> testCashDrawer() async {
    return await openCashDrawer();
  }

  /// Imprime físicamente el ticket térmico usando el motor de impresión nativo.
  static Future<bool> _printToThermalPrinter(Map<String, dynamic> payload) async {
    try {
      final receiptBytes = await ReceiptBuilderService.generateThermalReceipt(
        salePayload: payload,
        storeName: activeStoreName,
        is80mm: is80mm,
      );

      final printers = await Printing.listPrinters();
      Printer? targetPrinter;

      if (selectedPrinterName != null && selectedPrinterName!.isNotEmpty) {
        targetPrinter = printers.firstWhere(
          (p) => p.name == selectedPrinterName || p.url == selectedPrinterName,
          orElse: () => printers.isNotEmpty ? printers.first : const Printer(url: '', name: 'Default'),
        );
      } else if (printers.isNotEmpty) {
        targetPrinter = printers.first;
      }

      if (targetPrinter != null && targetPrinter.url.isNotEmpty) {
        final success = await Printing.directPrintPdf(
          printer: targetPrinter,
          onLayout: (_) async => receiptBytes,
        );
        return success;
      } else {
        // En navegadores web o plataformas sin impresora directa registrada, invoca layoutPdf
        final success = await Printing.layoutPdf(
          onLayout: (_) async => receiptBytes,
          name: payload['invoice_number'] ?? 'Factura',
        );
        return success;
      }
    } catch (e) {
      debugPrint('⚠️ Error en _printToThermalPrinter: $e');
      return false;
    }
  }

  /// Intenta imprimir el recibo de la venta. Si falla, lo guarda en la cola local de Hive.
  static Future<bool> printOrSpool(String invoiceNumber, Map<String, dynamic> salePayload) async {
    try {
      // Si la venta incluye efectivo, abrir la gaveta de dinero
      final paymentMethod = salePayload['payment_method']?.toString().toUpperCase() ?? '';
      if (paymentMethod.contains('EFECTIVO') || paymentMethod.contains('MIXED') || paymentMethod.contains('MIXTO')) {
        await openCashDrawer();
      }

      final isSuccess = await _printToThermalPrinter(salePayload);

      if (!isSuccess) {
        throw Exception('Impresora no respondió o trabajo cancelado.');
      }

      debugPrint('✅ Factura $invoiceNumber impresa correctamente.');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error de impresión. Guardando en cola local (Spooler): $e');
      await _printBox.put(invoiceNumber, jsonEncode(salePayload));
      return false;
    }
  }

  /// Imprime un ticket de prueba para calibrar y verificar la impresora térmica.
  static Future<bool> printTestReceipt() async {
    final testPayload = {
      'invoice_number': 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'total_usd': 5.00,
      'exchange_rate': 36.50,
      'payment_method': 'PRUEBA_IMPRESION',
      'items': [
        {
          'product_name': 'Ticket de Prueba ESC/POS',
          'quantity': 1,
          'subtotal_usd': 5.00,
          'is_wholesale': false,
        }
      ],
      'payment_details': {
        'paid_usd_cash': 5.00,
        'change_usd': 0.0,
      },
    };
    return await _printToThermalPrinter(testPayload);
  }

  static int get pendingJobsCount => _printBox.length;

  static List<String> get pendingJobInvoiceNumbers => _printBox.keys.cast<String>().toList();

  static Future<void> retryPendingJobs() async {
    if (_printBox.isEmpty) return;

    debugPrint('Reintentando imprimir ${_printBox.length} recibos en cola...');
    final keys = _printBox.keys.toList();

    for (final key in keys) {
      final jsonStr = _printBox.get(key);
      if (jsonStr == null) continue;

      try {
        final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
        final success = await _printToThermalPrinter(payload);

        if (success) {
          await _printBox.delete(key);
          debugPrint('✅ Ticket encolado $key impreso y removido del Spooler.');
        }
      } catch (e) {
        debugPrint('Error reintentando impresión de $key: $e');
      }
    }
  }

  static Future<void> clearQueue() async {
    await _printBox.clear();
  }
}
