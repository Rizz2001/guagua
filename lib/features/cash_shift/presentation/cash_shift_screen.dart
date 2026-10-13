import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/cash_shift_controller.dart';

class CashShiftScreen extends ConsumerStatefulWidget {
  const CashShiftScreen({super.key});

  @override
  ConsumerState<CashShiftScreen> createState() => _CashShiftScreenState();
}

class _CashShiftScreenState extends ConsumerState<CashShiftScreen> {
  final TextEditingController _usdCashCtrl = TextEditingController(text: '0.00');
  final TextEditingController _vesCashCtrl = TextEditingController(text: '0.00');
  final TextEditingController _pagoMovilCtrl = TextEditingController(text: '0.00');
  final TextEditingController _zelleCtrl = TextEditingController(text: '0.00');

  double _countUsdCash = 0.0;
  double _countVesCash = 0.0;
  double _countPagoMovilVes = 0.0;
  double _countZelleUsd = 0.0;

  @override
  void dispose() {
    _usdCashCtrl.dispose();
    _vesCashCtrl.dispose();
    _pagoMovilCtrl.dispose();
    _zelleCtrl.dispose();
    super.dispose();
  }

  void _showOpenShiftDialog(BuildContext context) {
    final fundCtrl = TextEditingController(text: '50.00');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir Turno de Caja (Cierre X)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el fondo inicial de sencillo entregado al cajero:'),
            const SizedBox(height: 12),
            TextField(
              controller: fundCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: r'Fondo Inicial ($)',
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final fund = double.tryParse(fundCtrl.text) ?? 50.0;
              final user = ref.read(authProvider).currentUser;
              final cashierId = user?.id ?? 'c98e0535-b4ac-4c4b-b30c-d41076d282c9';
              final ok = await ref.read(cashShiftProvider.notifier).openShift(
                    cashierId: cashierId,
                    openingFundUsd: fund,
                  );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Turno abierto con fondo inicial de \$${fund.toStringAsFixed(2)}')),
                  );
                }
              }
            },
            child: const Text('Abrir Turno'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(cashShiftProvider);
    final isCompact = context.isCompact;
    const double exchangeRate = 36.50;

    final double countVesInUsd = _countVesCash / exchangeRate;
    final double countPagoMovilInUsd = _countPagoMovilVes / exchangeRate;

    final double initialFund = shiftState.fondoCajaUsd;
    final double totalCountedUsd = initialFund + _countUsdCash + countVesInUsd + countPagoMovilInUsd + _countZelleUsd;
    final double expectedSalesUsd = shiftState.salesUsdInShift;
    final double expectedSystemTotalUsd = initialFund + expectedSalesUsd;
    final double differenceUsd = totalCountedUsd - expectedSystemTotalUsd;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'Control de Caja: Arqueo & Cierre X/Z de Turno',
              subtitle: 'Conteo físico de billetes, cuadre por canal (Efectivo, Pago Móvil, Zelle) y reporte de cierre.',
              actions: [
                if (shiftState.isShiftOpen)
                  StatusBadge(
                    label: 'Turno Activo (${shiftState.activeShiftId?.substring(0, 8) ?? ""})',
                    icon: Icons.access_time_filled,
                    type: BadgeType.success,
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _showOpenShiftDialog(context),
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: const Text('Abrir Turno (Fondo Inicial)'),
                  ),
              ],
            ),

            if (!shiftState.isShiftOpen)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.point_of_sale, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No hay ningún turno de caja abierto actualmente',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Abre el turno indicando el fondo inicial de sencillo para comenzar a registrar arqueos y ventas.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showOpenShiftDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Abrir Turno de Caja'),
                      ),
                    ],
                  ),
                ),
              )
            else
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
                        _buildCountingRow(
                          title: 'Fondo Inicial de Caja (Sencillo)',
                          subtitle: 'Fondo entregado al iniciar el turno',
                          valueText: '\$${initialFund.toStringAsFixed(2)}',
                        ),
                        const Divider(height: AppSpacing.xl),
                        _buildEditableCountingRow(
                          title: 'Efectivo Físico USD en Caja',
                          subtitle: 'Billetes contados en gaveta',
                          controller: _usdCashCtrl,
                          onChanged: (val) => setState(() => _countUsdCash = double.tryParse(val) ?? 0),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildEditableCountingRow(
                          title: 'Efectivo Físico VES (Bolívares)',
                          subtitle: 'Billetes en Bs contados en gaveta (~ \$${countVesInUsd.toStringAsFixed(2)})',
                          controller: _vesCashCtrl,
                          onChanged: (val) => setState(() => _countVesCash = double.tryParse(val) ?? 0),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildEditableCountingRow(
                          title: 'Transferencias / Pago Móvil Bs.',
                          subtitle: 'Conciliación bancaria hoy (~ \$${countPagoMovilInUsd.toStringAsFixed(2)})',
                          controller: _pagoMovilCtrl,
                          onChanged: (val) => setState(() => _countPagoMovilVes = double.tryParse(val) ?? 0),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildEditableCountingRow(
                          title: 'Transferencias Digitales Zelle USD',
                          subtitle: 'Depósitos verificados en cuenta USD',
                          controller: _zelleCtrl,
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
                          '2. Resumen & Cuadre de Arqueo (Cierre Z)',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSummaryRow('Total Contado por el Cajero', '\$${totalCountedUsd.toStringAsFixed(2)}', AppColors.primaryCharcoal),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Esperado por Sistema (Fondo + Ventas)', '\$${expectedSystemTotalUsd.toStringAsFixed(2)}', AppColors.textDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Ventas Registradas en Turno', '\$${expectedSalesUsd.toStringAsFixed(2)}', AppColors.textMuted),
                        const Divider(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              differenceUsd >= 0 ? 'Sobrante:' : 'Faltante:',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: differenceUsd >= 0 ? AppColors.successGreenDark : AppColors.dangerText,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '\$${differenceUsd.abs().toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: differenceUsd >= 0 ? AppColors.successGreenDark : AppColors.dangerText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('📄 Arqueo preliminar (Cierre X) generado')),
                                  );
                                },
                                icon: const Icon(Icons.print, size: 18),
                                label: const Text('Cierre X'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('¿Confirmar Cierre Z Definitivo?'),
                                      content: Text(
                                        'Se registrará el cierre en la base de datos con un total contado de \$${totalCountedUsd.toStringAsFixed(2)} USD.',
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            final ok = await ref.read(cashShiftProvider.notifier).closeShift(
                                                  actualCashUsd: _countUsdCash,
                                                  actualCashBs: _countVesCash,
                                                  differenceUsd: differenceUsd,
                                                );
                                            if (context.mounted && ok) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('🔒 Turno cerrado exitosamente con Reporte Z')),
                                              );
                                            }
                                          },
                                          child: const Text('Confirmar Cierre Z'),
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

  Widget _buildCountingRow({
    required String title,
    required String subtitle,
    required String valueText,
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(valueText, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildEditableCountingRow({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
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
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        ),
      ],
    );
  }
}
