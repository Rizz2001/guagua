import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../pos/models/product_model.dart';

class SupplierPurchaseScreen extends ConsumerStatefulWidget {
  const SupplierPurchaseScreen({super.key});

  @override
  ConsumerState<SupplierPurchaseScreen> createState() => _SupplierPurchaseScreenState();
}

class _SupplierPurchaseScreenState extends ConsumerState<SupplierPurchaseScreen> {
  ProductModel? _selectedProduct;
  final TextEditingController _currentStockCtrl = TextEditingController(text: '0');
  final TextEditingController _currentCostCtrl = TextEditingController(text: '0.00');
  final TextEditingController _newQtyCtrl = TextEditingController(text: '0');
  final TextEditingController _newCostCtrl = TextEditingController(text: '0.00');
  final TextEditingController _supplierNameCtrl = TextEditingController();

  double _currentStock = 0;
  double _currentCost = 0.0;
  double _newQuantity = 0;
  double _newCost = 0.0;

  @override
  void dispose() {
    _currentStockCtrl.dispose();
    _currentCostCtrl.dispose();
    _newQtyCtrl.dispose();
    _newCostCtrl.dispose();
    _supplierNameCtrl.dispose();
    super.dispose();
  }

  void _onProductSelected(ProductModel product) {
    setState(() {
      _selectedProduct = product;
      _currentStock = product.stockUnits.toDouble();
      _currentCost = product.costUsd;
      _currentStockCtrl.text = _currentStock.toInt().toString();
      _currentCostCtrl.text = _currentCost.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(inventoryProductsProvider);
    final products = productsAsync.value ?? [];

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
            AppPageHeader(
              title: 'Gestión de Compras a Proveedores & Costo Promedio (CPP)',
              subtitle: 'Calculadora de Costo Promedio Ponderado para mantener márgenes de ganancia exactos.',
            ),

            // Selector de Producto Real del Catálogo
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar Producto para Recálculo de Costo',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  if (products.isEmpty)
                    const Text('No hay productos registrados en el inventario aún.', style: TextStyle(color: AppColors.textMuted))
                  else
                    DropdownButtonFormField<ProductModel>(
                      initialValue: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Selecciona producto del inventario',
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      items: products.map((p) {
                        return DropdownMenuItem<ProductModel>(
                          value: p,
                          child: Text('${p.title} (Stock: ${p.stockUnits} | Costo: \$${p.costUsd.toStringAsFixed(2)})'),
                        );
                      }).toList(),
                      onChanged: (p) {
                        if (p != null) _onProductSelected(p);
                      },
                    ),
                ],
              ),
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
                            controller: _currentStockCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => _currentStock = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(labelText: 'Unidades Actuales'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _currentCostCtrl,
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
                            controller: _newQtyCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => _newQuantity = double.tryParse(v) ?? 0),
                            decoration: const InputDecoration(labelText: 'Unidades Recibidas'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newCostCtrl,
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
                              onPressed: _selectedProduct != null && newTotalStock > 0
                                  ? () async {
                                      final client = SupabaseService().client;
                                      if (client != null) {
                                        try {
                                          await client.from('products').update({
                                            'cost_usd': calculatedCpp,
                                            'stock': newTotalStock.toInt(),
                                          }).eq('id', _selectedProduct!.id);

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('✅ CPP actualizado a \$${calculatedCpp.toStringAsFixed(3)} y stock a ${newTotalStock.toInt()} uds en Supabase')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('❌ Error actualizando producto: $e')),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  : null,
                              child: const Text('Aplicar Nuevo CPP al Producto'),
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
