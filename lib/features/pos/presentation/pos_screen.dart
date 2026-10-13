import 'package:flutter/material.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/barcode_listener.dart';
import '../../../core/utils/currency_engine.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../controllers/pos_controller.dart';
import '../models/product_model.dart';
import '../../../core/services/print_spooler_service.dart';
import '../../../shared/widgets/supervisor_auth_dialog.dart';
import 'widgets/payment_modal_dialog.dart';
import 'widgets/pos_product_card.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  late BarcodeScannerListener _barcodeListener;

  @override
  void initState() {
    super.initState();
    _barcodeListener = BarcodeScannerListener(
      onBarcodeScanned: (code) {
        final productsList = ref.read(productsProvider).value ?? [];
        final found = productsList.firstWhere(
          (p) => p.barcode == code,
          orElse: () => ProductModel(id: '', title: '', priceRetailUsd: 0, stockUnits: 0, category: ''),
        );
        if (found.id.isNotEmpty) {
          ref.read(posCartProvider.notifier).addProduct(found);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Producto escaneado: ${found.title}'),
              duration: const Duration(seconds: 1),
              backgroundColor: AppColors.primaryCharcoal,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _barcodeListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(posCartProvider);
    final productsAsync = ref.watch(productsProvider);
    final categories = ['Todos', 'Café', 'Bebidas', 'Víveres', 'Combos'];

    final filteredProducts = productsAsync.value?.where((p) {
      final matchesCategory = cartState.selectedCategory == 'Todos' || p.category == cartState.selectedCategory;
      final matchesSearch = p.title.toLowerCase().contains(cartState.searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(cartState.searchQuery));
      return matchesCategory && matchesSearch;
    }).toList() ?? [];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            final leftPanel = Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Bar & Search & Tasa BCV
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront, size: 20, color: AppColors.primaryCharcoal),
                              const SizedBox(width: 8),
                              Text('Mi Comercio / Punto de Venta', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),

                        // Indicador de Tasa BCV del Día
                        InkWell(
                          onTap: () => _showUpdateExchangeRateDialog(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.comboPurpleBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.comboPurpleText.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇻🇪 ', style: TextStyle(fontSize: 14)),
                                Text(
                                  'Tasa BCV: ${cartState.activeExchangeRateBcv} Bs/USD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.comboPurpleText,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.edit, size: 14, color: AppColors.comboPurpleText),
                              ],
                            ),
                          ),
                        ),

                        // Apertura Manual de Gaveta de Dinero (Anti-Fraude)
                        InkWell(
                          onTap: () => _handleManualCashDrawer(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.point_of_sale, size: 16, color: AppColors.primaryCharcoal),
                                const SizedBox(width: 6),
                                Text(
                                  'Gaveta',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Search Input
                        SizedBox(
                          width: 220,
                          child: TextField(
                            onChanged: (val) => ref.read(posCartProvider.notifier).updateSearchQuery(val),
                            decoration: const InputDecoration(
                              hintText: 'Buscar o escanear...',
                              prefixIcon: Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Filter Pills
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = cartState.selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => ref.read(posCartProvider.notifier).selectCategory(cat),
                              selectedColor: AppColors.primaryCharcoal,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textDark,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.cardBorder),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Grid
                    Expanded(
                      child: productsAsync.when(
                        loading: () => const LoadingState(message: 'Cargando catálogo del POS...'),
                        error: (err, stack) => ErrorState(
                          title: 'Error al cargar el catálogo de productos',
                          message: err.toString(),
                          onRetry: () => ref.refresh(productsProvider),
                        ),
                        data: (_) {
                          if (filteredProducts.isEmpty) {
                            return EmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No hay productos disponibles',
                              description: cartState.searchQuery.isNotEmpty
                                  ? 'No encontramos productos que coincidan con "${cartState.searchQuery}".'
                                  : 'Aún no tienes productos en esta categoría.',
                            );
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 750 ? 3 : (constraints.maxWidth > 450 ? 2 : 1);
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1.3,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return PosProductCard(
                                    product: product,
                                    onAdd: () => ref.read(posCartProvider.notifier).addProduct(product),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );

            final rightPanel = Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: AppColors.cardBorder)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Detalle de la Orden',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cartState.items.isNotEmpty)
                          TextButton(
                            onPressed: () => _handleClearCart(context),
                            child: const Text('Limpiar', style: TextStyle(color: AppColors.dangerText)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selected Items List
                    Expanded(
                      child: cartState.items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('La comanda está vacía', style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: cartState.items.length,
                              itemBuilder: (context, index) {
                                final item = cartState.items[index];
                                final isWholesale = item.checkWholesaleApplied;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.title,
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                            ),
                                            if (isWholesale)
                                              Container(
                                                margin: const EdgeInsets.only(top: 2),
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warningBg,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '🏷️ Precio al Mayor Aplicado',
                                                  style: TextStyle(fontSize: 10, color: AppColors.warningText, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${item.unitPriceUsd.toStringAsFixed(2)} x ${item.quantity} = \$${item.totalPriceUsd.toStringAsFixed(2)}',
                                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            onPressed: () => _handleDecrementItem(context, item.product.id, item.product.title, item.quantity),
                                          ),
                                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            onPressed: () => ref.read(posCartProvider.notifier).updateQuantity(item.product.id, 1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Order Summary & Checkout Floating Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Ítems:', style: TextStyle(color: AppColors.textMuted)),
                              Text('${cartState.totalItemCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Total VES (Tasa ${cartState.activeExchangeRateBcv}):',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyEngine.formatVes(CurrencyEngine.usdToVes(cartState.subtotalUsd, cartState.activeExchangeRateBcv)),
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.successGreenDark),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total USD:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyEngine.formatUsd(cartState.subtotalUsd),
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checkout CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cartState.items.isEmpty
                            ? null
                            : () {
                                _showPaymentDialog(
                                  context,
                                  cartState.subtotalUsd,
                                  cartState.activeExchangeRateBcv,
                                  cartState.items.map((i) => {
                                    'name': i.product.title,
                                    'qty': i.quantity,
                                    'price': i.unitPriceUsd,
                                  }).toList(),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(
                          'Procesar Pago (${CurrencyEngine.formatUsd(cartState.subtotalUsd)})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 7, child: leftPanel),
                  Expanded(flex: 4, child: rightPanel),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(flex: 6, child: leftPanel),
                  Expanded(flex: 4, child: rightPanel),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, double totalUsd, double exchangeRate, List<Map<String, dynamic>> itemsSummary) {
    final cashierId = ref.read(authProvider).currentUser?.id ?? '00000000-0000-0000-0000-000000000000';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentModalDialog(
        totalUsd: totalUsd,
        exchangeRate: exchangeRate,
        itemsSummary: itemsSummary,
        onPaymentSuccess: (bool shouldPrint, Map<String, dynamic> paymentInfo) async {
          // Lógica Atómica de Supabase: Guardar venta, ítems y desarmar cajas
          final success = await ref.read(posCartProvider.notifier).processSale(
            cashierId: cashierId,
            paymentMethod: paymentInfo['payment_method'] ?? 'MIXED',
            paymentDetails: paymentInfo,
            shouldPrint: shouldPrint,
            igtfUsd: (paymentInfo['igtf_usd'] as num?)?.toDouble() ?? 0.0,
          );

          if (success) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Venta registrada exitosamente y stock actualizado'),
                backgroundColor: AppColors.successGreenDark,
              ),
            );
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Hubo un error al procesar la venta en la base de datos.'),
                backgroundColor: AppColors.dangerBg,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _handleClearCart(BuildContext context) async {
    final auth = await SupervisorAuthDialog.show(
      context: context,
      action: 'VOID_CART',
      actionTitle: 'Vaciado de Comanda Completa',
      description: 'Se eliminarán todos los ítems de la orden actual.',
    );
    if (auth != null && auth.authorized) {
      ref.read(posCartProvider.notifier).clearCart();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Comanda vaciada y registrada en auditoría')),
        );
      }
    }
  }

  Future<void> _handleDecrementItem(BuildContext context, String productId, String productName, int currentQty) async {
    if (currentQty <= 1) {
      final auth = await SupervisorAuthDialog.show(
        context: context,
        action: 'VOID_ITEM',
        actionTitle: 'Anulación de Ítem de Comanda',
        description: 'Se removerá el ítem "$productName" de la comanda actual.',
        details: {'product_id': productId, 'product_name': productName},
      );
      if (auth != null && auth.authorized) {
        ref.read(posCartProvider.notifier).updateQuantity(productId, -1);
      }
    } else {
      ref.read(posCartProvider.notifier).updateQuantity(productId, -1);
    }
  }

  Future<void> _handleManualCashDrawer(BuildContext context) async {
    final auth = await SupervisorAuthDialog.show(
      context: context,
      action: 'MANUAL_CASH_DRAWER',
      actionTitle: 'Apertura Manual de Gaveta',
      description: 'Apertura de gaveta de dinero sin venta asociada.',
    );
    if (auth != null && auth.authorized) {
      await PrintSpoolerService.openCashDrawer();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💵 Gaveta de dinero abierta y registrada en auditoría'),
            backgroundColor: AppColors.successGreenDark,
          ),
        );
      }
    }
  }

  void _showUpdateExchangeRateDialog(BuildContext context) {
    final controller = TextEditingController(text: ref.read(posCartProvider).activeExchangeRateBcv.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Tasa del Día (BCV/Paralelo)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nueva Tasa Bs/USD',
            suffixText: 'Bs',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                ref.read(posCartProvider.notifier).updateExchangeRate(newRate);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Guardar Tasa'),
          ),
        ],
      ),
    );
  }
}
