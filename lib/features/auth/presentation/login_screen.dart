import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isRegistering = false;
  UserRole _selectedRole = UserRole.admin;

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) return;

    if (_isRegistering) {
      final name = _nameController.text.trim();
      if (name.isEmpty) return;
      
      final success = await ref.read(authProvider.notifier).register(email, password, name, _selectedRole);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado exitosamente. Por favor, inicia sesión.'), backgroundColor: AppColors.successGreen),
        );
        setState(() => _isRegistering = false);
      }
    } else {
      await ref.read(authProvider.notifier).login(email, password);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;
    final authState = ref.watch(authProvider);

    final List<Widget> rowChildren = [];

    if (isWide) {
      rowChildren.add(
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: const BoxDecoration(
              color: AppColors.primaryCharcoal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Guagua POS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🇻🇪 Base de Datos Conectada (Supabase)',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sistema POS & Administración General',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Seguridad RBAC en la Nube. Crea nuevos usuarios con roles específicos para tu negocio.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.white60, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'RBAC • Supabase Auth • RLS Policies',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    rowChildren.add(
      Expanded(
        flex: 6,
        child: Padding(
          padding: EdgeInsets.all(isWide ? 40 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isWide)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCharcoal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Guagua POS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  _isRegistering ? 'Crear Nuevo Usuario' : 'Iniciar Sesión',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegistering 
                    ? 'Registra un nuevo usuario en la base de datos de Supabase.'
                    : 'Ingresa tu correo y contraseña para acceder.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),

                if (_isRegistering) ...[
                  Text('Nombre Completo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Carlos Ruiz',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Rol en el Sistema', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: _selectedRole,
                        isExpanded: true,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text('Correo Electrónico', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'ejemplo@guaguapos.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Contraseña', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onSubmitted: (_) => _handleSubmit(),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),

                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.dangerText, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSubmit,
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isRegistering ? 'Registrar Usuario' : 'Ingresar a POS',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(
                      _isRegistering 
                        ? '¿Ya tienes cuenta? Iniciar sesión'
                        : '¿No tienes cuenta? Registrar usuario',
                      style: const TextStyle(color: AppColors.primaryCharcoal, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1000, maxHeight: _isRegistering ? 750 : 600),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: rowChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
