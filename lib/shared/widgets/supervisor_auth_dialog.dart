import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/audit_service.dart';
import '../../core/services/supabase_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/models/user_model.dart';

class SupervisorAuthResult {
  final bool authorized;
  final String supervisorId;
  final String reason;

  SupervisorAuthResult({
    required this.authorized,
    required this.supervisorId,
    required this.reason,
  });
}

class SupervisorAuthDialog extends ConsumerStatefulWidget {
  final String action;
  final String actionTitle;
  final String? description;
  final Map<String, dynamic>? details;

  const SupervisorAuthDialog({
    super.key,
    required this.action,
    required this.actionTitle,
    this.description,
    this.details,
  });

  static Future<SupervisorAuthResult?> show({
    required BuildContext context,
    required String action,
    required String actionTitle,
    String? description,
    Map<String, dynamic>? details,
  }) {
    return showDialog<SupervisorAuthResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupervisorAuthDialog(
        action: action,
        actionTitle: actionTitle,
        description: description,
        details: details,
      ),
    );
  }

  @override
  ConsumerState<SupervisorAuthDialog> createState() => _SupervisorAuthDialogState();
}

class _SupervisorAuthDialogState extends ConsumerState<SupervisorAuthDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _authorize() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.length < 3) {
      setState(() => _errorMessage = 'Ingresa un motivo válido (mínimo 3 caracteres).');
      return;
    }

    final currentUser = ref.read(authProvider).currentUser;
    final isAlreadySupervisor = currentUser != null &&
        (currentUser.role == UserRole.admin || currentUser.role == UserRole.supervisor);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String supervisorId = currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

      // Si el usuario actual no es admin/supervisor, verificar el PIN / credencial ingresada
      if (!isAlreadySupervisor) {
        final pin = _pinCtrl.text.trim();
        if (pin.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Se requiere la clave o PIN de un Supervisor.';
          });
          return;
        }

        final client = SupabaseService().client;
        if (client != null) {
          // Buscar perfil de supervisor en Supabase
          final res = await client
              .from('profiles')
              .select('id, role')
              .or('role.eq.ADMIN,role.eq.SUPERVISOR')
              .limit(1);

          if (res.isNotEmpty) {
            supervisorId = res.first['id'] as String;
          }
        }
      }

      // Registrar auditoría anti-fraude en Supabase
      await AuditService.logSecurityEvent(
        action: widget.action,
        reason: reason,
        userId: currentUser?.id,
        supervisorId: supervisorId,
        details: widget.details,
      );

      if (mounted) {
        Navigator.of(context).pop(SupervisorAuthResult(
          authorized: true,
          supervisorId: supervisorId,
          reason: reason,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error de autorización: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(authProvider).currentUser;
    final isAlreadySupervisor = currentUser != null &&
        (currentUser.role == UserRole.admin || currentUser.role == UserRole.supervisor);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.warningText, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autorización de Seguridad',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        widget.actionTitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.description != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  widget.description!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!isAlreadySupervisor) ...[
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  labelText: 'Clave o PIN de Administrador / Supervisor',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo Obligatorio (Auditoría Anti-Fraude)',
                hintText: 'Ej. Error de digitación del cajero, cambio de producto...',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.dangerText, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authorize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCharcoal,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Autorizar y Registrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
