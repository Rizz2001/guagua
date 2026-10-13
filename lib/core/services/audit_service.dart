import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Servicio de registro de auditoría anti-fraude para operaciones críticas de caja
class AuditService {
  AuditService._();

  static Future<bool> logSecurityEvent({
    required String action,
    required String reason,
    String? userId,
    String? supervisorId,
    Map<String, dynamic>? details,
  }) async {
    final client = SupabaseService().client;
    try {
      if (client != null) {
        await client.from('audit_logs').insert({
          'action': action,
          'user_id': userId,
          'supervisor_id': supervisorId,
          'reason': reason.trim(),
          'details': details ?? {},
        });
      }
      debugPrint('🛡️ [AUDITORÍA] Acción "$action" registrada. Motivo: "$reason" | Supervisor: $supervisorId');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error al registrar evento en audit_logs: $e');
      return false;
    }
  }
}
