import 'package:flutter/material.dart';
import 'package:projectz/mainScreens/addProduct/selectBrandScreen.dart';

/// Step 1: Select Product Type
/// User selects the type of product from a dropdown
class SelectTypeScreen extends StatefulWidget {
  const SelectTypeScreen({Key? key}) : super(key: key);

  @override
  State<SelectTypeScreen> createState() => _SelectTypeScreenState();
}

class _SelectTypeScreenState extends State<SelectTypeScreen> {
  String? _selectedType;

  // Product types available
  final List<String> _productTypes = [
    'Cement',
    'Paint',
    'Brick',
    'Tiles/Marbles',
    'Iron Rod',
  ];

  // Brand names for each product type
  final Map<String, List<String>> _brandsByType = {
    'Cement': [
      'UltraTech Cement',
      'ACC Cement',
      'Ambuja Cement',
      'Shree Cement',
      'Dalmia Cement',
    ],
    'Paint': [
      'Asian Paints',
      'Berger Paints',
      'Nerolac',
      'Dulux',
      'Kansai Nerolac',
    ],
    'Brick': [
      'Wienerberger',
      'Porotherm',
      'Brickworks',
      'Supreme Bricks',
      'Magicrete',
    ],
    'Tiles/Marbles': [
      'Kajaria',
      'Somany',
      'Nitco',
      'Johnson Tiles',
      'RAK Ceramics',
    ],
    'Iron Rod': [
      'TATA Steel',
      'JSW Steel',
      'SAIL',
      'Jindal Steel',
      'Vizag Steel',
    ],
  };

  // SKU units for each product type
  final Map<String, String> _skuUnitByType = {
    'Cement': 'bags',
    'Paint': 'liters',
    'Brick': 'pieces',
    'Tiles/Marbles': 'sq.ft',
    'Iron Rod': 'kg',
  };

  void _proceedToNextStep() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product type')),
      );
      return;
    }

    // Navigate to brand selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectBrandScreen(
          productType: _selectedType!,
          brands: _brandsByType[_selectedType!]!,
          skuUnit: _skuUnitByType[_selectedType!]!,
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
            // Title
            const Text(
              'Step 1: Select Product Type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose the type of product you want to add',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            // Dropdown
            _buildTypeDropdown(),
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
        _buildStepCircle(1, true),
        _buildStepLine(false),
        _buildStepCircle(2, false),
        _buildStepLine(false),
        _buildStepCircle(3, false),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? Colors.purple : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
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

  /// Type dropdown
  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          hint: const Text(
            'Select Product Type',
            style: TextStyle(fontSize: 16),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
          items: _productTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  _getTypeIcon(type),
                  const SizedBox(width: 12),
                  Text(
                    type,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
          },
        ),
      ),
    );
  }

  /// Get icon for product type
  Widget _getTypeIcon(String type) {
    IconData iconData;
    Color iconColor = Colors.purple;

    switch (type) {
      case 'Cement':
        iconData = Icons.construction;
        break;
      case 'Paint':
        iconData = Icons.palette;
        break;
      case 'Brick':
        iconData = Icons.square;
        break;
      case 'Tiles/Marbles':
        iconData = Icons.grid_on;
        break;
      case 'Iron Rod':
        iconData = Icons.settings_input_component;
        break;
      default:
        iconData = Icons.category;
    }

    return Icon(iconData, color: iconColor, size: 24);
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
