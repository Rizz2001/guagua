import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/main_layout_screen.dart';
import 'core/services/outbox_service.dart';
import 'core/services/print_spooler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await OutboxService.initialize();
  await PrintSpoolerService.initialize();
  OutboxService.listenToConnectivityChanges();
  
  runApp(
    const ProviderScope(
      child: GuaguaApp(),
    ),
  );
}

class GuaguaApp extends ConsumerWidget {
  const GuaguaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Guagua POS - Sistema Punto de Venta & Administración',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isAuthenticated ? const MainLayoutScreen() : const LoginScreen(),
    );
  }
}

