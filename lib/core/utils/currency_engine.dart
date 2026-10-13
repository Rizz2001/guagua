import 'dart:math';

/// Motor de Cálculo Multimoneda (USD / BS) y Calculadora de Vueltos Mixtos
class CurrencyEngine {
  CurrencyEngine._();

  /// Convierte un monto en USD a Bolívares (VES) usando la tasa de cambio especificada
  static double usdToVes(double amountUsd, double exchangeRate) {
    return double.parse((amountUsd * exchangeRate).toStringAsFixed(2));
  }

  /// Convierte un monto en Bolívares (VES) a USD usando la tasa de cambio especificada
  static double vesToUsd(double amountVes, double exchangeRate) {
    if (exchangeRate <= 0) return 0.0;
    return double.parse((amountVes / exchangeRate).toStringAsFixed(2));
  }

  /// Formatea un monto en USD a string con 2 decimales (ej. "$12.50")
  static String formatUsd(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Formatea un monto en BS a string con 2 decimales (ej. "Bs. 456.25")
  static String formatVes(double amount) {
    return 'Bs. ${amount.toStringAsFixed(2)}';
  }

  /// Calcula el 3% de IGTF aplicable exclusivamente sobre pagos en divisas / moneda extranjera (efectivo USD y Zelle)
  static double calculateIgtfUsd({
    required double paidUsdCash,
    required double paidZelleUsd,
  }) {
    final double foreignTotal = paidUsdCash + paidZelleUsd;
    return double.parse((foreignTotal * 0.03).toStringAsFixed(2));
  }

  /// Algoritmo de cálculo de vueltos mixtos en USD y VES con soporte opcional de IGTF
  static Map<String, dynamic> calculatePaymentAndChange({
    required double totalToPayUsd,
    required double exchangeRate,
    required double paidUsdCash,
    required double paidVesPagoMovil,
    required double paidZelleUsd,
    required double paidCardVes,
    required double fondoCajaUsd,
    required double fondoCajaBs,
    double igtfUsd = 0.0,
  }) {
    final double effectiveTotalToPayUsd = totalToPayUsd + igtfUsd;
    final double paidVesInUsd = vesToUsd(paidVesPagoMovil + paidCardVes, exchangeRate);
    final double totalPaidUsd = paidUsdCash + paidZelleUsd + paidVesInUsd;
    final double differenceUsd = totalPaidUsd - effectiveTotalToPayUsd;

    if (differenceUsd < -0.009) {
      final double pendingUsd = differenceUsd.abs();
      final double pendingVes = usdToVes(pendingUsd, exchangeRate);
      return {
        'isComplete': false,
        'pendingUsd': double.parse(pendingUsd.toStringAsFixed(2)),
        'pendingVes': double.parse(pendingVes.toStringAsFixed(2)),
        'changeUsd': 0.0,
        'changeVes': 0.0,
        'totalPaidUsd': double.parse(totalPaidUsd.toStringAsFixed(2)),
        'suggestedChangeUsd': 0.0,
        'suggestedChangeVes': 0.0,
      };
    }

    final double changeUsd = max(0.0, differenceUsd);
    final double changeVes = usdToVes(changeUsd, exchangeRate);

    // Lógica Inteligente de Vuelto Cruzado (Guagua POS)
    // Asumimos que el vuelto en USD físico solo se da en billetes enteros
    double suggestedChangeUsd = 0.0;
    double suggestedChangeVes = 0.0;

    int changeUsdInt = changeUsd.floor(); // Parte entera del vuelto en USD
    if (changeUsdInt > 0) {
      // ¿Tenemos suficiente fondo en USD físico para dar la parte entera?
      int usdFondoInt = fondoCajaUsd.floor();
      suggestedChangeUsd = min(changeUsdInt, usdFondoInt).toDouble();
    }

    // El resto se da en Bolívares (Pago Móvil / Efectivo Bs)
    double remainingUsdToChange = changeUsd - suggestedChangeUsd;
    suggestedChangeVes = usdToVes(remainingUsdToChange, exchangeRate);

    return {
      'isComplete': true,
      'pendingUsd': 0.0,
      'pendingVes': 0.0,
      'changeUsd': double.parse(changeUsd.toStringAsFixed(2)),
      'changeVes': double.parse(changeVes.toStringAsFixed(2)),
      'totalPaidUsd': double.parse(totalPaidUsd.toStringAsFixed(2)),
      'suggestedChangeUsd': double.parse(suggestedChangeUsd.toStringAsFixed(2)),
      'suggestedChangeVes': double.parse(suggestedChangeVes.toStringAsFixed(2)),
    };
  }
}
