import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Step 3: Product Details
/// User enters product name, photo, price per SKU, SKU value, and quantity
class ProductDetailsScreen extends StatefulWidget {
  final String productType;
  final String brandName;
  final String skuUnit;

  const ProductDetailsScreen({
    Key? key,
    required this.productType,
    required this.brandName,
    required this.skuUnit,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  XFile? _productImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Pick product image
  Future<void> _pickProductImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _productImage = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      _showMessage("Failed to pick image", isError: true);
    }
  }

  /// Upload product image to Supabase
  Future<String?> _uploadProductImage() async {
    if (_productImage == null || _imageBytes == null) {
      return null;
    }

    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = _productImage!.name.split('.').last;
      final fullFileName = '$fileName.$fileExtension';

      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.storage.from('user-images').uploadBinary(
            fullFileName,
            _imageBytes!,
            fileOptions: supabase.FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );

      final String imageUrl =
          supabaseClient.storage.from('user-images').getPublicUrl(fullFileName);

      return imageUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      _showMessage("Failed to upload image", isError: true);
      return null;
    }
  }

  /// Save product to Firestore
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog if no image is selected
    if (_productImage == null) {
      final shouldContinue = await _showNoImageConfirmation();
      if (!shouldContinue) {
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage("User not authenticated", isError: true);
        setState(() => _isSaving = false);
        return;
      }

      // Upload product image (will be null if no image selected)
      final imageUrl = await _uploadProductImage();

      // Calculate capacity (you can modify this logic)
      final quantity = int.parse(_quantityController.text);
      final capacity = (quantity * 1.5).round(); // 50% buffer capacity

      // Save to Firestore
      await FirebaseFirestore.instance.collection('inventory').add({
        'productType': widget.productType,
        'brand': widget.brandName,
        'name': _productNameController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'pricePerSku': double.parse(_priceController.text),
        'sku': _skuController.text.trim(),
        'skuUnit': widget.skuUnit,
        'quantity': quantity,
        'capacity': capacity,
        'seller': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage("Product added successfully!", isError: false);
        // Pop all the way back to inventory screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint("Error saving product: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage("Failed to save product: ${e.toString()}", isError: true);
      }
    }
  }

  /// Show confirmation dialog when no image is selected
  Future<bool> _showNoImageConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Product Image'),
        content: const Text(
          'You haven\'t added a product image. Do you want to continue without an image?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text(
              'Continue Without Image',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Step indicator
              _buildStepIndicator(),
              const SizedBox(height: 40),
              // Selected info
              _buildSelectedInfo(),
              const SizedBox(height: 30),
              // Title
              const Text(
                'Step 3: Product Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter product information and photo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              // Product image
              _buildProductImageSection(),
              const SizedBox(height: 30),
              // Product name
              _buildTextField(
                controller: _productNameController,
                label: 'Product Name',
                hint: 'Enter product name',
                icon: Icons.inventory,
              ),
              const SizedBox(height: 20),
              // Price per SKU
              _buildTextField(
                controller: _priceController,
                label: 'Price per ${widget.skuUnit}',
                hint: 'Enter price',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              // SKU value
              _buildTextField(
                controller: _skuController,
                label: 'SKU (${widget.skuUnit})',
                hint: 'e.g., 50 ${widget.skuUnit}',
                icon: Icons.scale,
              ),
              const SizedBox(height: 20),
              // Quantity
              _buildTextField(
                controller: _quantityController,
                label: 'Current Quantity',
                hint: 'Enter available quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),
              // Save button
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Step indicator
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, false, true),
        _buildStepLine(true),
        _buildStepCircle(2, false, true),
        _buildStepLine(true),
        _buildStepCircle(3, true, false),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive, bool isCompleted) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.purple
            : isCompleted
                ? Colors.green
                : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted && !isActive
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive || isCompleted
                      ? Colors.white
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  /// Selected info
  Widget _buildSelectedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Type: ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                widget.productType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Brand: ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                widget.brandName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Product image section
  Widget _buildProductImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProductImage,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickProductImage,
            icon: const Icon(Icons.camera_alt),
            label: Text(_productImage == null ? 'Add Photo' : 'Change Photo'),
          ),
        ],
      ),
    );
  }

  /// Text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.purple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            if (keyboardType == TextInputType.number) {
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
