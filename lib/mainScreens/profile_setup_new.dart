import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:projectz/config/app_theme.dart';
import 'package:projectz/mainScreens/home_screen_new.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressLineController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingPincode = false;
  int _currentStep = 0;
  String _email = "";
  String _phone = "";
  String _sellerName = "";
  double _lat = 0.0;
  double _lng = 0.0;

  // Image state
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profileImageBytes;
  Uint8List? _shopImageBytes;
  String _currentProfileImageUrl = "";
  String _currentShopImageUrl = "";

  final List<String> _stepTitles = [
    'Shop Details',
    'Contact & Images',
    'Location & Address',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shopNameController.dispose();
    _contactController.dispose();
    _addressLineController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        return;
      }

      final userData = await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .get();

      if (userData.exists && mounted) {
        final data = userData.data()!;
        setState(() {
          _email = data["sellerEmail"] ?? "";
          _phone = data["phone"] ?? "";
          _sellerName = data["sellerName"] ?? "";
          _shopNameController.text = data["shopName"] ?? "";
          _contactController.text = data["contactDetails"] ?? data["phone"] ?? "";
          _addressLineController.text = data["addressLine"] ?? "";
          _pincodeController.text = data["pincode"] ?? "";
          _districtController.text = data["district"] ?? "";
          _stateController.text = data["state"] ?? "";
          _cityController.text = data["city"] ?? "";
          _lat = (data["lat"] ?? 0.0).toDouble();
          _lng = (data["lng"] ?? 0.0).toDouble();
          _currentProfileImageUrl = data["sellerAvatarUrl"] ?? "";
          _currentShopImageUrl = data["shopImage"] ?? "";
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocationFromPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() => _isLoadingPincode = true);

    try {
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success' && data[0]['PostOffice'] != null) {
          final postOffice = data[0]['PostOffice'][0];
          setState(() {
            _districtController.text = postOffice['District'] ?? '';
            _stateController.text = postOffice['State'] ?? '';
            _cityController.text = postOffice['Block'] ?? postOffice['Name'] ?? '';
          });
          _showSnackBar('Location auto-filled!', isSuccess: true);
        } else {
          _showSnackBar('Invalid pincode');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to fetch location');
    } finally {
      setState(() => _isLoadingPincode = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          return;
        }
      }

      _showSnackBar('Getting your location...', isSuccess: true);

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });

      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
        ),
        headers: {'User-Agent': 'ProjectZApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        if (address != null) {
          setState(() {
            _pincodeController.text = address['postcode'] ?? '';
            _districtController.text = address['county'] ?? address['city_district'] ?? '';
            _stateController.text = address['state'] ?? '';
            _cityController.text = address['city'] ?? address['town'] ?? address['village'] ?? '';

            List<String> parts = [];
            if (address['road'] != null) parts.add(address['road']);
            if (address['suburb'] != null) parts.add(address['suburb']);
            _addressLineController.text = parts.join(', ');
          });
          _showSnackBar('Location captured!', isSuccess: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error getting location');
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image');
    }
  }

  Future<void> _pickShopImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _shopImageBytes = bytes);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image');
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String prefix) async {
    try {
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final supabaseClient = supabase.Supabase.instance.client;
      
      await supabaseClient.storage.from('user-images').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: supabase.FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      return supabaseClient.storage.from('user-images').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    if (_pincodeController.text.trim().isEmpty ||
        _districtController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty) {
      _showSnackBar('Please complete address details');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('User not authenticated');
        setState(() => _isSaving = false);
        return;
      }

      String? profileImageUrl;
      String? shopImageUrl;

      if (_profileImageBytes != null) {
        profileImageUrl = await _uploadImage(_profileImageBytes!, 'profile');
      }
      if (_shopImageBytes != null) {
        shopImageUrl = await _uploadImage(_shopImageBytes!, 'shop');
      }

      String fullAddress = [
        _addressLineController.text.trim(),
        _cityController.text.trim(),
        _districtController.text.trim(),
        _stateController.text.trim(),
        _pincodeController.text.trim(),
      ].where((s) => s.isNotEmpty).join(', ');

      Map<String, dynamic> updateData = {
        "shopName": _shopNameController.text.trim(),
        "contactDetails": _contactController.text.trim(),
        "address": fullAddress,
        "addressLine": _addressLineController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "district": _districtController.text.trim(),
        "state": _stateController.text.trim(),
        "city": _cityController.text.trim(),
        "lat": _lat,
        "lng": _lng,
        "profileComplete": true,
        "status": "active",
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (profileImageUrl != null) {
        updateData["sellerAvatarUrl"] = profileImageUrl;
      }
      if (shopImageUrl != null) {
        updateData["shopImage"] = shopImageUrl;
      }

      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .update(updateData);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("shopName", _shopNameController.text.trim());
      if (profileImageUrl != null) {
        await prefs.setString("sellerAvatarUrl", profileImageUrl);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showSnackBar('Error saving profile');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildStepIndicator(),
        Expanded(
          child: Form(
            key: _formKey,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStep1ShopDetails(),
                _buildStep2ContactImages(),
                _buildStep3Location(),
              ],
            ),
          ),
        ),
        _buildBottomNav(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Profile',
                      style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Step ${_currentStep + 1} of 3 • ${_stepTitles[_currentStep]}',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1ShopDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Shop Information', 'Tell us about your business'),
          const SizedBox(height: 24),
          
          _buildTextField(
            label: 'Shop Name',
            controller: _shopNameController,
            hint: 'Enter your shop name',
            icon: Icons.store_rounded,
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          
          // User Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, 'Owner', _sellerName),
                if (_email.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildInfoRow(Icons.email_outlined, 'Email', _email),
                ],
                if (_phone.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildInfoRow(Icons.phone_outlined, 'Phone', _phone),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2ContactImages() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Contact & Images', 'Add photos and contact info'),
          const SizedBox(height: 24),
          
          _buildTextField(
            label: 'Contact Details',
            controller: _contactController,
            hint: 'Phone or alternate contact',
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 28),
          
          // Profile Image
          Text(
            'Profile Picture',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildImagePicker(
            imageBytes: _profileImageBytes,
            currentUrl: _currentProfileImageUrl,
            onTap: _pickProfileImage,
            icon: Icons.person,
            label: 'Tap to add photo',
          ),
          const SizedBox(height: 24),
          
          // Shop Image
          Text(
            'Shop Photo',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildImagePicker(
            imageBytes: _shopImageBytes,
            currentUrl: _currentShopImageUrl,
            onTap: _pickShopImage,
            icon: Icons.storefront_rounded,
            label: 'Tap to add shop photo',
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Location & Address', 'Where is your shop located?'),
          const SizedBox(height: 24),
          
          // Get Location Button
          InkWell(
            onTap: _getCurrentLocation,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Current Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Auto-fill address from GPS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Pincode',
                  controller: _pincodeController,
                  hint: '6 digits',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (v) {
                    if (v.length == 6) _fetchLocationFromPincode(v);
                  },
                  suffix: _isLoadingPincode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'City',
                  controller: _cityController,
                  hint: 'City/Town',
                  icon: Icons.location_city_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'District',
                  controller: _districtController,
                  hint: 'District',
                  icon: Icons.map_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'State',
                  controller: _stateController,
                  hint: 'State',
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            label: 'Address Line',
            controller: _addressLineController,
            hint: 'Street, Building, Landmark',
            icon: Icons.home_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, size: 20, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Back',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 2 ? 'Complete Setup' : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 2 ? Icons.check : Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTheme.bodyMedium),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            suffixIcon: suffix,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: AppTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required Uint8List? imageBytes,
    required String currentUrl,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool isWide = false,
  }) {
    final hasImage = imageBytes != null || currentUrl.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? double.infinity : 120,
        height: isWide ? 160 : 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppTheme.primaryColor : AppTheme.borderColor,
            width: hasImage ? 2 : 1,
          ),
          boxShadow: AppTheme.cardShadow,
          image: imageBytes != null
              ? DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover)
              : currentUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(currentUrl), fit: BoxFit.cover)
                  : null,
        ),
        child: !hasImage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
