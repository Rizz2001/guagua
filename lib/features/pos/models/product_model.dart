class ProductModel {
  final String id;
  final String title;
  final double priceRetailUsd;
  final double? priceWholesaleUsd;
  final int? wholesaleMinQty;
  final double costUsd;
  final int stockUnits;
  final int unitsPerBox;
  final bool isCombo;
  final String? imageUrl;
  final String category;
  final String? barcode;
  final String? parentBoxId;
  final DateTime? expirationDate;

  ProductModel({
    required this.id,
    required this.title,
    required this.priceRetailUsd,
    this.priceWholesaleUsd,
    this.wholesaleMinQty,
    this.costUsd = 0.0,
    required this.stockUnits,
    this.unitsPerBox = 1,
    this.isCombo = false,
    this.imageUrl,
    required this.category,
    this.barcode,
    this.parentBoxId,
    this.expirationDate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      priceRetailUsd: (json['price_retail_usd'] as num).toDouble(),
      priceWholesaleUsd: json['price_wholesale_usd'] != null ? (json['price_wholesale_usd'] as num).toDouble() : null,
      wholesaleMinQty: json['wholesale_min_qty'] != null ? json['wholesale_min_qty'] as int : null,
      costUsd: json['cost_usd'] != null ? (json['cost_usd'] as num).toDouble() : 0.0,
      stockUnits: json['stock_units'] as int,
      unitsPerBox: json['units_per_box'] != null ? json['units_per_box'] as int : 1,
      isCombo: json['is_combo'] == true,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? 'General',
      barcode: json['barcode'] as String?,
      parentBoxId: json['parent_box_id'] as String?,
      expirationDate: json['expiration_date'] != null ? DateTime.parse(json['expiration_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price_retail_usd': priceRetailUsd,
    'price_wholesale_usd': priceWholesaleUsd,
    'wholesale_min_qty': wholesaleMinQty,
    'cost_usd': costUsd,
    'stock_units': stockUnits,
    'units_per_box': unitsPerBox,
    'is_combo': isCombo,
    'image_url': imageUrl,
    'category': category,
    'barcode': barcode,
    'parent_box_id': parentBoxId,
    'expiration_date': expirationDate?.toIso8601String(),
  };
}
