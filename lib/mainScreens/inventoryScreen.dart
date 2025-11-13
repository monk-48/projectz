import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projectz/mainScreens/addInventoryScreen.dart';

class InventoryItem {
  final String id;
  final String brand;
  final String name;
  final String sku;
  final String seller;
  final int capacity;
  final int quantity;

  InventoryItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.sku,
    required this.seller,
    required this.capacity,
    required this.quantity,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      brand: data['brand'] ?? '',
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      seller: data['seller'] ?? '',
      capacity: data['capacity'] ?? 0,
      quantity: data['quantity'] ?? 0,
    );
  }

  double get stockPercentage => capacity > 0 ? (quantity / capacity) * 100 : 0;
  
  bool get isLowStock => quantity < (capacity * 0.2);
  
  bool get isOutOfStock => quantity == 0;
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  
  String _sortBy = 'name'; // name, brand, quantity, sku
  bool _isAscending = true;
  String _searchQuery = '';
  String _filterByStatus = 'all'; // all, low, out_of_stock

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  // Single dummy item for visualization
  InventoryItem getDummyItem() {
    return InventoryItem(
      id: 'demo-001',
      brand: 'Bosch',
      name: 'Professional Power Drill GSB 16 (Demo)',
      sku: 'BOSCH-GSB-16-DEMO',
      seller: _auth.currentUser?.uid ?? '',
      capacity: 50,
      quantity: 12,
    );
  }

  Stream<List<InventoryItem>> getInventoryStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('inventory')
        .where('seller', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          // Fetch real data from Firestore
          List<InventoryItem> items = snapshot.docs
              .map((doc) => InventoryItem.fromFirestore(doc))
              .toList();

          // Add dummy item for visualization at the beginning
          items.insert(0, getDummyItem());

          // Apply filtering
          items = _applyFilters(items);

          // Apply sorting
          items = _applySorting(items);

          return items;
        });
  }

  List<InventoryItem> _applyFilters(List<InventoryItem> items) {
    // Search filter
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final query = _searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(query) ||
            item.brand.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query);
      }).toList();
    }

    // Status filter
    switch (_filterByStatus) {
      case 'low':
        items = items.where((item) => item.isLowStock && !item.isOutOfStock).toList();
        break;
      case 'out_of_stock':
        items = items.where((item) => item.isOutOfStock).toList();
        break;
      default:
        break;
    }

    return items;
  }

  List<InventoryItem> _applySorting(List<InventoryItem> items) {
    switch (_sortBy) {
      case 'brand':
        items.sort((a, b) => _isAscending
            ? a.brand.compareTo(b.brand)
            : b.brand.compareTo(a.brand));
        break;
      case 'quantity':
        items.sort((a, b) => _isAscending
            ? a.quantity.compareTo(b.quantity)
            : b.quantity.compareTo(a.quantity));
        break;
      case 'sku':
        items.sort((a, b) => _isAscending
            ? a.sku.compareTo(b.sku)
            : b.sku.compareTo(a.sku));
        break;
      case 'name':
      default:
        items.sort((a, b) => _isAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
    }
    return items;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Name', 'name'),
            _buildSortOption('Brand', 'brand'),
            _buildSortOption('Quantity', 'quantity'),
            _buildSortOption('SKU', 'sku'),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.purple,
              ),
              title: Text(_isAscending ? 'Ascending' : 'Descending'),
              onTap: () {
                setState(() => _isAscending = !_isAscending);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return ListTile(
      leading: _sortBy == value
          ? const Icon(Icons.check, color: Colors.purple)
          : null,
      title: Text(label),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter By Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('All Items', 'all'),
            _buildFilterOption('Low Stock', 'low'),
            _buildFilterOption('Out of Stock', 'out_of_stock'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return ListTile(
      leading: _filterByStatus == value
          ? const Icon(Icons.check_circle, color: Colors.purple)
          : const Icon(Icons.circle_outlined),
      title: Text(label),
      onTap: () {
        setState(() => _filterByStatus = value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name, brand, or SKU...',
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
            ),
          ),
          
          // Filter and Sort Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('Filter'),
                        onSelected: (_) => _showFilterOptions(),
                        avatar: _filterByStatus != 'all'
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                        backgroundColor: _filterByStatus != 'all'
                            ? Colors.purple
                            : Colors.grey.shade300,
                        labelStyle: TextStyle(
                          color: _filterByStatus != 'all' ? Colors.white : Colors.black,
                        ),
                      ),
                      FilterChip(
                        label: const Text('Sort'),
                        onSelected: (_) => _showSortOptions(),
                        avatar: const Icon(Icons.unfold_more, color: Colors.white, size: 18),
                        backgroundColor: Colors.purple,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Inventory List
          Expanded(
            child: StreamBuilder<List<InventoryItem>>(
              stream: getInventoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No items match your search'
                              : 'No inventory items yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildInventoryCard(item, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item, BuildContext context) {
    final stockColor = item.isOutOfStock
        ? Colors.red
        : item.isLowStock
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.brand,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stockColor),
                  ),
                  child: Text(
                    item.isOutOfStock
                        ? 'Out of Stock'
                        : item.isLowStock
                            ? 'Low Stock'
                            : 'In Stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // SKU and Capacity info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SKU: ${item.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacity: ${item.capacity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stock progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${item.quantity}/${item.capacity} (${item.stockPercentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: item.stockPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to edit inventory item
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit ${item.name} - coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Delete inventory item with confirmation
                      _showDeleteConfirmation(item, context);
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(InventoryItem item, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('inventory').doc(item.id).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
