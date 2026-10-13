import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../controllers/credit_controller.dart';

class CreditManagementScreen extends ConsumerStatefulWidget {
  const CreditManagementScreen({super.key});

  @override
  ConsumerState<CreditManagementScreen> createState() => _CreditManagementScreenState();
}

class _CreditManagementScreenState extends ConsumerState<CreditManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;
    final clientsAsync = ref.watch(creditClientsStreamProvider);

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            title: 'Cuentas por Cobrar & Recordatorios WhatsApp',
            subtitle: 'Clasificación por antigüedad de mora y cobro automatizado en 1 toque por WhatsApp.',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showNewClientDialog(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Nuevo Cliente / Cupo'),
              ),
            ],
          ),
          Expanded(
            child: clientsAsync.when(
              loading: () => const LoadingState(message: 'Cargando clientes y cartera de crédito...'),
              error: (err, stack) => ErrorState(
                message: 'Error al conectar con la cartera de crédito: $err',
                onRetry: () => ref.refresh(creditClientsStreamProvider),
              ),
              data: (clients) {
                if (clients.isEmpty) {
                  return EmptyState(
                    icon: Icons.credit_score_outlined,
                    title: 'Aún no tienes clientes registrados con cupo de crédito',
                    description: 'Registra un cliente con su Cédula/RIF y cupo en dólares para comenzar a gestionar créditos.',
                    actionLabel: 'Nuevo Cliente / Cupo',
                    onAction: () => _showNewClientDialog(context),
                  );
                }

                return ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final acc = clients[index];
                    return _buildClientCreditCard(acc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCreditCard(CreditClientModel acc) {
    Color statusBg;
    Color statusText;
    String statusLabel;

    if (acc.daysOverdue >= 30) {
      statusBg = AppColors.dangerBg;
      statusText = AppColors.dangerText;
      statusLabel = '🔴 Mora Crítica (${acc.daysOverdue} días)';
    } else if (acc.daysOverdue >= 8) {
      statusBg = AppColors.warningBg;
      statusText = AppColors.warningText;
      statusLabel = '🍊 Mora Intermedia (${acc.daysOverdue} días)';
    } else if (acc.daysOverdue >= 1) {
      statusBg = AppColors.background;
      statusText = AppColors.textDark;
      statusLabel = '🟡 Reciente (${acc.daysOverdue} días)';
    } else {
      statusBg = AppColors.successGreen.withValues(alpha: 0.15);
      statusText = AppColors.successGreenDark;
      statusLabel = '🟢 Al Día';
    }

    final usageRatio = acc.creditLimitUsd > 0
        ? (acc.currentDebtUsd / acc.creditLimitUsd).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 750;

        final clientInfo = Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryCharcoal.withValues(alpha: 0.1),
              child: Text(
                acc.name.isNotEmpty ? acc.name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryCharcoal),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc.name,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Doc: ${acc.documentId.isNotEmpty ? acc.documentId : "N/A"} • Tel: +${acc.phone}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
          child: Text(statusLabel, style: TextStyle(color: statusText, fontWeight: FontWeight.bold, fontSize: 11)),
        );

        final progress = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Deuda: \$${acc.currentDebtUsd.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Límite: \$${acc.creditLimitUsd.toStringAsFixed(2)}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usageRatio,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  usageRatio > 0.8 ? AppColors.dangerText : AppColors.primaryCharcoal,
                ),
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showPurchaseHistoryDialog(context, acc),
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Historial 🛒'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            OutlinedButton.icon(
              onPressed: acc.currentDebtUsd > 0 ? () => _showAbonoDialog(acc) : null,
              icon: const Icon(Icons.attach_money, size: 16),
              label: const Text('Abonar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: acc.currentDebtUsd > 0
                  ? () {
                      WhatsAppService.sendDebtReminder(
                        phone: acc.phone,
                        clientName: acc.name,
                        totalDueUsd: acc.currentDebtUsd,
                        exchangeRate: 36.50,
                        daysOverdue: acc.daysOverdue,
                      );
                    }
                  : null,
              icon: const Icon(Icons.send, size: 16, color: Colors.white),
              label: const Text('Cobrar 💬'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreenDark,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 4, child: clientInfo),
                    const SizedBox(width: 12),
                    badge,
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: progress),
                    const SizedBox(width: 16),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: clientInfo),
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ),
                    const SizedBox(height: 14),
                    progress,
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                ),
        );
      },
    );
  }

  void _showAbonoDialog(CreditClientModel acc) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Abono a ${acc.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo Actual Deudor: \$${acc.currentDebtUsd.toStringAsFixed(2)} USD'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: r'Monto del Abono ($)',
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                final success = await ref.read(creditControllerProvider).recordPayment(
                      clientId: acc.id,
                      amountUsd: amount,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🎉 Abono de \$${amount.toStringAsFixed(2)} registrado correctamente')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Error registrando abono en Supabase')),
                    );
                  }
                }
              }
            },
            child: const Text('Guardar Abono'),
          ),
        ],
      ),
    );
  }

  void _showNewClientDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '300.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Cliente para Crédito'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre / Comercio', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: docCtrl,
                decoration: const InputDecoration(labelText: 'Cédula / RIF (ej. V-12345678)', prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono WhatsApp (ej. 58414...)', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: r'Límite de Crédito ($)', prefixIcon: Icon(Icons.attach_money)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && docCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final success = await ref.read(creditControllerProvider).createClient(
                      name: nameCtrl.text,
                      documentId: docCtrl.text,
                      phone: phoneCtrl.text,
                      creditLimitUsd: double.tryParse(limitCtrl.text) ?? 300.0,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Cliente de crédito registrado con éxito')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Error al registrar cliente en Supabase')),
                    );
                  }
                }
              }
            },
            child: const Text('Crear Cupo'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseHistoryDialog(BuildContext context, CreditClientModel acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: AppColors.primaryCharcoal),
            const SizedBox(width: 8),
            Expanded(child: Text('Historial de Consumo: ${acc.name}', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 550,
          height: 380,
          child: FutureBuilder<List<dynamic>>(
            future: () async {
              final client = SupabaseService().client;
              if (client == null) return [];
              try {
                return await client
                    .from('sales')
                    .select('invoice_number, total_usd, exchange_rate, payment_method, created_at')
                    .eq('client_id', acc.id)
                    .order('created_at', ascending: false)
                    .limit(20);
              } catch (_) {
                return [];
              }
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final sales = snapshot.data ?? [];
              if (sales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No hay compras previas registradas para ${acc.name}', style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = sales[index];
                  final invoice = s['invoice_number'] ?? 'INV-000';
                  final totalUsd = (s['total_usd'] as num?)?.toDouble() ?? 0.0;
                  final method = s['payment_method'] ?? 'EFECTIVO';
                  final date = s['created_at'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(s['created_at'])) : '';

                  return ListTile(
                    dense: true,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.receipt, size: 18, color: AppColors.primaryCharcoal),
                    ),
                    title: Text(invoice, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$date • Método: $method'),
                    trailing: Text('\$${totalUsd.toStringAsFixed(2)} USD', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreenDark)),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
