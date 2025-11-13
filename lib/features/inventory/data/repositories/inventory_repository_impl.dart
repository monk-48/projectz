import '../../../../core/utils/logger.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../models/inventory_item.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<InventoryItem>> getInventoryStream(String sellerId) {
    try {
      Logger.info('Getting inventory stream for seller: $sellerId');
      return remoteDataSource.getInventoryStream(sellerId);
    } catch (e) {
      Logger.error('Get inventory stream error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      Logger.info('Adding inventory item: ${item.name}');
      await remoteDataSource.addInventoryItem(item);
      Logger.info('Inventory item added successfully');
    } catch (e) {
      Logger.error('Add inventory item error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      Logger.info('Updating inventory item: ${item.id}');
      await remoteDataSource.updateInventoryItem(item);
      Logger.info('Inventory item updated successfully');
    } catch (e) {
      Logger.error('Update inventory item error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      Logger.info('Deleting inventory item: $itemId');
      await remoteDataSource.deleteInventoryItem(itemId);
      Logger.info('Inventory item deleted successfully');
    } catch (e) {
      Logger.error('Delete inventory item error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      return await remoteDataSource.getInventoryItem(itemId);
    } catch (e) {
      Logger.error('Get inventory item error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }
}

