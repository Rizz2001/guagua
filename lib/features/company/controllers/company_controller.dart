import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/company_membership_model.dart';
import '../models/company_model.dart';

class CompanyState {
  final CompanyModel? activeCompany;
  final List<CompanyMembershipModel> memberships;
  final bool isLoading;
  final String? errorMessage;

  const CompanyState({
    this.activeCompany,
    this.memberships = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CompanyState copyWith({
    CompanyModel? activeCompany,
    List<CompanyMembershipModel>? memberships,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CompanyState(
      activeCompany: activeCompany ?? this.activeCompany,
      memberships: memberships ?? this.memberships,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CompanyNotifier extends Notifier<CompanyState> {
  @override
  CompanyState build() {
    return const CompanyState();
  }

  /// Carga todas las empresas a las que pertenece el usuario actual
  Future<void> loadUserCompanies(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final client = SupabaseService().client;
    if (client == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Supabase no conectado',
      );
      return;
    }

    try {
      final res = await client
          .from('company_memberships')
          .select('*, companies(*)')
          .eq('user_id', userId)
          .eq('status', 'ACTIVE');

      final list = (res as List)
          .map(
            (item) =>
                CompanyMembershipModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      CompanyModel? currentActive = state.activeCompany;
      if (list.isNotEmpty) {
        // Si no hay empresa activa seleccionada o la actual no está en la lista, tomar la primera
        final matching = list
            .where((m) => m.company?.id == currentActive?.id)
            .firstOrNull;
        currentActive = matching?.company ?? list.first.company;
      } else {
        currentActive = null;
      }

      state = state.copyWith(
        activeCompany: currentActive,
        memberships: list,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('⚠️ [CompanyNotifier] Error cargando empresas: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Cambia la empresa activa en la sesión del usuario
  void selectCompany(String companyId) {
    final membership = state.memberships
        .where((m) => m.company?.id == companyId)
        .firstOrNull;
    if (membership?.company != null) {
      state = state.copyWith(activeCompany: membership!.company);
    }
  }

  /// Actualiza los datos de la empresa activa
  Future<bool> updateActiveCompany(CompanyModel company) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final client = SupabaseService().client;
    if (client == null) return false;

    try {
      await client
          .from('companies')
          .update({
            'legal_name': company.legalName,
            'trade_name': company.tradeName,
            'rif': company.rif,
            'address': company.address,
            'phone': company.phone,
            'email': company.email,
            'base_currency': company.baseCurrency,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', company.id);

      state = state.copyWith(activeCompany: company, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final companyProvider = NotifierProvider<CompanyNotifier, CompanyState>(
  CompanyNotifier.new,
);
