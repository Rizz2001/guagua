import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../pos/models/product_model.dart';

final inventoryProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final client = SupabaseService().client;
  if (client == null) return Stream.value([]);

  try {
    return client.from('products').stream(primaryKey: ['id']).order('created_at', ascending: false).map((list) {
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
  } catch (e) {
    debugPrint('Error fetching inventory products: $e');
    return Stream.value([]);
  }
});

class StockTransferModel {
  final String id;
  final String transferNumber;
  final String originStore;
  final String destinationStore;
  final String productId;
  final String productName;
  final int quantity;
  final String status;
  final DateTime createdAt;

  StockTransferModel({
    required this.id,
    required this.transferNumber,
    required this.originStore,
    required this.destinationStore,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory StockTransferModel.fromJson(Map<String, dynamic> json) {
    return StockTransferModel(
      id: json['id'] as String,
      transferNumber: json['transfer_number'] as String? ?? 'TRF-000',
      originStore: json['origin_store'] as String? ?? 'Almacén Central',
      destinationStore: json['destination_store'] as String? ?? 'Sucursal',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Producto',
      quantity: json['quantity'] as int? ?? 0,
      status: json['status'] as String? ?? 'EN_TRANSITO',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

final stockTransfersStreamProvider = StreamProvider<List<StockTransferModel>>((ref) {
  final client = SupabaseService().client;
  if (client == null) return Stream.value([]);

  try {
    return client
        .from('stock_transfers')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list.map((json) => StockTransferModel.fromJson(json)).toList());
  } catch (e) {
    debugPrint('Error obteniendo transferencias: $e');
    return Stream.value([]);
  }
});

class InventoryController {
  final SupabaseService _supabase = SupabaseService();

  Future<bool> createProduct({
    required String name,
    required String code,
    required String category,
    required double priceUsd,
    double? priceWholesaleUsd,
    int? wholesaleMinQty,
    required double costUsd,
    required int stock,
    required int minStock,
    String? parentBoxId,
    required int unitsPerBox,
    bool isCombo = false,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      // Inserción directa en tabla con todos los campos Enterprise
      await client.from('products').insert({
        'name': name,
        'code': code,
        'category': category,
        'price_usd': priceUsd,
        'price_wholesale_usd': priceWholesaleUsd,
        'wholesale_min_qty': wholesaleMinQty,
        'cost_usd': costUsd,
        'stock': stock,
        'min_stock': minStock,
        'parent_box_id': parentBoxId,
        'units_per_box': unitsPerBox,
        'is_combo': isCombo,
        'is_active': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating product: $e');
      return false;
    }
  }

  Future<bool> registerSpoilage({
    required String productId,
    required String productName,
    required int quantity,
    required String reason,
    required String reportedBy,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('spoilage_logs').insert({
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'reason': reason,
        'reported_by': reportedBy,
      });
      
      final p = await client.from('products').select('stock').eq('id', productId).single();
      final currentStock = p['stock'] as int;
      await client.from('products').update({'stock': currentStock - quantity}).eq('id', productId);
      
      return true;
    } catch (e) {
      debugPrint('Error registering spoilage: $e');
      return false;
    }
  }

  Future<bool> createStockTransfer({
    required String originStore,
    required String destinationStore,
    required String productId,
    required String productName,
    required int quantity,
    required String dispatchedBy,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      final transferNumber = 'TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await client.from('stock_transfers').insert({
        'transfer_number': transferNumber,
        'origin_store': originStore,
        'destination_store': destinationStore,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'status': 'EN_TRANSITO',
        'dispatched_by': dispatchedBy,
      });

      // Descontar del almacén de origen
      final p = await client.from('products').select('stock').eq('id', productId).single();
      final currentStock = p['stock'] as int;
      await client.from('products').update({'stock': (currentStock - quantity).clamp(0, 999999)}).eq('id', productId);

      return true;
    } catch (e) {
      debugPrint('Error al crear transferencia de stock: $e');
      return false;
    }
  }

  Future<bool> confirmStockTransfer({
    required String transferId,
    required String productId,
    required int quantity,
    required String receivedBy,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      await client.from('stock_transfers').update({
        'status': 'CONFIRMADA',
        'received_by': receivedBy,
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', transferId);

      // Sumar al stock de la tienda de destino
      final p = await client.from('products').select('stock').eq('id', productId).single();
      final currentStock = p['stock'] as int;
      await client.from('products').update({'stock': currentStock + quantity}).eq('id', productId);

      return true;
    } catch (e) {
      debugPrint('Error al confirmar transferencia: $e');
      return false;
    }
  }
}

final inventoryControllerProvider = Provider((ref) => InventoryController());
