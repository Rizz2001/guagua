import 'package:flutter_test/flutter_test.dart';
import 'package:guagua/core/utils/currency_engine.dart';

void main() {
  group('CurrencyEngine - Lógica Multimoneda y Vuelto Cruzado Inteligente', () {
    const double exchangeRate = 36.50; // 36.50 Bs / USD

    test('Conversiones USD a VES y viceversa', () {
      expect(CurrencyEngine.usdToVes(10.0, exchangeRate), 365.0);
      expect(CurrencyEngine.vesToUsd(365.0, exchangeRate), 10.0);
    });

    test('Pago exacto en USD sin vuelto', () {
      final res = CurrencyEngine.calculatePaymentAndChange(
        totalToPayUsd: 10.0,
        exchangeRate: exchangeRate,
        paidUsdCash: 10.0,
        paidVesPagoMovil: 0.0,
        paidZelleUsd: 0.0,
        paidCardVes: 0.0,
        fondoCajaUsd: 100.0,
        fondoCajaBs: 5000.0,
      );

      expect(res['isComplete'], true);
      expect(res['changeUsd'], 0.0);
      expect(res['changeVes'], 0.0);
    });

    test('Pago en USD con vuelto prioritario en USD si hay fondo', () {
      final res = CurrencyEngine.calculatePaymentAndChange(
        totalToPayUsd: 10.0,
        exchangeRate: exchangeRate,
        paidUsdCash: 20.0, // Pagó $20 por compra de $10 => Vuelto $10
        paidVesPagoMovil: 0.0,
        paidZelleUsd: 0.0,
        paidCardVes: 0.0,
        fondoCajaUsd: 50.0, // Hay suficiente USD en caja
        fondoCajaBs: 5000.0,
      );

      expect(res['isComplete'], true);
      expect(res['changeUsd'], 10.0);
      expect(res['suggestedChangeUsd'], 10.0);
      expect(res['suggestedChangeVes'], 0.0);
    });

    test('Pago en USD con vuelto en Bs cuando NO hay suficiente billetes de USD en caja', () {
      final res = CurrencyEngine.calculatePaymentAndChange(
        totalToPayUsd: 10.0,
        exchangeRate: exchangeRate,
        paidUsdCash: 20.0, // Sobra $10
        paidVesPagoMovil: 0.0,
        paidZelleUsd: 0.0,
        paidCardVes: 0.0,
        fondoCajaUsd: 5.0, // Solo hay $5 en caja (insuficiente para dar $10 en billetes)
        fondoCajaBs: 5000.0, // Hay suficiente Bs
      );

      expect(res['isComplete'], true);
      expect(res['suggestedChangeUsd'], 5.0);
      expect(res['suggestedChangeVes'], 182.5); // ($5 de vuelto restante) * 36.50
    });

    test('Manejo de Pago Insuficiente', () {
      final res = CurrencyEngine.calculatePaymentAndChange(
        totalToPayUsd: 10.0,
        exchangeRate: exchangeRate,
        paidUsdCash: 5.0,
        paidVesPagoMovil: 0.0,
        paidZelleUsd: 0.0,
        paidCardVes: 0.0,
        fondoCajaUsd: 100.0,
        fondoCajaBs: 1000.0,
      );

      expect(res['isComplete'], false);
      expect(res['pendingUsd'], 5.0);
    });
  });
}
