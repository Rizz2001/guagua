import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../company/controllers/company_controller.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? currentUser;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.currentUser,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? currentUser,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Escuchar cambios de estado en Supabase Auth de forma asíncrona
    Future.microtask(() => _initAuthListener());
    return AuthState(isLoading: false);
  }

  void _initAuthListener() {
    final client = SupabaseService().client;
    if (client == null) return;

    client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        try {
          // Cargar empresas del usuario
          ref.read(companyProvider.notifier).loadUserCompanies(session.user.id);

          // Obtener el perfil real de la base de datos
          final res = await client
              .from('profiles')
              .select()
              .eq('id', session.user.id)
              .maybeSingle();

          if (res != null) {
            final userModel = UserModel(
              id: res['id'],
              name: res['full_name'],
              email: res['email'],
              role: UserRole.values.firstWhere(
                (e) => e.name.toUpperCase() == res['role'],
                orElse: () => UserRole.cashier,
              ),
              pin: '', // Ya no usamos PIN duro
            );
            state = state.copyWith(
              currentUser: userModel,
              isAuthenticated: true,
              isLoading: false,
            );
          } else {
            state = state.copyWith(isAuthenticated: true, isLoading: false);
          }
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Error cargando perfil: $e',
          );
        }
      } else {
        state = state.copyWith(
          currentUser: null,
          isAuthenticated: false,
          isLoading: false,
        );
      }
    });
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final client = SupabaseService().client;
    if (client == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Supabase no conectado',
      );
      return false;
    }

    try {
      await client.auth.signInWithPassword(email: email, password: password);
      // El estado se actualizará en onAuthStateChange
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al iniciar sesión.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final client = SupabaseService().client;
    await client?.auth.signOut();
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final client = SupabaseService().client;
    if (client == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Supabase no conectado',
      );
      return false;
    }
    try {
      await client.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al enviar correo de recuperación.',
      );
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final client = SupabaseService().client;
    if (client == null) return false;

    try {
      final res = await client.auth.signUp(email: email, password: password);

      if (res.user != null) {
        // Insertamos el perfil. (En un caso real de producción, esto debería hacerse con un Trigger SQL en Supabase)
        try {
          await client.from('profiles').insert({
            'id': res.user!.id,
            'email': email,
            'full_name': name,
            'role': role.name.toUpperCase(),
          });
        } catch (insertError) {
          debugPrint('Error guardando perfil: $insertError');
        }
      }
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
