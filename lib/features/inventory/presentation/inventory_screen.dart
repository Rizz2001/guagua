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
            subtitle: 'Control de conversión por caja/bulto a unidades detalladas, precios al mayor, mermas y transferencias.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _showStockTransfersDialog(context),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Transferencias'),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                          constraints: const BoxConstraints(minWidth: 850),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.background),
                            columns: [
                              const DataColumn(label: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Precio Detal (USD)', style: TextStyle(fontWeight: FontWeight.bold))),
                              const DataColumn(label: Text('Precio Mayor (USD)', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                        Icon(
                                          product.isCombo ? Icons.all_inclusive : Icons.inventory_2_outlined,
                                          size: 18,
                                          color: product.isCombo ? AppColors.comboPurpleText : AppColors.textDark,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                if (product.isCombo) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.comboPurpleBg,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text('COMBO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.comboPurpleText)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(product.barcode ?? 'Sin código', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(product.category)),
                                  DataCell(Text('\$${product.priceRetailUsd.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(
                                    product.priceWholesaleUsd != null
                                        ? Text(
                                            '\$${product.priceWholesaleUsd!.toStringAsFixed(2)} (min ${product.wholesaleMinQty ?? 6})',
                                            style: const TextStyle(color: AppColors.warningText, fontWeight: FontWeight.w600),
                                          )
                                        : const Text('-', style: TextStyle(color: AppColors.textMuted)),
                                  ),
                                  if (!isCashier) DataCell(Text('\$${product.costUsd.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textMuted))),
                                  DataCell(Text('${product.stockUnits} u.', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(isUnboxable ? '1 Caja = ${product.unitsPerBox} u.' : (product.isCombo ? 'Combo' : 'Unidad suelta'))),
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
    final products = ref.read(inventoryProductsProvider).value ?? [];
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos en inventario para registrar mermas')),
      );
      return;
    }

    String selectedProductId = products.first.id;
    String selectedProductName = products.first.title;
    final qtyCtrl = TextEditingController(text: '1');
    final obsCtrl = TextEditingController();
    String selectedReason = 'Botella Rota / Daño Físico';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Merma / Daño Físico'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedProductId,
                  items: products
                      .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.title} (Stock: ${p.stockUnits})')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedProductId = val;
                        selectedProductName = products.firstWhere((p) => p.id == val).title;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Producto Afectado'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  items: [
                    'Botella Rota / Daño Físico',
                    'Empaque Roto / Abierto',
                    'Producto Vencido / Caducado',
                    'Consumo Interno Autorizado',
                    'Error de Conteo / Ajuste'
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setModalState(() => selectedReason = val ?? selectedReason),
                  decoration: const InputDecoration(labelText: 'Causa de la Merma'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad de Unidades Dañadas'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: obsCtrl, decoration: const InputDecoration(labelText: 'Observación u Orden')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final user = ref.read(authProvider).currentUser;
                final reportedBy = user?.id ?? '00000000-0000-0000-0000-000000000000';

                final ok = await ref.read(inventoryControllerProvider).registerSpoilage(
                      productId: selectedProductId,
                      productName: selectedProductName,
                      quantity: qty,
                      reason: '$selectedReason: ${obsCtrl.text.trim()}',
                      reportedBy: reportedBy,
                    );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (ok) {
                    ref.invalidate(inventoryProductsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('⚠️ Merma de $qty uds descontada del stock y registrada')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Error al registrar merma en Supabase')),
                    );
                  }
                }
              },
              child: const Text('Registrar Merma'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewProductDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final wholesalePriceCtrl = TextEditingController();
    final wholesaleMinQtyCtrl = TextEditingController(text: '6');
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final unitsCtrl = TextEditingController(text: '1');
    String selectedCategory = 'Víveres';
    bool isCombo = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Producto / Combo Enterprise'),
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
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Detal (USD)'))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Costo (USD)'))),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: TextField(controller: wholesalePriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Mayor (USD, Opcional)'))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: TextField(controller: wholesaleMinQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mínimo Mayorista (uds)'))),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Inicial'))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: TextField(controller: unitsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unidades por Caja'))),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('¿Es un Combo Promocional?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Producto compuesto que incluye múltiples unidades/artículos', style: TextStyle(fontSize: 12)),
                  value: isCombo,
                  onChanged: (val) => setDialogState(() => isCombo = val),
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
                  priceWholesaleUsd: double.tryParse(wholesalePriceCtrl.text),
                  wholesaleMinQty: int.tryParse(wholesaleMinQtyCtrl.text),
                  costUsd: double.tryParse(costCtrl.text) ?? 0.0,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                  minStock: 5,
                  unitsPerBox: int.tryParse(unitsCtrl.text) ?? 1,
                  isCombo: isCombo,
                );

                if (success) {
                  ref.invalidate(inventoryProductsProvider);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Producto creado en Supabase con precios configurados')),
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
      ),
    );
  }

  void _showStockTransfersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final transfersAsync = ref.watch(stockTransfersStreamProvider);
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transferencias Internas de Mercancía'),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showNewTransferDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nueva Guía'),
                ),
              ],
            ),
            content: SizedBox(
              width: 650,
              height: 400,
              child: transfersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error al cargar transferencias: $e')),
                data: (transfers) {
                  if (transfers.isEmpty) {
                    return const Center(
                      child: Text('No hay transferencias de mercancía registradas entre sucursales.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: transfers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = transfers[index];
                      final isPending = t.status == 'EN_TRANSITO';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPending ? AppColors.warningBg : AppColors.successGreen.withValues(alpha: 0.2),
                          child: Icon(
                            isPending ? Icons.local_shipping : Icons.check,
                            color: isPending ? AppColors.warningText : AppColors.successGreenDark,
                            size: 20,
                          ),
                        ),
                        title: Text('${t.transferNumber}: ${t.productName} (${t.quantity} u.)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('De: ${t.originStore} ➔ A: ${t.destinationStore} • Estado: ${t.status}'),
                        trailing: isPending
                            ? ElevatedButton(
                                onPressed: () async {
                                  final user = ref.read(authProvider).currentUser;
                                  final ok = await ref.read(inventoryControllerProvider).confirmStockTransfer(
                                    transferId: t.id,
                                    productId: t.productId,
                                    quantity: t.quantity,
                                    receivedBy: user?.id ?? '00000000-0000-0000-0000-000000000000',
                                  );
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('✅ Entrada de stock confirmada en la sucursal')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreenDark),
                                child: const Text('Confirmar Entrada'),
                              )
                            : const Text('Confirmada', style: TextStyle(color: AppColors.successGreenDark, fontWeight: FontWeight.bold)),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        },
      ),
    );
  }

  void _showNewTransferDialog(BuildContext context) {
    final products = ref.read(inventoryProductsProvider).value ?? [];
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles para transferir')),
      );
      return;
    }

    String selectedOrigin = 'Almacén Central (Bodega)';
    String selectedDest = 'Sucursal Principal - Centro';
    String selectedProductId = products.first.id;
    String selectedProductName = products.first.title;
    final qtyCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Guía de Transferencia de Stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedOrigin,
                  items: ['Almacén Central (Bodega)', 'Sucursal Principal - Centro', 'Sucursal 2 - Bodegón Este']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedOrigin = v ?? selectedOrigin),
                  decoration: const InputDecoration(labelText: 'Almacén / Tienda de Origen'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedDest,
                  items: ['Sucursal Principal - Centro', 'Sucursal 2 - Bodegón Este', 'Almacén Central (Bodega)']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedDest = v ?? selectedDest),
                  decoration: const InputDecoration(labelText: 'Sucursal de Destino'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedProductId,
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.title} (Stock: ${p.stockUnits})'))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setModalState(() {
                        selectedProductId = v;
                        selectedProductName = products.firstWhere((p) => p.id == v).title;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Producto a Despachar'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad a Despachar (uds)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final user = ref.read(authProvider).currentUser;
                final dispatchedBy = user?.id ?? '00000000-0000-0000-0000-000000000000';

                final ok = await ref.read(inventoryControllerProvider).createStockTransfer(
                  originStore: selectedOrigin,
                  destinationStore: selectedDest,
                  productId: selectedProductId,
                  productName: selectedProductName,
                  quantity: qty,
                  dispatchedBy: dispatchedBy,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (ok) {
                    ref.invalidate(inventoryProductsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('📦 Guía despachada: $qty uds de $selectedProductName en tránsito')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Error al crear guía de transferencia')),
                    );
                  }
                }
              },
              child: const Text('Despachar Guía'),
            ),
          ],
        ),
      ),
    );
  }
}
