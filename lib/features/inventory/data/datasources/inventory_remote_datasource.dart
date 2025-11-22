import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../models/inventory_item.dart';

abstract class InventoryRemoteDataSource {
  Stream<List<InventoryItem>> getInventoryStream(String sellerId);
  Future<void> addInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String itemId);
  Future<InventoryItem?> getInventoryItem(String itemId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore firestore;

  InventoryRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<InventoryItem>> getInventoryStream(String sellerId) {
    try {
      return firestore
          .collection(AppConstants.inventoryCollection)
          .where('seller', isEqualTo: sellerId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      final data = item.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await firestore
          .collection(AppConstants.inventoryCollection)
          .add(data);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final data = item.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await firestore
          .collection(AppConstants.inventoryCollection)
          .doc(item.id)
          .update(data);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteInventoryItem(String itemId) async {
    try {
      await firestore
          .collection(AppConstants.inventoryCollection)
          .doc(itemId)
          .delete();
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.inventoryCollection)
          .doc(itemId)
          .get();
      
      if (!doc.exists) {
        return null;
      }
      
      return InventoryItem.fromFirestore(doc);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

