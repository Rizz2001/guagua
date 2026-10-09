import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/empty_state.dart';

class CreditAccountItem {
  final String id;
  final String clientName;
  final String phone;
  final double creditLimitUsd;
  final double currentBalanceUsd;
  final int daysOverdue;

  CreditAccountItem({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.creditLimitUsd,
    required this.currentBalanceUsd,
    required this.daysOverdue,
  });

  double get availableCreditUsd => creditLimitUsd - currentBalanceUsd;
}

class CreditManagementScreen extends StatefulWidget {
  const CreditManagementScreen({super.key});

  @override
  State<CreditManagementScreen> createState() => _CreditManagementScreenState();
}

class _CreditManagementScreenState extends State<CreditManagementScreen> {
  final List<CreditAccountItem> _accounts = [];

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standardized AppPageHeader
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

          // Accounts List Table / Cards / Empty State
          Expanded(
            child: _accounts.isEmpty
                ? EmptyState(
                    icon: Icons.credit_score_outlined,
                    title: 'Aún no tienes clientes registrados con cupo de crédito',
                    description: 'Registra un cliente y asígnale un cupo de crédito para comenzar a gestionar fiados y recordatorios.',
                    actionLabel: 'Nuevo Cliente / Cupo',
                    onAction: () => _showNewClientDialog(context),
                  )
                : ListView.builder(
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final acc = _accounts[index];
                      return _buildClientCreditCard(acc);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCreditCard(CreditAccountItem acc) {
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

    final usageRatio = (acc.currentBalanceUsd / acc.creditLimitUsd).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 750;

        final clientInfo = Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryCharcoal.withValues(alpha: 0.1),
              child: Text(
                acc.clientName.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryCharcoal),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc.clientName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Tel: +${acc.phone}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                    child: Text('Deuda: \$${acc.currentBalanceUsd.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Límite: \$${acc.creditLimitUsd.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                valueColor: AlwaysStoppedAnimation<Color>(usageRatio > 0.8 ? AppColors.dangerText : AppColors.primaryCharcoal),
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showAbonoDialog(acc),
              icon: const Icon(Icons.attach_money, size: 16),
              label: const Text('Abonar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                WhatsAppService.sendDebtReminder(
                  phone: acc.phone,
                  clientName: acc.clientName,
                  totalDueUsd: acc.currentBalanceUsd,
                  exchangeRate: 36.50,
                  pagoMovilDetails: '0414-1234567 / J-501928370',
                  zelleDetails: 'pagos@guagua.com',
                );
              },
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

  void _showAbonoDialog(CreditAccountItem acc) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Abono a ${acc.clientName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo Actual Deudor: \$${acc.currentBalanceUsd.toStringAsFixed(2)} USD'),
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
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                setState(() {
                  final idx = _accounts.indexWhere((a) => a.id == acc.id);
                  if (idx >= 0) {
                    final newBal = (acc.currentBalanceUsd - amount).clamp(0.0, 100000.0);
                    _accounts[idx] = CreditAccountItem(
                      id: acc.id,
                      clientName: acc.clientName,
                      phone: acc.phone,
                      creditLimitUsd: acc.creditLimitUsd,
                      currentBalanceUsd: newBal,
                      daysOverdue: newBal == 0 ? 0 : acc.daysOverdue,
                    );
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🎉 Abono de \$${amount.toStringAsFixed(2)} registrado en caja')),
                );
              }
            },
            child: const Text('Guardar Abono en Caja'),
          ),
        ],
      ),
    );
  }

  void _showNewClientDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '300.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Cliente para Crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre / Comercio')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono WhatsApp (584...)')),
            const SizedBox(height: 10),
            TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: r'Límite de Crédito ($)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                setState(() {
                  _accounts.add(
                    CreditAccountItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      clientName: nameCtrl.text,
                      phone: phoneCtrl.text,
                      creditLimitUsd: double.tryParse(limitCtrl.text) ?? 300.0,
                      currentBalanceUsd: 0.0,
                      daysOverdue: 0,
                    ),
                  );
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Crear Cupo'),
          ),
        ],
      ),
    );
  }
}
