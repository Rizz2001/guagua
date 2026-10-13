import 'package:flutter_test/flutter_test.dart';
import 'package:guagua/core/services/receipt_builder_service.dart';

void main() {
  test('generateThermalReceipt produces valid PDF bytes for 58mm and 80mm', () async {
    final payload = {
      'invoice_number': 'INV-TEST-001',
      'total_usd': 15.50,
      'exchange_rate': 36.50,
      'payment_method': 'EFECTIVO_USD',
      'items': [
        {
          'product_name': 'Harina PAN 1kg',
          'quantity': 2,
          'subtotal_usd': 2.40,
        },
        {
          'product_name': 'Café Fama de América 500g',
          'quantity': 1,
          'subtotal_usd': 4.50,
        },
      ],
    };

    final bytes58 = await ReceiptBuilderService.generateThermalReceipt(
      salePayload: payload,
      is80mm: false,
    );
    expect(bytes58, isNotEmpty);

    final bytes80 = await ReceiptBuilderService.generateThermalReceipt(
      salePayload: payload,
      is80mm: true,
    );
    expect(bytes80, isNotEmpty);
  });
}
