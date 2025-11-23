import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectz/mainScreens/profileScreen.dart';
import 'package:projectz/mainScreens/ordersScreen.dart';
import 'package:projectz/mainScreens/addProduct/selectTypeScreen.dart';
import 'package:projectz/models/inventory_item.dart';

/// Home Screen - Landing page after authentication
/// Following Clean Architecture and SOLID principles
/// Single Responsibility: Display dashboard with inventory overview
/// Open/Closed: Extensible design for additional features
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  bool _isLoading = true;
  String _errorMessage = "";
  String _shopName = "My Shop";
  String _profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  /// Initialize screen and load necessary data
  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);

    try {
      await _loadShopInfo();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error initializing screen: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load dashboard";
        });
      }
    }
  }

  /// Load shop information from Firestore
  Future<void> _loadShopInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userData = await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .get();

      if (userData.exists && mounted) {
        final data = userData.data()!;
        setState(() {
          // Use shopName if available, fallback to sellerName, then default
          _shopName = data["shopName"] ?? data["sellerName"] ?? "My Shop";
          // Load user's profile picture
          _profileImageUrl = data["sellerAvatarUrl"] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error loading shop info: $e");
      // Continue with default values
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildDashboardContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Product',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Builds the app bar with navigation buttons
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _shopName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.purple,
      automaticallyImplyLeading: false,
      // Profile button on top-left with user's profile picture
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: _navigateToProfile,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: _profileImageUrl.isNotEmpty
                ? NetworkImage(_profileImageUrl)
                : null,
            child: _profileImageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.purple,
                  )
                : null,
          ),
        ),
      ),
      // Orders button on top-right
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: _navigateToOrders,
          tooltip: 'Orders',
        ),
      ],
    );
  }

  /// Loading view
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Main dashboard content with inventory table
  Widget _buildDashboardContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    return Column(
      children: [
        _buildHeaderSection(),
        const Divider(height: 1),
        Expanded(
          child: _buildInventoryTable(),
        ),
      ],
    );
  }

  /// Header section with dashboard title and summary
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildRefreshButton(),
            ],
          ),
          const SizedBox(height: 8),
          // Shop name centered and bold
          Text(
            _shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Inventory Overview',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All items in your inventory',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Refresh button
  Widget _buildRefreshButton() {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.purple),
      onPressed: () {
        setState(() {});
      },
      tooltip: 'Refresh',
    );
  }

  /// Error view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Inventory table widget
  Widget _buildInventoryTable() {
    return StreamBuilder<List<InventoryItem>>(
      stream: _getInventoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading inventory: ${snapshot.error}'),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyInventoryView();
        }

        return _buildInventoryDataTable(items);
      },
    );
  }

  /// Stream of inventory items from Firestore
  Stream<List<InventoryItem>> _getInventoryStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('inventory')
        .where('seller', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .toList();
    });
  }

  /// Empty inventory view
  Widget _buildEmptyInventoryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Inventory Items',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start by adding items to your inventory',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Inventory data table
  Widget _buildInventoryDataTable(List<InventoryItem> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.purple.shade100),
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 40,
                child: Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Brand',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'SKU',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Capacity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: items.map((item) => _buildDataRow(item)).toList(),
        ),
      ),
    );
  }

  /// Individual data row for an inventory item
  DataRow _buildDataRow(InventoryItem item) {
    final stockColor = item.isOutOfStock
        ? Colors.red
        : item.isLowStock
            ? Colors.orange
            : Colors.green;

    final statusText = item.isOutOfStock
        ? 'Out of Stock'
        : item.isLowStock
            ? 'Low Stock'
            : 'In Stock';

    return DataRow(
      cells: [
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
            onPressed: () => _showEditDialog(item),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        DataCell(Text(item.brand)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(item.sku)),
        DataCell(
          Text(
            '₹${item.pricePerSku.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(Text(item.quantity.toString())),
        DataCell(Text(item.capacity.toString())),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stockColor),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: stockColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== Navigation Methods ==========

  /// Navigate to Profile screen
  /// Reloads shop info when returning to refresh shop name
  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    // Reload shop info when returning from profile
    _loadShopInfo();
  }

  /// Navigate to Orders screen
  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
  }

  /// Navigate to Add Product screen
  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectTypeScreen()),
    );
  }

  /// Show edit dialog for inventory item
  void _showEditDialog(InventoryItem item) {
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    final priceController =
        TextEditingController(text: item.pricePerSku.toString());
    final capacityController =
        TextEditingController(text: item.capacity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per SKU',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newQuantity = int.parse(quantityController.text);
                final newPrice = double.parse(priceController.text);
                final newCapacity = int.parse(capacityController.text);

                await FirebaseFirestore.instance
                    .collection('inventory')
                    .doc(item.id)
                    .update({
                  'quantity': newQuantity,
                  'pricePerSku': newPrice,
                  'capacity': newCapacity,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating item: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
