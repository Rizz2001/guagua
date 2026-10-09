import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/status_badge.dart';

class CashShiftScreen extends StatefulWidget {
  const CashShiftScreen({super.key});

  @override
  State<CashShiftScreen> createState() => _CashShiftScreenState();
}

class _CashShiftScreenState extends State<CashShiftScreen> {
  final double _initialFundUsd = 50.0;
  double _countUsdCash = 370.0;
  double _countVesCash = 1825.0; // ~ 50 USD at 36.50
  double _countPagoMovilVes = 2920.0; // ~ 80 USD
  double _countZelleUsd = 120.0;

  @override
  Widget build(BuildContext context) {
    const double exchangeRate = 36.50;
    final double countVesInUsd = _countVesCash / exchangeRate;
    final double countPagoMovilInUsd = _countPagoMovilVes / exchangeRate;
    
    // Contado total en caja
    final double totalCountedUsd = _initialFundUsd + _countUsdCash + countVesInUsd + countPagoMovilInUsd + _countZelleUsd;

    // Regla de Negocio: Esperado = Fondo inicial + Ventas registradas por canal
    const double expectedSalesUsd = 620.0;
    final double expectedSystemTotalUsd = _initialFundUsd + expectedSalesUsd; // $670.0 total
    final double differenceUsd = totalCountedUsd - expectedSystemTotalUsd;

    final isCompact = context.isCompact;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized AppPageHeader with StatusBadge
            AppPageHeader(
              title: 'Control de Caja: Arqueo & Cierre X/Z de Turno',
              subtitle: 'Conteo físico de billetes, cuadre por canal (Efectivo, Pago Móvil, Zelle) y reporte de cierre.',
              actions: const [
                StatusBadge(
                  label: 'Turno Activo #1042',
                  icon: Icons.access_time_filled,
                  type: BadgeType.success,
                ),
              ],
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1024;

                final countingSection = Container(
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
                        '1. Conteo de Dinero Físico y Canales Digitales',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCountingField(
                        title: 'Fondo Inicial de Caja (Sencillo)',
                        value: '\$${_initialFundUsd.toStringAsFixed(2)}',
                        subtitle: 'Fondo entregado al iniciar el turno',
                        isEditable: false,
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildCountingField(
                        title: 'Efectivo Físico USD en Caja',
                        value: '\$${_countUsdCash.toStringAsFixed(2)}',
                        subtitle: 'Billetes contados en gaveta',
                        isEditable: true,
                        onChanged: (val) => setState(() => _countUsdCash = double.tryParse(val) ?? 0),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCountingField(
                        title: 'Efectivo Físico VES (Bolívares)',
                        value: 'Bs. ${_countVesCash.toStringAsFixed(2)} (~ \$${countVesInUsd.toStringAsFixed(2)})',
                        subtitle: 'Billetes en Bs contados en gaveta',
                        isEditable: true,
                        onChanged: (val) => setState(() => _countVesCash = double.tryParse(val) ?? 0),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCountingField(
                        title: 'Pago Móvil / Transferencias VES',
                        value: 'Bs. ${_countPagoMovilVes.toStringAsFixed(2)} (~ \$${countPagoMovilInUsd.toStringAsFixed(2)})',
                        subtitle: 'Verificado en extracto bancario',
                        isEditable: true,
                        onChanged: (val) => setState(() => _countPagoMovilVes = double.tryParse(val) ?? 0),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCountingField(
                        title: 'Pagos Zelle USD',
                        value: '\$${_countZelleUsd.toStringAsFixed(2)}',
                        subtitle: 'Confirmados en aplicación Zelle',
                        isEditable: true,
                        onChanged: (val) => setState(() => _countZelleUsd = double.tryParse(val) ?? 0),
                      ),
                    ],
                  ),
                );

                final summarySection = Container(
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
                        '2. Cuadre del Cierre Z',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSummaryRow('Esperado por Sistema (Fondo + Ventas):', '\$${expectedSystemTotalUsd.toStringAsFixed(2)}', AppColors.textDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSummaryRow('Total Ingresado y Declarado:', '\$${totalCountedUsd.toStringAsFixed(2)}', AppColors.primaryCharcoal),
                      const Divider(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Diferencia de Cierre:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                          StatusBadge(
                            label: differenceUsd == 0
                                ? 'Cuadre Perfecto (\$0.00)'
                                : (differenceUsd > 0
                                    ? 'Sobrante (+\$${differenceUsd.toStringAsFixed(2)})'
                                    : 'Faltante (-\$${differenceUsd.abs().toStringAsFixed(2)})'),
                            icon: differenceUsd == 0 ? Icons.check_circle : (differenceUsd > 0 ? Icons.arrow_upward : Icons.warning),
                            type: differenceUsd == 0 ? BadgeType.success : (differenceUsd > 0 ? BadgeType.info : BadgeType.danger),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('📄 Reporte X generado (Solo Lectura)')),
                                );
                              },
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Informe X'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar Cierre Z Definitivo'),
                                    content: const Text('¿Estás seguro de cerrar el turno de caja? Esta acción imprimirá el Reporte Z inmutable y reiniciará el saldo para el próximo turno.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('🔒 Turno de Caja cerrado exitosamente con Reporte Z')),
                                          );
                                        },
                                        child: const Text('Cerrar Turno Z'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.lock, size: 18),
                              label: const Text('Cierre Z'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryCharcoal,
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: countingSection),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(flex: 5, child: summarySection),
                    ],
                  );
                }

                return Column(
                  children: [
                    countingSection,
                    const SizedBox(height: AppSpacing.xl),
                    summarySection,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountingField({
    required String title,
    required String value,
    required String subtitle,
    required bool isEditable,
    ValueChanged<String>? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
      ],
    );
  }
}
