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
      isCombo: false,
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

class InventoryController {
  final SupabaseService _supabase = SupabaseService();

  Future<bool> createProduct({
    required String name,
    required String code,
    required String category,
    required double priceUsd,
    required double costUsd,
    required int stock,
    required int minStock,
    String? parentBoxId,
    required int unitsPerBox,
  }) async {
    final client = _supabase.client;
    if (client == null) return false;

    try {
      // 1. Intentar vía RPC (SECURITY DEFINER) para evitar bloqueos por RLS
      try {
        final rpcRes = await client.rpc('crear_producto', params: {
          'p_name': name,
          'p_code': code,
          'p_category': category,
          'p_price_usd': priceUsd,
          'p_cost_usd': costUsd,
          'p_stock': stock,
          'p_min_stock': minStock,
          'p_parent_box_id': parentBoxId,
          'p_units_per_box': unitsPerBox,
        });
        if (rpcRes != null && rpcRes['success'] == true) {
          return true;
        }
      } catch (rpcError) {
        debugPrint('RPC crear_producto no disponible, intentando inserción directa: $rpcError');
      }

      // 2. Inserción directa en tabla
      await client.from('products').insert({
        'name': name,
        'code': code,
        'category': category,
        'price_usd': priceUsd,
        'cost_usd': costUsd,
        'stock': stock,
        'min_stock': minStock,
        'parent_box_id': parentBoxId,
        'units_per_box': unitsPerBox,
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
      
      // Restar del stock actual (usamos rpc si estuviera, pero al no haber, consultamos y restamos, o simplemente lo logueamos)
      // Para una solución atómica perfecta habría que crear un RPC, pero como el skill pide registrarlo obligatoriamente:
      final p = await client.from('products').select('stock').eq('id', productId).single();
      final currentStock = p['stock'] as int;
      await client.from('products').update({'stock': currentStock - quantity}).eq('id', productId);
      
      return true;
    } catch (e) {
      debugPrint('Error registering spoilage: $e');
      return false;
    }
  }
}

final inventoryControllerProvider = Provider((ref) => InventoryController());
