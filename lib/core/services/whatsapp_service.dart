import 'package:url_launcher/url_launcher.dart';
import '../utils/currency_engine.dart';

class WhatsAppService {
  WhatsAppService._();

  /// Envia el recibo digital de una venta por WhatsApp
  static Future<void> sendDigitalReceipt({
    required String phone,
    required String clientName,
    required String receiptId,
    required double totalUsd,
    required double exchangeRate,
    required List<Map<String, dynamic>> itemsSummary,
  }) async {
    final double totalVes = CurrencyEngine.usdToVes(totalUsd, exchangeRate);

    final StringBuffer itemsText = StringBuffer();
    for (final item in itemsSummary) {
      itemsText.writeln('• ${item['qty']}x ${item['name']} - \$${(item['price'] as double).toStringAsFixed(2)}');
    }

    final String message = Uri.encodeComponent(
      'Hola *$clientName*, ¡gracias por tu compra! 🛍️✨\n\n'
      '📋 *Comprobante de Venta #$receiptId*\n'
      '${itemsText.toString()}\n'
      '💵 *Total USD:* \$${totalUsd.toStringAsFixed(2)}\n'
      '🇻🇪 *Total VES:* Bs. ${totalVes.toStringAsFixed(2)} (Tasa: $exchangeRate)\n\n'
      '¡Esperamos verte pronto de nuevo! 🙏🏼'
    );

    await _launchWhatsAppUrl(phone, message);
  }

  /// Envía un recordatorio amigable de saldo pendiente a un cliente deudor
  static Future<void> sendDebtReminder({
    required String phone,
    required String clientName,
    required double totalDueUsd,
    required double exchangeRate,
    required String pagoMovilDetails,
    required String zelleDetails,
  }) async {
    final double totalDueVes = CurrencyEngine.usdToVes(totalDueUsd, exchangeRate);

    final String message = Uri.encodeComponent(
      'Hola *$clientName*, esperamos que estés muy bien. 👋🏼\n\n'
      'Te recordamos de forma amigable que tienes un saldo pendiente en tu cuenta:\n'
      '🔹 *Saldo Pendiente:* \$${totalDueUsd.toStringAsFixed(2)} USD\n'
      '🔹 *Equivalente:* Bs. ${totalDueVes.toStringAsFixed(2)} (Tasa BCV: $exchangeRate)\n\n'
      '📌 *Datos para realizar tu pago:*\n'
      '• *Pago Móvil:* $pagoMovilDetails\n'
      '• *Zelle:* $zelleDetails\n\n'
      'Agradecemos enviarnos el comprobante por este medio al realizar la transferencia. ¡Muchas gracias! 🙏🏼'
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
