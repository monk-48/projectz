import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Convert to map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'brand': brand,
      'name': name,
      'sku': sku,
      'seller': seller,
      'capacity': capacity,
      'quantity': quantity,
    };
  }

  // Computed properties
  double get stockPercentage => capacity > 0 ? (quantity / capacity) * 100 : 0;

  bool get isLowStock => quantity < (capacity * 0.2);

  bool get isOutOfStock => quantity == 0;

  // Copy with method for updates
  InventoryItem copyWith({
    String? id,
    String? brand,
    String? name,
    String? sku,
    String? seller,
    int? capacity,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      seller: seller ?? this.seller,
      capacity: capacity ?? this.capacity,
      quantity: quantity ?? this.quantity,
    );
  }
}
