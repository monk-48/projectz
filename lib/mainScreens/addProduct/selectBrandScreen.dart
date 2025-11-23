import 'package:flutter/material.dart';
import 'package:projectz/mainScreens/addProduct/productDetailsScreen.dart';

/// Step 2: Select Brand
/// User selects the brand from a dropdown
class SelectBrandScreen extends StatefulWidget {
  final String productType;
  final List<String> brands;
  final String skuUnit;

  const SelectBrandScreen({
    Key? key,
    required this.productType,
    required this.brands,
    required this.skuUnit,
  }) : super(key: key);

  @override
  State<SelectBrandScreen> createState() => _SelectBrandScreenState();
}

class _SelectBrandScreenState extends State<SelectBrandScreen> {
  String? _selectedBrand;

  void _proceedToNextStep() {
    if (_selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand')),
      );
      return;
    }

    // Navigate to product details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          productType: widget.productType,
          brandName: _selectedBrand!,
          skuUnit: widget.skuUnit,
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 40),
            // Selected type info
            _buildSelectedTypeInfo(),
            const SizedBox(height: 30),
            // Title
            const Text(
              'Step 2: Select Brand',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose the brand for your ${widget.productType}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            // Dropdown
            _buildBrandDropdown(),
            const Spacer(),
            // Next button
            _buildNextButton(),
            const SizedBox(height: 20),
          ],
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
        _buildStepCircle(2, true, false),
        _buildStepLine(false),
        _buildStepCircle(3, false, false),
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
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
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
        color: isActive ? Colors.purple : Colors.grey.shade300,
      ),
    );
  }

  /// Selected type info
  Widget _buildSelectedTypeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Type',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.productType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Brand dropdown
  Widget _buildBrandDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrand,
          hint: const Text(
            'Select Brand',
            style: TextStyle(fontSize: 16),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
          items: widget.brands.map((brand) {
            return DropdownMenuItem<String>(
              value: brand,
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.purple, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      brand,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBrand = value;
            });
          },
        ),
      ),
    );
  }

  /// Next button
  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _proceedToNextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
