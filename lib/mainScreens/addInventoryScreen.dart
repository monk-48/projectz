import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projectz/core/constants/app_colors.dart';
import 'package:projectz/core/constants/app_strings.dart';
import 'package:projectz/core/utils/validators.dart';
import 'package:projectz/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:projectz/models/inventory_item.dart';

class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({super.key});

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _brandController;
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _capacityController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
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

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final provider = context.read<InventoryProvider>();

    // Create InventoryItem instance
    final item = InventoryItem(
      id: '', // Firestore will generate the ID
      brand: _brandController.text.trim(),
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      seller: currentUser.uid,
      capacity: int.parse(_capacityController.text),
      quantity: int.parse(_quantityController.text),
    );

    final success = await provider.addInventoryItem(item);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.itemAddedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? AppStrings.unknownError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addInventoryItem, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    const Text(
                      AppStrings.itemDetails,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand Field
                    _buildTextField(
                      controller: _brandController,
                      label: AppStrings.brand,
                      hint: 'e.g., Bosch, DeWalt, Stanley',
                      validator: (value) => Validators.required(value, fieldName: 'brand'),
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),

                    // Product Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: AppStrings.productName,
                      hint: 'e.g., Power Drill, Concrete Mixer',
                      validator: (value) => Validators.required(value, fieldName: 'product name'),
                      maxLines: 2,
                      icon: Icons.note,
                    ),
                    const SizedBox(height: 16),

                    // SKU Field
                    _buildTextField(
                      controller: _skuController,
                      label: AppStrings.sku,
                      hint: 'e.g., SKU-2024-001',
                      validator: (value) => Validators.required(value, fieldName: 'SKU'),
                      icon: Icons.qr_code_2,
                    ),
                    const SizedBox(height: 16),

                    // Capacity Field
                    _buildTextField(
                      controller: _capacityController,
                      label: AppStrings.capacity,
                      hint: 'Total capacity',
                      validator: (value) => Validators.positiveNumber(value, fieldName: 'capacity'),
                      keyboardType: TextInputType.number,
                      icon: Icons.storage,
                    ),
                    const SizedBox(height: 16),

                    // Quantity Field
                    _buildTextField(
                      controller: _quantityController,
                      label: AppStrings.quantity,
                      hint: 'Current stock quantity',
                      validator: (value) {
                        final numberError = Validators.positiveNumber(value, fieldName: 'quantity');
                        if (numberError != null) return numberError;
                        
                        final quantity = int.tryParse(value ?? '');
                        final capacity = int.tryParse(_capacityController.text);
                        if (quantity != null && capacity != null && quantity > capacity) {
                          return 'Quantity cannot exceed capacity';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      icon: Icons.inventory_2,
                    ),
                    const SizedBox(height: 30),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: AppColors.info),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Tips',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '• SKU should be unique per item\n• Quantity cannot exceed capacity\n• All fields are required',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
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
                        onPressed: provider.isLoading ? null : _addInventoryItem,
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(provider.isLoading ? 'Adding...' : AppStrings.add),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                        onPressed: provider.isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
