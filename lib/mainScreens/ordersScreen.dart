import 'package:flutter/material.dart';

/// Orders screen displays all orders with basic structure
/// Following Single Responsibility Principle - handles only order display
/// Extensible design allows easy addition of order properties and features
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = false;
  // Order data will be fetched here
  final List<OrderItem> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  /// Loads orders from backend
  /// Placeholder for future implementation
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement order fetching from Firestore/Supabase
      // For now, using empty list
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading orders: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage("Failed to load orders");
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildOrdersContent(),
    );
  }

  /// Builds app bar with refresh action
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Orders',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.purple,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadOrders,
        ),
      ],
    );
  }

  /// Loading indicator
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Main orders content
  Widget _buildOrdersContent() {
    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return _buildOrdersList();
  }

  /// Empty state when no orders exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Orders will appear here once customers place them',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Orders list view
  Widget _buildOrdersList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  /// Individual order card
  /// Designed to be easily extensible with more order properties
  Widget _buildOrderCard(OrderItem order) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleOrderTap(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 12),
              _buildOrderInfoRow(
                Icons.calendar_today,
                'Date',
                order.formattedDate,
              ),
              const SizedBox(height: 8),
              _buildOrderInfoRow(
                Icons.attach_money,
                'Total',
                '\$${order.total.toStringAsFixed(2)}',
              ),
              // More order properties can be added here
            ],
          ),
        ),
      ),
    );
  }

  /// Status badge widget
  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        label = 'Processing';
        break;
      case OrderStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Order info row
  Widget _buildOrderInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Handles order tap - navigate to order details
  void _handleOrderTap(OrderItem order) {
    // TODO: Navigate to order details screen
    _showErrorMessage('Order details feature coming soon');
  }
}

// ============================================================================
// Data Models - Following Clean Architecture principles
// Separated from UI logic for better maintainability
// ============================================================================

/// Order status enum
/// Easily extensible with more statuses
enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled,
}

/// Basic Order Item model
/// Designed to be easily extended with more properties
class OrderItem {
  final String id;
  final DateTime date;
  final double total;
  final OrderStatus status;
  // Additional properties can be added here:
  // final String customerName;
  // final String customerEmail;
  // final List<OrderLineItem> items;
  // final String shippingAddress;
  // final String paymentMethod;

  OrderItem({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
  });

  /// Formatted date string
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Factory method for creating from Firestore document
  /// TODO: Implement based on your database structure
  factory OrderItem.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderItem(
      id: id,
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      total: (data['total'] ?? 0.0).toDouble(),
      status: _parseStatus(data['status'] ?? 'pending'),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'date': date.toIso8601String(),
      'total': total,
      'status': status.name,
    };
  }

  /// Helper method to parse status from string
  static OrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// Copy with method for immutability
  OrderItem copyWith({
    String? id,
    DateTime? date,
    double? total,
    OrderStatus? status,
  }) {
    return OrderItem(
      id: id ?? this.id,
      date: date ?? this.date,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }
}
