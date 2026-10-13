import 'package:flutter_test/flutter_test.dart';
import 'package:guagua/core/utils/currency_engine.dart';
import 'package:guagua/features/dashboard/controllers/dashboard_controller.dart';
import 'package:guagua/features/inventory/controllers/inventory_controller.dart';
import 'package:guagua/features/pos/models/cart_item_model.dart';
import 'package:guagua/features/pos/models/product_model.dart';

void main() {
  group('Fase 2: Precios Dinámicos & Escala Mayorista Tests', () {
    final testProduct = ProductModel(
      id: 'prod-001',
      title: 'Harina PAN 1kg',
      priceRetailUsd: 1.50,
      priceWholesaleUsd: 1.20,
      wholesaleMinQty: 6,
      stockUnits: 50,
      category: 'Víveres',
      isCombo: false,
    );

    test('Aplica precio detal si cantidad es menor que wholesaleMinQty', () {
      final item = CartItemModel(product: testProduct, quantity: 3);

      expect(item.checkWholesaleApplied, false);
      expect(item.unitPriceUsd, 1.50);
      expect(item.totalPriceUsd, 4.50);
    });

    test('Conmuta automáticamente a precio mayorista si cantidad >= wholesaleMinQty', () {
      final item = CartItemModel(product: testProduct, quantity: 6);

      expect(item.checkWholesaleApplied, true);
      expect(item.unitPriceUsd, 1.20);
      expect(item.totalPriceUsd, 7.20);
    });

    test('Combo promocional preserva flag isCombo', () {
      final combo = ProductModel(
        id: 'combo-001',
        title: 'Combo Desayuno',
        priceRetailUsd: 10.0,
        stockUnits: 20,
        category: 'Combos',
        isCombo: true,
      );

      expect(combo.isCombo, true);
    });
  });

  group('Fase 3: IGTF (3%) & Reportes Contables Tests', () {
    test('Calcula el 3% de IGTF exactamente sobre pagos en divisas / Zelle', () {
      final igtf = CurrencyEngine.calculateIgtfUsd(
        paidUsdCash: 50.0,
        paidZelleUsd: 50.0,
      );

      // (50 + 50) * 0.03 = 3.00 USD
      expect(igtf, 3.00);
    });

    test('calculatePaymentAndChange incorpora IGTF al total requerido', () {
      final res = CurrencyEngine.calculatePaymentAndChange(
        totalToPayUsd: 100.0,
        exchangeRate: 36.50,
        paidUsdCash: 103.0,
        paidVesPagoMovil: 0.0,
        paidZelleUsd: 0.0,
        paidCardVes: 0.0,
        fondoCajaUsd: 50.0,
        fondoCajaBs: 1000.0,
        igtfUsd: 3.00, // Total requerido: $103.00
      );

      expect(res['isComplete'], true);
      expect(res['changeUsd'], 0.0);
    });

    test('generateSalesCsv genera encabezado y filas delimitadas correctamente', () {
      final sales = [
        {
          'invoice_number': 'INV-001',
          'created_at': '2026-10-12T15:30:00Z',
          'total_usd': 25.50,
          'exchange_rate': 36.50,
          'payment_method': 'EFECTIVO_USD',
          'payment_details': {'igtf_usd': 0.77},
        }
      ];

      final csv = generateSalesCsv(sales);

      expect(csv.contains('Factura,Fecha,Hora,Total USD,Tasa BCV,Total VES,Metodo Pago,IGTF USD'), true);
      expect(csv.contains('"INV-001"'), true);
      expect(csv.contains('25.50'), true);
    });
  });

  group('Fase 4: Multi-Sucursal & Transferencias Model Tests', () {
    test('StockTransferModel deserializa JSON correctamente', () {
      final json = {
        'id': 'trf-123',
        'transfer_number': 'TRF-998877',
        'origin_store': 'Almacén Central',
        'destination_store': 'Sucursal Principal',
        'product_id': 'prod-001',
        'product_name': 'Harina PAN',
        'quantity': 24,
        'status': 'EN_TRANSITO',
        'created_at': '2026-10-12T10:00:00Z',
      };

      final transfer = StockTransferModel.fromJson(json);

      expect(transfer.id, 'trf-123');
      expect(transfer.transferNumber, 'TRF-998877');
      expect(transfer.originStore, 'Almacén Central');
      expect(transfer.destinationStore, 'Sucursal Principal');
      expect(transfer.quantity, 24);
      expect(transfer.status, 'EN_TRANSITO');
    });
  });
}
