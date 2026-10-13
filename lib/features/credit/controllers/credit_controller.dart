import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

class CreditClientModel {
  final String id;
  final String name;
  final String documentId;
  final String phone;
  final double creditLimitUsd;
  final double currentDebtUsd;
  final int daysOverdue;

  CreditClientModel({
    required this.id,
    required this.name,
    required this.documentId,
    required this.phone,
    required this.creditLimitUsd,
    required this.currentDebtUsd,
    this.daysOverdue = 0,
  });

  double get availableCreditUsd => (creditLimitUsd - currentDebtUsd).clamp(0.0, creditLimitUsd);

  factory CreditClientModel.fromJson(Map<String, dynamic> json) {
    return CreditClientModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sin Nombre',
      documentId: json['document_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      creditLimitUsd: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      currentDebtUsd: (json['current_debt'] as num?)?.toDouble() ?? 0.0,
      daysOverdue: json['days_overdue'] as int? ?? 0,
    );
  }
}

final creditClientsStreamProvider = StreamProvider<List<CreditClientModel>>((ref) {
  final client = SupabaseService().client;
  if (client == null) return Stream.value([]);

  try {
    return client
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((list) => list.map((json) => CreditClientModel.fromJson(json)).toList());
  } catch (e) {
    debugPrint('Error en stream de clientes a crédito: $e');
    return Stream.value([]);
  }
});

class CreditController {
  final SupabaseService _supabase = SupabaseService();

  Future<bool> createClient({
    required String name,
    required String documentId,
    required String phone,
    required double creditLimitUsd,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('clients').insert({
        'name': name.trim(),
        'document_id': documentId.trim(),
        'phone': phone.trim(),
        'credit_limit': creditLimitUsd,
        'current_debt': 0.0,
      });
      return true;
    } catch (e) {
      debugPrint('Error creando cliente para crédito: $e');
      return false;
    }
  }

  Future<bool> recordPayment({
    required String clientId,
    required double amountUsd,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      // 1. Obtener cliente actual
      final res = await client.from('clients').select('current_debt').eq('id', clientId).single();
      final double currentDebt = (res['current_debt'] as num?)?.toDouble() ?? 0.0;
      final double newDebt = (currentDebt - amountUsd).clamp(0.0, 1000000.0);

      // 2. Actualizar deuda del cliente
      await client.from('clients').update({'current_debt': newDebt}).eq('id', clientId);

      // 3. Si hay deudas registradas en la tabla debts, amortizarlas
      final pendingDebts = await client
          .from('debts')
          .select()
          .eq('client_id', clientId)
          .eq('is_paid', false)
          .order('created_at', ascending: true);

      double remainingPayment = amountUsd;
      for (final debt in pendingDebts) {
        if (remainingPayment <= 0) break;
        final debtId = debt['id'] as String;
        final double pending = (debt['pending_amount_usd'] as num).toDouble();

        if (remainingPayment >= pending) {
          await client.from('debts').update({
            'pending_amount_usd': 0.0,
            'is_paid': true,
          }).eq('id', debtId);
          remainingPayment -= pending;
        } else {
          await client.from('debts').update({
            'pending_amount_usd': pending - remainingPayment,
          }).eq('id', debtId);
          remainingPayment = 0;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error registrando abono de deuda: $e');
      return false;
    }
  }
}

final creditControllerProvider = Provider((ref) => CreditController());
