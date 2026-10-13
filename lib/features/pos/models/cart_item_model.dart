import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  bool isWholesaleApplied;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.isWholesaleApplied = false,
  });

  /// Calcula el precio unitario en USD considerando el volumen o tarifa al mayor
  double get unitPriceUsd {
    if (product.priceWholesaleUsd != null && 
        product.wholesaleMinQty != null && 
        quantity >= product.wholesaleMinQty!) {
      return product.priceWholesaleUsd!;
    }
    return product.priceRetailUsd;
  }

  /// Indica si se ha aplicado automáticamente el precio al mayor
  bool get checkWholesaleApplied {
    return product.priceWholesaleUsd != null && 
           product.wholesaleMinQty != null && 
           quantity >= product.wholesaleMinQty!;
  }

  double get totalPriceUsd => double.parse((unitPriceUsd * quantity).toStringAsFixed(2));

  CartItemModel copyWith({int? quantity, bool? isWholesaleApplied}) {
    return CartItemModel(
      product: product,
      quantity: quantity ?? this.quantity,
      isWholesaleApplied: isWholesaleApplied ?? this.isWholesaleApplied,
    );
  }
}
