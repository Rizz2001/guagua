import 'package:flutter_test/flutter_test.dart';
import 'package:guagua/features/credit/controllers/credit_controller.dart';
import 'package:guagua/features/dashboard/controllers/dashboard_controller.dart';
import 'package:guagua/features/cash_shift/controllers/cash_shift_controller.dart';

void main() {
  group('CreditClientModel & Logic Tests', () {
    test('Calculates available credit correctly', () {
      final client = CreditClientModel(
        id: '1',
        name: 'Bodega El Sol',
        documentId: 'J-12345678',
        phone: '584141112233',
        creditLimitUsd: 500.0,
        currentDebtUsd: 150.0,
      );

      expect(client.availableCreditUsd, 350.0);
    });

    test('Clamps available credit to 0 if debt exceeds limit', () {
      final client = CreditClientModel(
        id: '2',
        name: 'Comercial La Paz',
        documentId: 'V-10203040',
        phone: '584120000000',
        creditLimitUsd: 200.0,
        currentDebtUsd: 250.0,
      );

      expect(client.availableCreditUsd, 0.0);
    });
  });

  group('DashboardMetrics & CashShift Tests', () {
    test('DashboardMetrics defaults correctly with zero mock data', () {
      final metrics = DashboardMetrics();
      expect(metrics.realCashInDrawerUsd, 0.0);
      expect(metrics.capitalInStreetUsd, 0.0);
      expect(metrics.activeCreditClientsCount, 0);
      expect(metrics.delinquencyRatePercentage, 0.0);
      expect(metrics.lowStockAlerts, isEmpty);
    });

    test('CashShiftState defaults to closed shift', () {
      final state = CashShiftState();
      expect(state.isShiftOpen, false);
      expect(state.fondoCajaUsd, 0.0);
      expect(state.activeShiftId, isNull);
    });
  });
}
