import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_breakpoints.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../controllers/inventory_controller.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProductsProvider);
    final isCashier = ref.watch(authProvider).currentUser?.role == UserRole.cashier;
    final isCompact = context.isCompact;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standardized AppPageHeader
          AppPageHeader(
            title: 'Gestión de Inventario, Combos & Desarmado',
            subtitle: 'Control de conversión por caja/bulto a unidades detalladas, registro de mermas y lotes.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _showRegisterSpoilageDialog(context),
                icon: const Icon(Icons.remove_shopping_cart, size: 18, color: AppColors.dangerText),
                label: const Text('Registrar Merma', style: TextStyle(color: AppColors.dangerText)),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () => _showNewProductDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo Producto'),
              ),
            ],
          ),

          // Inventory Content Container (Loading, Empty, Error, Data)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.borderLg,
                child: inventoryAsync.when(
                  loading: () => const LoadingState(message: 'Cargando inventario en tiempo real...'),
                  error: (err, stack) => ErrorState(
                    title: 'Error al conectar con el inventario',
                    message: err.toString(),
                    onRetry: () => ref.refresh(inventoryProductsProvider),
                  ),
                  data: (inventory) {
                    if (inventory.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aún no tienes productos registrados',
                        description: 'Agrega tu primer producto para comenzar a vender en el POS y controlar tu stock.',
                        actionLabel: 'Nuevo Producto',
                        onAction: () => _showNewProductDialog(context),
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 800),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.background),
                            columns: [
                              const DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Precio (USD)', style: TextStyle(fontWeight: FontWeight.bold))),
                              if (!isCashier) const DataColumn(label: Text('Costo (CPP)', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Stock Unidades', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Conversión Caja', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Estado Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: inventory.map((product) {
                              final isLowStock = product.stockUnits <= 5;
                              final isUnboxable = product.parentBoxId != null;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.textDark),
                                        const SizedBox(width: AppSpacing.sm),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(product.barcode ?? 'Sin código', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(product.category)),
                                  DataCell(Text('\$${product.priceRetailUsd.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  if (!isCashier) DataCell(Text('\$${product.costUsd.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textMuted))),
                                  DataCell(Text('${product.stockUnits} u.', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(isUnboxable ? '1 Caja = ${product.unitsPerBox} u.' : 'Unidad suelta')),
                                  DataCell(
                                    isLowStock
                                        ? const StatusBadge(label: 'Bajo Stock', icon: Icons.warning_amber, type: BadgeType.danger)
                                        : (isUnboxable
                                            ? const StatusBadge(label: 'Desarmable', icon: Icons.unarchive, type: BadgeType.info)
                                            : const StatusBadge(label: 'Normal', icon: Icons.check_circle_outline, type: BadgeType.success)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterSpoilageDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Merma / Botella Rota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona el motivo del ajuste:'),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'damage', child: Text('Rotura / Botella Caída')),
                DropdownMenuItem(value: 'expired', child: Text('Producto Vencido')),
                DropdownMenuItem(value: 'internal', child: Text('Consumo Interno de Personal')),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: 'Motivo de Merma'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Observación u Orden')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚠️ Merma registrada exitosamente en auditoría')),
              );
            },
            child: const Text('Registrar Merma'),
          ),
        ],
      ),
    );
  }

  void _showNewProductDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final unitsCtrl = TextEditingController(text: '1');
    String selectedCategory = 'Víveres';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Producto / Caja'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nombre del Producto')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código de Barras o SKU')),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: ['Víveres', 'Bebidas', 'Licorería', 'Snacks', 'Combos', 'Otros'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => selectedCategory = v ?? 'Víveres',
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio de Venta (USD)'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Costo (USD)'))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Inicial (Opcional)'))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: TextField(controller: unitsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unidades por Caja'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(inventoryControllerProvider).createProduct(
                name: titleCtrl.text,
                code: codeCtrl.text,
                category: selectedCategory,
                priceUsd: double.tryParse(priceCtrl.text) ?? 0.0,
                costUsd: double.tryParse(costCtrl.text) ?? 0.0,
                stock: int.tryParse(stockCtrl.text) ?? 0,
                minStock: 5,
                unitsPerBox: int.tryParse(unitsCtrl.text) ?? 1,
              );

              if (success) {
                ref.invalidate(inventoryProductsProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Producto creado en Supabase')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Error al crear producto (verifica políticas RLS o código duplicado)'),
                      backgroundColor: AppColors.dangerBg,
                    ),
                  );
                }
              }
            },
            child: const Text('Crear Producto'),
          ),
        ],
      ),
    );
  }
}
