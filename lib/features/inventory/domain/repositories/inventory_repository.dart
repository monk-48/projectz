import '../../../../models/inventory_item.dart';

abstract class InventoryRepository {
  Stream<List<InventoryItem>> getInventoryStream(String sellerId);
  Future<void> addInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String itemId);
  Future<InventoryItem?> getInventoryItem(String itemId);
}

