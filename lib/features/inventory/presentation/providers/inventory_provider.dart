import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/inventory_item.dart';

class InventoryProvider extends ChangeNotifier {
  final _inventoryRepository = ServiceLocator().inventoryRepository;
  final _auth = FirebaseAuth.instance;

  List<InventoryItem> _allItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _isAscending = true;
  String _filterByStatus = 'all';

  List<InventoryItem> get items => _filteredAndSortedItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get isAscending => _isAscending;
  String get filterByStatus => _filterByStatus;

  void updateItems(List<InventoryItem> items) {
    _allItems = items;
    notifyListeners();
  }

  List<InventoryItem> get _filteredAndSortedItems {
    List<InventoryItem> filtered = List.from(_allItems);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.brand.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    switch (_filterByStatus) {
      case 'low':
        filtered = filtered.where((item) => item.isLowStock && !item.isOutOfStock).toList();
        break;
      case 'out_of_stock':
        filtered = filtered.where((item) => item.isOutOfStock).toList();
        break;
      default:
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case 'brand':
        filtered.sort((a, b) => _isAscending
            ? a.brand.compareTo(b.brand)
            : b.brand.compareTo(a.brand));
        break;
      case 'quantity':
        filtered.sort((a, b) => _isAscending
            ? a.quantity.compareTo(b.quantity)
            : b.quantity.compareTo(a.quantity));
        break;
      case 'sku':
        filtered.sort((a, b) => _isAscending
            ? a.sku.compareTo(b.sku)
            : b.sku.compareTo(a.sku));
        break;
      case 'name':
      default:
        filtered.sort((a, b) => _isAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
    }

    return filtered;
  }

  Stream<List<InventoryItem>> getInventoryStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _inventoryRepository.getInventoryStream(currentUser.uid);
  }

  Future<bool> addInventoryItem(InventoryItem item) async {
    _setLoading(true);
    _clearError();

    try {
      await _inventoryRepository.addInventoryItem(item);
      Logger.info('Inventory item added successfully');
      _setLoading(false);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Add inventory item error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateInventoryItem(InventoryItem item) async {
    _setLoading(true);
    _clearError();

    try {
      await _inventoryRepository.updateInventoryItem(item);
      Logger.info('Inventory item updated successfully');
      _setLoading(false);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Update inventory item error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteInventoryItem(String itemId) async {
    _setLoading(true);
    _clearError();

    try {
      await _inventoryRepository.deleteInventoryItem(itemId);
      Logger.info('Inventory item deleted successfully');
      _setLoading(false);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Delete inventory item error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void toggleSortOrder() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  void setFilterByStatus(String status) {
    _filterByStatus = status;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}

