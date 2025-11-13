import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({Key? key}) : super(key: key);

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form field controllers
  late TextEditingController _brandController;
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _capacityController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;

    _brandController = TextEditingController();
    _nameController = TextEditingController();
    _skuController = TextEditingController();
    _capacityController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _capacityController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addInventoryItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add to Firestore
      await _firestore.collection('inventory').add({
        'brand': _brandController.text.trim(),
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'seller': currentUser.uid,
        'capacity': int.parse(_capacityController.text),
        'quantity': int.parse(_quantityController.text),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorMessage,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        prefixIcon: label.contains('Brand')
            ? const Icon(Icons.business, color: Colors.purple)
            : label.contains('SKU')
                ? const Icon(Icons.qr_code_2, color: Colors.purple)
                : label.contains('Capacity')
                    ? const Icon(Icons.storage, color: Colors.purple)
                    : label.contains('Quantity')
                        ? const Icon(Icons.inventory_2, color: Colors.purple)
                        : const Icon(Icons.note, color: Colors.purple),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorMessage;
        }
        if (keyboardType == TextInputType.number) {
          if (int.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Inventory Item', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                const Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Brand Field
                _buildTextField(
                  controller: _brandController,
                  label: 'Brand',
                  hint: 'e.g., Bosch, DeWalt, Stanley',
                  errorMessage: 'Please enter a brand name',
                ),
                const SizedBox(height: 16),

                // Product Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Product Name',
                  hint: 'e.g., Power Drill, Concrete Mixer',
                  errorMessage: 'Please enter a product name',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // SKU Field
                _buildTextField(
                  controller: _skuController,
                  label: 'SKU',
                  hint: 'e.g., SKU-2024-001',
                  errorMessage: 'Please enter a SKU',
                ),
                const SizedBox(height: 16),

                // Capacity Field
                _buildTextField(
                  controller: _capacityController,
                  label: 'Capacity',
                  hint: 'Total capacity',
                  errorMessage: 'Please enter capacity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Quantity Field
                _buildTextField(
                  controller: _quantityController,
                  label: 'Current Quantity',
                  hint: 'Current stock quantity',
                  errorMessage: 'Please enter quantity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 30),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade600),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• SKU should be unique per item\n• Quantity cannot exceed capacity\n• All fields are required',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _addInventoryItem,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isLoading ? 'Adding...' : 'Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
