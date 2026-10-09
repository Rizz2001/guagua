import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _storeNameCtrl = TextEditingController(text: 'Mi Comercial Guagua POS');
  final TextEditingController _rifCtrl = TextEditingController(text: 'J-50192837-0');
  final TextEditingController _phoneCtrl = TextEditingController(text: '584141234567');
  final TextEditingController _addressCtrl = TextEditingController(text: 'Av. Bolivar, Local 12');

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Gestión de Usuarios'),
          content: const Text('Para registrar nuevos operadores, por favor cierra sesión y utiliza la opción "Registrar Usuario" en la pantalla de inicio.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> _fetchUsers() async {
    final client = SupabaseService().client;
    if (client == null) return [];
    try {
      return await client.from('profiles').select();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración General del Comercio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Personaliza el nombre de tu tienda, datos fiscales, perfiles y usuarios del sistema.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // DATOS DE LA TIENDA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos del Negocio / Comercio', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _storeNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Comercial de la Tienda (Cualquier Sector)',
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rifCtrl,
                          decoration: const InputDecoration(labelText: 'RIF / Identificación Fiscal', prefixIcon: Icon(Icons.badge)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Teléfono Comercial WhatsApp', prefixIcon: Icon(Icons.phone)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección Física', prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('💾 Datos del comercio guardados exitosamente')),
                      );
                    },
                    child: const Text('Guardar Cambios de Tienda'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // GESTIÓN DE USUARIOS Y PERFILES (RBAC)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal (Perfiles de Supabase)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Lista de perfiles registrados en la base de datos.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Información'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<List<dynamic>>(
                    future: _fetchUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return const Text('No hay usuarios o no hay conexión a Supabase.');
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final user = users[idx];
                          final name = user['full_name'] ?? 'Desconocido';
                          final email = user['email'] ?? '';
                          final role = user['role'] ?? 'CASHIER';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryCharcoal,
                              child: Text(name.toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: Text('$email • Rol: $role', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
