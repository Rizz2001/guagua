import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../../../core/services/outbox_service.dart';
import '../../../core/services/print_spooler_service.dart';
import '../../../core/utils/currency_engine.dart';

/// Estado de la comanda/carrito de compra en el Punto de Venta
class PosCartState {
  final List<CartItemModel> items;
  final double activeExchangeRateBcv;
  final String selectedCategory;
  final String searchQuery;

  PosCartState({
    this.items = const [],
    this.activeExchangeRateBcv = 36.50,
    this.selectedCategory = 'Todos',
    this.searchQuery = '',
  });

  double get subtotalUsd => items.fold(0.0, (sum, item) => sum + item.totalPriceUsd);
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PosCartState copyWith({
    List<CartItemModel>? items,
    double? activeExchangeRateBcv,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return PosCartState(
      items: items ?? this.items,
      activeExchangeRateBcv: activeExchangeRateBcv ?? this.activeExchangeRateBcv,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PosCartNotifier extends Notifier<PosCartState> {
  @override
  PosCartState build() {
    _fetchExchangeRate();
    return PosCartState();
  }

  Future<void> _fetchExchangeRate() async {
    final rate = await SupabaseService().getActiveExchangeRate();
    state = state.copyWith(activeExchangeRateBcv: rate);
  }

  Future<void> updateExchangeRate(double newRate, {String userId = 'admin'}) async {
    await SupabaseService().updateDailyExchangeRate(newRate, userId);
    state = state.copyWith(activeExchangeRateBcv: newRate);
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void addProduct(ProductModel product) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final currentItem = state.items[existingIndex];
      final updatedItem = currentItem.copyWith(quantity: currentItem.quantity + 1);
      final updatedList = List<CartItemModel>.from(state.items);
      updatedList[existingIndex] = updatedItem;
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItemModel(product: product, quantity: 1);
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, int delta) {
    final updatedList = <CartItemModel>[];
    for (final item in state.items) {
      if (item.product.id == productId) {
        final newQty = item.quantity + delta;
        if (newQty > 0) {
          updatedList.add(item.copyWith(quantity: newQty));
        }
      } else {
        updatedList.add(item);
      }
    }
    state = state.copyWith(items: updatedList);
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }

  Future<bool> processSale({
    required String cashierId,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
    required bool shouldPrint,
    double igtfUsd = 0.0,
  }) async {
    if (state.items.isEmpty) return false;

    try {
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      
      // EMPAQUETADO INMUTABLE DE LA VENTA
      // Se congela la tasa actual y se calculan los precios fijos de ese momento exacto.
      final double frozenExchangeRate = state.activeExchangeRateBcv;
      
      final List<Map<String, dynamic>> itemsPayload = state.items.map((item) {
        return {
          'product_id': item.product.id,
          'product_name': item.product.title,
          'quantity': item.quantity,
          'unit_price_usd': item.unitPriceUsd,
          'is_wholesale': item.checkWholesaleApplied,
          // CRÍTICO: Pre-calculamos y congelamos el precio en Bs.
          'unit_price_bs': CurrencyEngine.usdToVes(item.unitPriceUsd, frozenExchangeRate),
          'subtotal_usd': item.totalPriceUsd,
        };
      }).toList();

      final Map<String, dynamic> salePayload = {
        'invoice_number': invoiceNumber,
        'cashier_id': cashierId,
        'total_usd': state.subtotalUsd,
        'igtf_usd': igtfUsd,
        'exchange_rate': frozenExchangeRate,
        'payment_method': paymentMethod,
        'payment_details': paymentDetails,
        'items': itemsPayload,
      };

      // Mandar a Hive (Outbox). El servicio intentará sincronizar inmediatamente si hay red.
      await OutboxService.saveSaleAndTrySync(salePayload);

      // Si el cajero seleccionó imprimir, intentamos imprimir. Si no, o si falla, va a la cola de impresión.
      if (shouldPrint) {
        await PrintSpoolerService.printOrSpool(invoiceNumber, salePayload);
      }

      clearCart();
      return true;
    } catch (e) {
      debugPrint('Error encolando venta offline: $e');
      return false;
    }
  }
}

final posCartProvider = NotifierProvider<PosCartNotifier, PosCartState>(PosCartNotifier.new);

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  final client = SupabaseService().client;
  if (client == null) return Stream.value([]);

  return client.from('products').stream(primaryKey: ['id']).eq('is_active', true).map((list) {
    return list.map((json) => ProductModel(
    id: json['id'],
    title: json['name'],
    priceRetailUsd: (json['price_usd'] as num).toDouble(),
    priceWholesaleUsd: json['price_wholesale_usd'] != null ? (json['price_wholesale_usd'] as num).toDouble() : null,
    wholesaleMinQty: json['wholesale_min_qty'] as int?,
    costUsd: json['cost_usd'] != null ? (json['cost_usd'] as num).toDouble() : 0.0,
    stockUnits: json['stock'] as int,
    unitsPerBox: json['units_per_box'] as int? ?? 1,
    isCombo: json['is_combo'] == true,
    category: json['category'] ?? 'General',
    barcode: json['code'],
    parentBoxId: json['parent_box_id'],
  )).toList();
  });
});
