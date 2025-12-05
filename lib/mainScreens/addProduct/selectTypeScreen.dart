import 'package:flutter/material.dart';
import 'package:projectz/config/app_theme.dart';
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
        SnackBar(
          content: const Text('Please select a product type'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Product',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildStepIndicator(),
            const SizedBox(height: 40),
            Text(
              'Step 1: Select Product Type',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose the type of product you want to add',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            _buildTypeDropdown(),
            const Spacer(),
            _buildNextButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
        color: isActive ? AppTheme.primaryColor : AppTheme.dividerColor,
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        hint: Text(
          'Select Product Type',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
        ),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        items: _productTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _getTypeIcon(type),
                ),
                const SizedBox(width: 12),
                Text(
                  type,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
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
    );
  }

  Widget _getTypeIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'Cement':
        iconData = Icons.construction;
        break;
      case 'Paint':
        iconData = Icons.palette;
        break;
      case 'Brick':
        iconData = Icons.square_rounded;
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
    return Icon(iconData, color: AppTheme.primaryColor, size: 20);
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.buttonShadow,
      ),
      child: ElevatedButton(
        onPressed: _proceedToNextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
