import 'package:url_launcher/url_launcher.dart';
import '../utils/currency_engine.dart';
import 'print_spooler_service.dart';

class WhatsAppService {
  WhatsAppService._();

  /// Envia el recibo digital de una venta por WhatsApp con formato Markdown profesional
  static Future<void> sendDigitalReceipt({
    required String phone,
    required String clientName,
    required String receiptId,
    required double totalUsd,
    required double exchangeRate,
    required List<Map<String, dynamic>> itemsSummary,
    String? storeName,
  }) async {
    final double totalVes = CurrencyEngine.usdToVes(totalUsd, exchangeRate);
    final String businessName = storeName ?? PrintSpoolerService.activeStoreName;

    final StringBuffer itemsText = StringBuffer();
    for (final item in itemsSummary) {
      final name = item['name'] ?? 'Producto';
      final qty = item['qty'] ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final isWholesale = item['is_wholesale'] == true;
      itemsText.writeln('• $qty x $name ${isWholesale ? "[MAYOR]" : ""} - \$${price.toStringAsFixed(2)}');
    }

    final String message = Uri.encodeComponent(
      '🏪 *$businessName*\n'
      '¡Hola *$clientName*, gracias por tu preferencia! 🛍️✨\n\n'
      '🧾 *COMPROBANTE DIGITAL #$receiptId*\n'
      '--------------------------------\n'
      '${itemsText.toString()}'
      '--------------------------------\n'
      '💵 *TOTAL USD:* \$${totalUsd.toStringAsFixed(2)}\n'
      '🇻🇪 *TOTAL VES:* Bs. ${totalVes.toStringAsFixed(2)} (Tasa Oficial: $exchangeRate)\n\n'
      '🌐 *Consulta tu ticket web:* https://guagua-pos.web.app/receipt/$receiptId\n\n'
      '¡Esperamos verte pronto de nuevo! 🙏🏼'
    );

    await _launchWhatsAppUrl(phone, message);
  }

  /// Envía un estado de cuenta profesional en 1 toque a un cliente deudor
  static Future<void> sendDebtReminder({
    required String phone,
    required String clientName,
    required double totalDueUsd,
    required double exchangeRate,
    int daysOverdue = 0,
    String? storeName,
    String? pagoMovilDetails,
    String? zelleDetails,
  }) async {
    final double totalDueVes = CurrencyEngine.usdToVes(totalDueUsd, exchangeRate);
    final String businessName = storeName ?? PrintSpoolerService.activeStoreName;

    String moraBadge;
    if (daysOverdue >= 30) {
      moraBadge = '🔴 *Mora Crítica:* $daysOverdue días de vencimiento';
    } else if (daysOverdue >= 8) {
      moraBadge = '🍊 *Mora Intermedia:* $daysOverdue días de vencimiento';
    } else if (daysOverdue >= 1) {
      moraBadge = '🟡 *Recordatorio Amigable:* $daysOverdue días';
    } else {
      moraBadge = '🟢 *Cuenta al Día:* Factura reciente';
    }

    final String pmData = pagoMovilDetails ?? 'Banesco (0134) | CI/RIF: J-50192837-0 | Tel: 0414-1234567';
    final String zelleData = zelleDetails ?? 'pagos@guagua-pos.com (Comercial Guagua)';

    final String message = Uri.encodeComponent(
      '🏪 *$businessName*\n'
      'Estimado(a) *$clientName*, gusto en saludarte. 👋🏼\n\n'
      'Te enviamos el resumen actualizado de tu estado de cuenta:\n'
      '--------------------------------\n'
      '🔹 *Saldo Pendiente:* \$${totalDueUsd.toStringAsFixed(2)} USD\n'
      '🔹 *Equivalente VES:* Bs. ${totalDueVes.toStringAsFixed(2)} (Tasa BCV: $exchangeRate)\n'
      '🔹 $moraBadge\n'
      '--------------------------------\n\n'
      '📌 *Canales de Pago Autorizados:*\n'
      '📱 *Pago Móvil:* $pmData\n'
      '💵 *Zelle:* $zelleData\n\n'
      'Agradecemos enviarnos tu comprobante de pago por este chat al efectuar la transferencia. ¡Feliz día! 🙏🏼'
    );

    await _launchWhatsAppUrl(phone, message);
  }

  static Future<void> _launchWhatsAppUrl(String phone, String encodedMessage) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final Uri whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('No se pudo abrir WhatsApp en este dispositivo.');
    }
  }
}
