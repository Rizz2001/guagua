import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';

class SupplierPurchaseScreen extends StatefulWidget {
  const SupplierPurchaseScreen({super.key});

  @override
  State<SupplierPurchaseScreen> createState() => _SupplierPurchaseScreenState();
}

class _SupplierPurchaseScreenState extends State<SupplierPurchaseScreen> {
  double _currentStock = 100;
  double _currentCost = 1.00;
  double _newQuantity = 50;
  double _newCost = 1.30;

  @override
  Widget build(BuildContext context) {
    // Fórmulas CPP: Costo Promedio Ponderado
    final double totalCurrentVal = _currentStock * _currentCost;
    final double totalNewVal = _newQuantity * _newCost;
    final double newTotalStock = _currentStock + _newQuantity;
    final double calculatedCpp = newTotalStock > 0 ? (totalCurrentVal + totalNewVal) / newTotalStock : 0.0;
    final isCompact = context.isCompact;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standardized AppPageHeader
            AppPageHeader(
              title: 'Gestión de Compras a Proveedores & Costo Promedio (CPP)',
              subtitle: 'Calculadora de Costo Promedio Ponderado para mantener márgenes de ganancia exactos.',
              actions: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.note_add, size: 18),
                  label: const Text('Registrar Factura de Compra'),
                ),
              ],
            ),

            // CPP Interactive Calculator Card
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
                  Text(
                    'Simulador / Recálculo de Costo Promedio Ponderado (CPP)',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;

                      final currentStockSection = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stock Actual en Sistema', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(text: _currentStock.toString()),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => _currentStock = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(labelText: 'Unidades Actuales'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(text: _currentCost.toString()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() => _currentCost = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(labelText: r'Costo Actual ($)'),
                          ),
                        ],
                      );

                      final newPurchaseSection = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nueva Mercancía del Proveedor', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(text: _newQuantity.toString()),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => _newQuantity = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(labelText: 'Unidades Recibidas'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(text: _newCost.toString()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() => _newCost = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(labelText: r'Nuevo Costo de Compra ($)'),
                          ),
                        ],
                      );

                      final resultSection = Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Costo Promedio Recalculado (CPP):', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '\$${calculatedCpp.toStringAsFixed(3)} USD',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.successGreenDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Nuevo Stock Total: ${newTotalStock.toInt()} uds'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('✅ CPP actualizado a \$${calculatedCpp.toStringAsFixed(3)} en catálogo')),
                                );
                              },
                              child: const Text('Aplicar Nuevo CPP'),
                            ),
                          ],
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: currentStockSection),
                            const SizedBox(width: 24),
                            Expanded(child: newPurchaseSection),
                            const SizedBox(width: 24),
                            Expanded(child: resultSection),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          currentStockSection,
                          const SizedBox(height: 16),
                          newPurchaseSection,
                          const SizedBox(height: 16),
                          resultSection,
                        ],
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
