import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

class CashShiftState {
  final String? activeShiftId;
  final double fondoCajaUsd;
  final double fondoCajaBs;
  final bool isShiftOpen;
  final DateTime? openedAt;
  final double salesUsdInShift;
  final double salesBsInShift;
  final bool isLoading;

  CashShiftState({
    this.activeShiftId,
    this.fondoCajaUsd = 0.0,
    this.fondoCajaBs = 0.0,
    this.isShiftOpen = false,
    this.openedAt,
    this.salesUsdInShift = 0.0,
    this.salesBsInShift = 0.0,
    this.isLoading = false,
  });

  CashShiftState copyWith({
    String? activeShiftId,
    double? fondoCajaUsd,
    double? fondoCajaBs,
    bool? isShiftOpen,
    DateTime? openedAt,
    double? salesUsdInShift,
    double? salesBsInShift,
    bool? isLoading,
  }) {
    return CashShiftState(
      activeShiftId: activeShiftId ?? this.activeShiftId,
      fondoCajaUsd: fondoCajaUsd ?? this.fondoCajaUsd,
      fondoCajaBs: fondoCajaBs ?? this.fondoCajaBs,
      isShiftOpen: isShiftOpen ?? this.isShiftOpen,
      openedAt: openedAt ?? this.openedAt,
      salesUsdInShift: salesUsdInShift ?? this.salesUsdInShift,
      salesBsInShift: salesBsInShift ?? this.salesBsInShift,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CashShiftNotifier extends Notifier<CashShiftState> {
  @override
  CashShiftState build() {
    Future.microtask(() => checkActiveShift());
    return CashShiftState(isLoading: true);
  }

  Future<void> checkActiveShift() async {
    final client = SupabaseService().client;
    if (client == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final res = await client
          .from('cash_shifts')
          .select()
          .eq('status', 'OPEN')
          .order('opened_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        final shiftId = res['id'] as String;
        final double openingUsd = (res['opening_fund_usd'] as num?)?.toDouble() ?? 0.0;
        final DateTime opened = DateTime.tryParse(res['opened_at'] ?? '') ?? DateTime.now();

        // Calcular ventas reales ocurridas desde que se abrió el turno
        final sales = await client
            .from('sales')
            .select('total_usd, exchange_rate, payment_method')
            .eq('status', 'COMPLETED')
            .gte('created_at', opened.toIso8601String());

        double totalSalesUsd = 0.0;
        double totalSalesBs = 0.0;

        for (final s in sales) {
          final usd = (s['total_usd'] as num?)?.toDouble() ?? 0.0;
          final rate = (s['exchange_rate'] as num?)?.toDouble() ?? 36.50;
          totalSalesUsd += usd;
          if (s['payment_method'] == 'PAGO_MOVIL' || s['payment_method'] == 'EFECTIVO_BS') {
            totalSalesBs += usd * rate;
          }
        }

        state = CashShiftState(
          activeShiftId: shiftId,
          fondoCajaUsd: openingUsd,
          fondoCajaBs: 0.0,
          isShiftOpen: true,
          openedAt: opened,
          salesUsdInShift: totalSalesUsd,
          salesBsInShift: totalSalesBs,
          isLoading: false,
        );
      } else {
        state = CashShiftState(
          activeShiftId: null,
          fondoCajaUsd: 0.0,
          fondoCajaBs: 0.0,
          isShiftOpen: false,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Error verificando turno de caja en Supabase: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> openShift({
    required String cashierId,
    required double openingFundUsd,
  }) async {
    final client = SupabaseService().client;
    if (client == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final res = await client
          .from('cash_shifts')
          .insert({
            'cashier_id': cashierId,
            'opening_fund_usd': openingFundUsd,
            'status': 'OPEN',
          })
          .select()
          .single();

      final newShiftId = res['id'] as String;
      state = CashShiftState(
        activeShiftId: newShiftId,
        fondoCajaUsd: openingFundUsd,
        fondoCajaBs: 0.0,
        isShiftOpen: true,
        openedAt: DateTime.now(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      debugPrint('Error abriendo turno de caja en Supabase: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> closeShift({
    required double actualCashUsd,
    required double actualCashBs,
    required double differenceUsd,
  }) async {
    final client = SupabaseService().client;
    if (client == null || state.activeShiftId == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      await client.from('cash_shifts').update({
        'status': 'CLOSED',
        'closed_at': DateTime.now().toIso8601String(),
        'cash_usd_actual': actualCashUsd,
        'cash_bs_actual': actualCashBs,
        'difference_usd': differenceUsd,
      }).eq('id', state.activeShiftId!);

      state = CashShiftState(
        activeShiftId: null,
        fondoCajaUsd: 0.0,
        fondoCajaBs: 0.0,
        isShiftOpen: false,
        isLoading: false,
      );
      return true;
    } catch (e) {
      debugPrint('Error cerrando turno de caja en Supabase: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final cashShiftProvider = NotifierProvider<CashShiftNotifier, CashShiftState>(
  CashShiftNotifier.new,
);
