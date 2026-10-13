import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/print_spooler_service.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _printAccountingReport(BuildContext context, DashboardMetrics metrics) async {
    try {
      final pdfBytes = await generateAccountingPdf(
        metrics: metrics,
        storeName: PrintSpoolerService.activeStoreName,
      );
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: 'Reporte_Contable_GuaguaPOS');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  void _exportCsv(BuildContext context, List<Map<String, dynamic>> sales) {
    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ventas registradas para exportar')),
      );
      return;
    }
    final csvContent = generateSalesCsv(sales);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Libro de Ventas Exportado (CSV / Excel)'),
        content: SizedBox(
          width: 600,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Copia o utiliza el formato CSV para importarlo en Excel o enviarlo a contabilidad:'),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csvContent,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvContent));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 CSV copiado al portapapeles exitosamente')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar al Portapapeles'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = context.isCompact;
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final metrics = metricsAsync.value ?? DashboardMetrics();

    final isRiskFree = metrics.delinquencyRatePercentage == 0.0;
    final isHighRisk = metrics.delinquencyRatePercentage > 15.0;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'Dashboard Financiero & Analíticas de Riesgo',
              subtitle: 'Visión integral de liquidez, dinero en caja, margen bruto, IGTF e índice de morosidad.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _exportCsv(context, metrics.salesLedger),
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text('Exportar CSV'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () => _printAccountingReport(context, metrics),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Reporte PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCharcoal),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Actualizar métricas',
                  onPressed: () => ref.refresh(dashboardMetricsProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),

            // Top Financial Metrics Grid (Responsive Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200
                    ? 5
                    : (constraints.maxWidth > 900
                        ? 3
                        : (constraints.maxWidth > 600 ? 2 : 1));

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: constraints.maxWidth > 1024 ? 1.5 : 1.35,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      title: 'Dinero Real en Caja',
                      value: '\$${metrics.realCashInDrawerUsd.toStringAsFixed(2)}',
                      subtext: 'Efectivo + Pago Móvil + Zelle recaudado',
                      icon: Icons.account_balance_wallet,
                      color: AppColors.successGreenDark,
                      badge: const StatusBadge(
                        label: 'En Caja',
                        icon: Icons.check_circle_outline,
                        type: BadgeType.success,
                      ),
                    ),
                    _buildMetricCard(
                      title: 'Ganancia Neta (Margen)',
                      value: '\$${metrics.netProfitUsd.toStringAsFixed(2)}',
                      subtext: '${metrics.profitMarginPercentage.toStringAsFixed(1)}% margen sobre CPP',
                      icon: Icons.savings_outlined,
                      color: AppColors.successGreenDark,
                      badge: const StatusBadge(
                        label: 'Margen Real',
                        icon: Icons.pie_chart_outline,
                        type: BadgeType.success,
                      ),
                    ),
                    _buildMetricCard(
                      title: 'Capital en la Calle (Deuda)',
                      value: '\$${metrics.capitalInStreetUsd.toStringAsFixed(2)}',
                      subtext: '${metrics.activeCreditClientsCount} clientes con crédito activo',
                      icon: Icons.credit_card,
                      color: AppColors.textDark,
                      badge: const StatusBadge(
                        label: 'Por Cobrar',
                        icon: Icons.assignment_outlined,
                        type: BadgeType.neutral,
                      ),
                    ),
                    _buildMetricCard(
                      title: 'Índice de Morosidad',
                      value: '${metrics.delinquencyRatePercentage.toStringAsFixed(1)}%',
                      subtext: '${metrics.overdueClientsCount} deudas vencidas > 15 días',
                      icon: Icons.verified,
                      color: isRiskFree
                          ? AppColors.successGreenDark
                          : (isHighRisk ? AppColors.dangerText : Colors.amber.shade800),
                      badge: StatusBadge(
                        label: isRiskFree
                            ? 'Sin Riesgo'
                            : (isHighRisk ? 'Riesgo Alto' : 'En Observación'),
                        icon: Icons.shield_outlined,
                        type: isRiskFree
                            ? BadgeType.success
                            : (isHighRisk ? BadgeType.danger : BadgeType.warning),
                      ),
                    ),
                    _buildMetricCard(
                      title: 'Cobros vs Proyectado',
                      value: '\$${metrics.weeklySalesCollectedUsd.toStringAsFixed(2)} / \$${metrics.weeklySalesProjectedUsd.toStringAsFixed(2)}',
                      subtext: metrics.weeklySalesProjectedUsd > 0
                          ? '${((metrics.weeklySalesCollectedUsd / metrics.weeklySalesProjectedUsd) * 100).toStringAsFixed(0)}% recaudado en caja'
                          : '0% recaudado vs proyectado',
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Regla de Oro: Flujo de Caja vs. Ventas a Crédito',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Control estricto para evitar iliquidez por exceso de cuentas por cobrar.',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isRiskFree ? AppColors.successGreen.withValues(alpha: 0.15) : AppColors.warningBg,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isRiskFree ? Icons.check_circle : Icons.warning_amber,
                                  size: 16,
                                  color: isRiskFree ? AppColors.successGreenDark : AppColors.warningText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isRiskFree ? 'Saludable' : 'Alerta de Crédito',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isRiskFree ? AppColors.successGreenDark : AppColors.warningText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildCashflowBar(
                        label: 'Dinero Real Recaudado en Caja',
                        amountUsd: metrics.realCashInDrawerUsd,
                        totalUsd: metrics.realCashInDrawerUsd + metrics.capitalInStreetUsd,
                        color: AppColors.successGreenDark,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCashflowBar(
                        label: 'Deuda Colocada en la Calle (Por Cobrar)',
                        amountUsd: metrics.capitalInStreetUsd,
                        totalUsd: metrics.realCashInDrawerUsd + metrics.capitalInStreetUsd,
                        color: AppColors.textMuted,
                      ),
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
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.textDark),
                          const SizedBox(width: 8),
                          Text(
                            'Alertas Operativas en Vivo',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (metrics.delinquencyRatePercentage > 10.0) ...[
                        _buildAlertTile(
                          'Morosidad Alta Detectada',
                          '${metrics.delinquencyRatePercentage.toStringAsFixed(1)}% de la cartera supera los 15 días.',
                          AppColors.dangerBg,
                          AppColors.dangerText,
                          Icons.warning_amber_rounded,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (metrics.lowStockAlerts.isNotEmpty) ...[
                        ...metrics.lowStockAlerts.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _buildAlertTile(
                                'Agotamiento Próximo',
                                item,
                                AppColors.warningBg,
                                AppColors.warningText,
                                Icons.inventory_2_outlined,
                              ),
                            )),
                      ] else ...[
                        _buildAlertTile(
                          'Stock Óptimo',
                          'Todos los productos cuentan con existencias por encima del mínimo.',
                          AppColors.successGreen.withValues(alpha: 0.1),
                          AppColors.successGreenDark,
                          Icons.check_circle_outline,
                        ),
                      ],
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: cashflowWidget),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 4, child: alertsWidget),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      cashflowWidget,
                      const SizedBox(height: AppSpacing.lg),
                      alertsWidget,
                    ],
                  );
                }
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              badge,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowBar({
    required String label,
    required double amountUsd,
    required double totalUsd,
    required Color color,
  }) {
    final percent = totalUsd > 0 ? (amountUsd / totalUsd).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
            Text('\$${amountUsd.toStringAsFixed(2)} (${(percent * 100).toStringAsFixed(0)}%)', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
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

  Widget _buildAlertTile(String title, String subtitle, Color bg, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
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
