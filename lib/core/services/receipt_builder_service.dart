import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Servicio generador de tickets térmicos formateados para 58mm y 80mm.
class ReceiptBuilderService {
  /// Genera un documento PDF con las dimensiones exactas de papel térmico (58mm o 80mm).
  static Future<Uint8List> generateThermalReceipt({
    required Map<String, dynamic> salePayload,
    String storeName = 'Mi Comercial Guagua POS',
    String storeRif = 'J-50192837-0',
    String storePhone = '+58 414-1234567',
    String storeAddress = 'Av. Bolívar, Local 12',
    bool is80mm = false,
  }) async {
    final pdf = pw.Document();

    final double rollWidth = is80mm ? 80 * PdfPageFormat.mm : 58 * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(
      rollWidth,
      double.infinity,
      marginLeft: 3 * PdfPageFormat.mm,
      marginRight: 3 * PdfPageFormat.mm,
      marginTop: 4 * PdfPageFormat.mm,
      marginBottom: 6 * PdfPageFormat.mm,
    );

    final String invoiceNumber = salePayload['invoice_number'] ?? 'INV-0000';
    final double totalUsd = (salePayload['total_usd'] as num?)?.toDouble() ?? 0.0;
    final double rate = (salePayload['exchange_rate'] as num?)?.toDouble() ?? 36.50;
    final double igtfUsd = (salePayload['igtf_usd'] as num?)?.toDouble() ?? 0.0;
    final double finalTotalUsd = totalUsd + igtfUsd;
    final double totalBs = finalTotalUsd * rate;
    final String paymentMethod = salePayload['payment_method'] ?? 'EFECTIVO_USD';
    final Map<String, dynamic> paymentDetails = (salePayload['payment_details'] as Map<String, dynamic>?) ?? {};
    final List<dynamic> items = salePayload['items'] ?? [];
    final String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final double changeUsd = (paymentDetails['change_usd'] as num?)?.toDouble() ?? 0.0;
    final double changeBs = (paymentDetails['change_bs'] as num?)?.toDouble() ?? 0.0;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 1. ENCABEZADO COMERCIO
              pw.Text(
                storeName.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 12 : 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'RIF: $storeRif',
                style: pw.TextStyle(fontSize: is80mm ? 9 : 8),
              ),
              pw.Text(
                storeAddress,
                style: pw.TextStyle(fontSize: is80mm ? 8 : 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Tel: $storePhone',
                style: pw.TextStyle(fontSize: is80mm ? 8 : 7),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // 2. DETALLE DE FACTURA
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Factura: $invoiceNumber', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 9 : 8)),
                    pw.Text('Fecha: $dateStr', style: pw.TextStyle(fontSize: is80mm ? 8 : 7)),
                    pw.Text('Tasa Oficial: ${rate.toStringAsFixed(2)} Bs/USD', style: pw.TextStyle(fontSize: is80mm ? 8 : 7)),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // 3. TABLA DE ÍTEMS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 5, child: pw.Text('Desc', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 8 : 7))),
                  pw.Expanded(flex: 2, child: pw.Text('Cant', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 8 : 7))),
                  pw.Expanded(flex: 3, child: pw.Text('Total \$', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 8 : 7))),
                ],
              ),
              pw.SizedBox(height: 2),
              ...items.map((item) {
                final name = item['product_name'] ?? 'Producto';
                final qty = item['quantity'] ?? 1;
                final subtotal = (item['subtotal_usd'] as num?)?.toDouble() ?? 0.0;
                final isWholesale = item['is_wholesale'] == true;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          isWholesale ? '$name [MAYOR]' : name,
                          style: pw.TextStyle(fontSize: is80mm ? 8 : 7),
                          maxLines: 1,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'x$qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: is80mm ? 8 : 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          '\$${subtotal.toStringAsFixed(2)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 8 : 7),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // 4. TOTALES & IGTF
              if (igtfUsd > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal:', style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                    pw.Text('\$${totalUsd.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IGTF (3% Divisas):', style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                    pw.Text('+\$${igtfUsd.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: is80mm ? 9 : 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL USD:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 11 : 9)),
                  pw.Text('\$${finalTotalUsd.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 11 : 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL BS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 10 : 8)),
                  pw.Text('Bs. ${totalBs.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 10 : 8)),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Forma de Pago: $paymentMethod',
                  style: pw.TextStyle(fontSize: is80mm ? 8 : 7, fontStyle: pw.FontStyle.italic),
                ),
              ),

              // DESGLOSE DE VUELTO CRUZADO
              if (changeUsd > 0 || changeBs > 0) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Vuelto Entregado: ${changeUsd > 0 ? "\$${changeUsd.toStringAsFixed(2)} USD " : ""}${changeBs > 0 ? "Bs. ${changeBs.toStringAsFixed(2)}" : ""}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is80mm ? 8 : 7),
                  ),
                ),
              ],

              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // 5. CÓDIGO QR Y PIE DE PÁGINA
              pw.SizedBox(height: 4),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'FACTURA:$invoiceNumber|TOTAL:\$$finalTotalUsd|BS:$totalBs|FECHA:$dateStr',
                width: is80mm ? 44 : 36,
                height: is80mm ? 44 : 36,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '¡Gracias por su compra!',
                style: pw.TextStyle(fontSize: is80mm ? 8 : 7, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Guagua POS - Enterprise Edition',
                style: pw.TextStyle(fontSize: is80mm ? 7 : 6, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
