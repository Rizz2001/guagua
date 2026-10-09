import 'package:flutter_riverpod/flutter_riverpod.dart';

class CashShiftState {
  final double fondoCajaUsd;
  final double fondoCajaBs;
  final bool isShiftOpen;

  CashShiftState({
    this.fondoCajaUsd = 0.0,
    this.fondoCajaBs = 0.0,
    this.isShiftOpen = false,
  });

  CashShiftState copyWith({
    double? fondoCajaUsd,
    double? fondoCajaBs,
    bool? isShiftOpen,
  }) {
    return CashShiftState(
      fondoCajaUsd: fondoCajaUsd ?? this.fondoCajaUsd,
      fondoCajaBs: fondoCajaBs ?? this.fondoCajaBs,
      isShiftOpen: isShiftOpen ?? this.isShiftOpen,
    );
  }
}

class CashShiftNotifier extends Notifier<CashShiftState> {
  @override
  CashShiftState build() {
    // Inicialización por defecto. En un futuro, esto leerá de Hive/Supabase
    // al abrir el turno (Cierre X).
    return CashShiftState(
      fondoCajaUsd: 150.0, // Fondo de prueba
      fondoCajaBs: 5000.0,  // Fondo de prueba
      isShiftOpen: true,
    );
  }

  void openShift(double fondoUsd, double fondoBs) {
    state = state.copyWith(
      fondoCajaUsd: fondoUsd,
      fondoCajaBs: fondoBs,
      isShiftOpen: true,
    );
  }

  void closeShift() {
    state = state.copyWith(
      fondoCajaUsd: 0,
      fondoCajaBs: 0,
      isShiftOpen: false,
    );
  }

  // Permite actualizar el fondo si hubo un retiro parcial (Sobrante)
  void updateFunds(double usd, double bs) {
    state = state.copyWith(
      fondoCajaUsd: usd,
      fondoCajaBs: bs,
    );
  }
}

final cashShiftProvider = NotifierProvider<CashShiftNotifier, CashShiftState>(
  CashShiftNotifier.new,
);
