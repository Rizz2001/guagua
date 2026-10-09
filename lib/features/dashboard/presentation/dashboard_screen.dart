import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unified AppPageHeader from Shared Widgets
            AppPageHeader(
              title: 'Dashboard Financiero & Analíticas de Riesgo',
              subtitle: 'Visión integral de liquidez, dinero en caja, cartera colocada e índice de morosidad.',
              actions: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar Vistas'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  ),
                ),
              ],
            ),

            // Top Financial Metrics Grid (Responsive Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1024 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: constraints.maxWidth > 1024 ? 1.6 : 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      title: 'Dinero Real en Caja',
                      value: '\$0.00',
                      subtext: 'Efectivo + Pago Móvil + Zelle hoy',
                      icon: Icons.account_balance_wallet,
                      color: AppColors.successGreenDark,
                      badge: const StatusBadge(
                        label: 'En Caja',
                        icon: Icons.check_circle_outline,
                        type: BadgeType.success,
                      ),
                    ),
                    _buildMetricCard(
                      title: 'Capital en la Calle (Deuda)',
                      value: '\$0.00',
                      subtext: '0 clientes con crédito activo',
                      icon: Icons.credit_card,
                      color: AppColors.textDark,
                      badge: const StatusBadge(
                        label: 'Por Cobrar',
                        icon: Icons.assignment_outlined,
                        type: BadgeType.neutral,
                      ),
                    ),
                    // Cumpliendo skill flutter-pos-business-logic: Morosidad 0% -> "Sin Riesgo"
                    _buildMetricCard(
                      title: 'Índice de Morosidad',
                      value: '0.0%',
                      subtext: '0 clientes vencidos > 15 días',
                      icon: Icons.verified,
                      color: AppColors.successGreenDark,
                      badge: const StatusBadge(
                        label: 'Sin Riesgo',
                        icon: Icons.shield_outlined,
                        type: BadgeType.success,
                      ),
                    ),
                    _buildMetricCard(
                      title: 'Cobros de la Semana',
                      value: '\$0 / \$0',
                      subtext: '0% recaudado vs proyectado',
                      icon: Icons.trending_up,
                      color: AppColors.comboPurpleText,
                      badge: const StatusBadge(
                        label: 'Meta 80%+',
                        icon: Icons.track_changes,
                        type: BadgeType.info,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Section 2: Cashflow Rule Visualizer & Operational Alerts
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1024;

                final cashflowWidget = Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user, color: AppColors.primaryCharcoal, size: 22),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Regla de Oro de Flujo de Caja (Fina Rule)',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          '💡 "Una venta no es dinero en caja hasta que se cobra". El sistema diferencia estrictamente el Efectivo/Transferencia Recibido de la Cartera Otorgada a Crédito.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Comparison Bars
                      _buildCashflowBar('Ventas Totales Proyectadas', 0.0, 1.0, Colors.grey),
                      const SizedBox(height: AppSpacing.md),
                      _buildCashflowBar('Dinero Recaudado en Caja (USD)', 0.0, 1.0, AppColors.successGreenDark),
                      const SizedBox(height: AppSpacing.md),
                      _buildCashflowBar('Mercancía Entregada a Crédito', 0.0, 1.0, Colors.amber.shade800),
                    ],
                  ),
                );

                final alertsWidget = Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertas Operativas & Inventario',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildAlertTile('Sistema Operativo Limpio', 'No existen alertas de stock bajo ni vencimientos por el momento', AppColors.successGreen.withValues(alpha: 0.15), AppColors.successGreenDark),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: cashflowWidget),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(flex: 5, child: alertsWidget),
                    ],
                  );
                }

                return Column(
                  children: [
                    cashflowWidget,
                    const SizedBox(height: AppSpacing.xl),
                    alertsWidget,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required Widget badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              badge,
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtext,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowBar(String label, double valueUsd, double totalUsd, Color color) {
    final percent = totalUsd > 0 ? (valueUsd / totalUsd).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('\$${valueUsd.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.borderSm,
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertTile(String title, String subtitle, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: AppColors.textDark, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
