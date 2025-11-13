// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectz/core/constants/app_colors.dart';
import 'package:projectz/core/constants/app_strings.dart';
import 'package:projectz/core/utils/validators.dart';
import 'package:projectz/core/di/service_locator.dart';
import 'package:projectz/features/auth/presentation/providers/auth_provider.dart';
import 'package:projectz/global/global.dart';
import 'package:projectz/widgets/customTextField.dart';
import 'package:http/http.dart' as http;
import 'package:projectz/mainScreens/homeScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Position? _sellerCurrentPosition;
  XFile? _imageXFile;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  Future<String?> _getAddressFromCoordinatesWeb(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterSellerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        String formattedAddress = '';
        
        if (address != null) {
          List<String> addressParts = [];
          if (address['road'] != null) addressParts.add(address['road']);
          if (address['suburb'] != null) addressParts.add(address['suburb']);
          if (address['city'] != null) addressParts.add(address['city']);
          if (address['state'] != null) addressParts.add(address['state']);
          if (address['postcode'] != null) addressParts.add(address['postcode']);
          if (address['country'] != null) addressParts.add(address['country']);
          formattedAddress = addressParts.join(', ');
        }
        
        return formattedAddress.isNotEmpty ? formattedAddress : data['display_name'];
      }
    } catch (e) {
      debugPrint('Error getting address from API: $e');
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageXFile == null) {
      _showErrorDialog(AppStrings.imageRequired);
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // Step 1: Upload image
    String? imageUrl;
    try {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        _showErrorDialog('Failed to upload image');
        return;
      }
    } catch (e) {
      _showErrorDialog('Error uploading image: $e');
      return;
    }

    // Step 2: Sign up user
    final signUpSuccess = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!signUpSuccess) {
      _showErrorDialog(authProvider.errorMessage ?? AppStrings.unknownError);
      return;
    }

    // Step 3: Create seller profile
    final profileData = {
      "sellerUID": authProvider.currentUser!.uid,
      "sellerEmail": authProvider.currentUser!.email,
      "sellerName": _nameController.text.trim(),
      "sellerAvatarUrl": imageUrl,
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "status": "approved",
      "earnings": 0.0,
      "lat": _sellerCurrentPosition?.latitude ?? 0.0,
      "lng": _sellerCurrentPosition?.longitude ?? 0.0,
    };

    final profileSuccess = await authProvider.createSellerProfile(profileData);

    if (mounted) {
      if (profileSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showErrorDialog(authProvider.errorMessage ?? AppStrings.unknownError);
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageXFile == null || _imageBytes == null) {
      return null;
    }

    try {
      final storageService = ServiceLocator().storageRemoteDataSource;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${_imageXFile!.name.split('.').last}';
      final imageUrl = await storageService.uploadImage(
        _imageBytes!,
        fileName,
        'user-images',
      );
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _sellerCurrentPosition = position;
      });

      if (kIsWeb) {
        _addressController.text = 'Loading address...';
        final address = await _getAddressFromCoordinatesWeb(
          position.latitude,
          position.longitude,
        );
        
        if (mounted) {
          if (address != null && address.isNotEmpty) {
            setState(() {
              _addressController.text = address;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location captured successfully!')),
            );
          } else {
            final webAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
            setState(() {
              _addressController.text = webAddress;
            });
          }
        }
      } else {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final placemark = placemarks[0];
          final address = '${placemark.subLocality} ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _getImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageXFile = image;
      });
      _imageBytes = await image.readAsBytes();
    }
  }

  ImageProvider? _getImageProvider() {
    if (_imageXFile == null) return null;
    
    if (kIsWeb) {
      return _imageBytes != null ? MemoryImage(_imageBytes!) : null;
    } else {
      try {
        return FileImage(File(_imageXFile!.path));
      } catch (e) {
        return _imageBytes != null ? MemoryImage(_imageBytes!) : null;
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.error),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SingleChildScrollView(
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 10),
                InkWell(
                  onTap: _getImage,
                  child: CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.20,
                    backgroundColor: Colors.white,
                    backgroundImage: _getImageProvider(),
                    child: _imageXFile == null
                        ? Icon(
                            Icons.add_photo_alternate,
                            size: MediaQuery.of(context).size.width * 0.20,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        data: Icons.person,
                        hintText: AppStrings.name,
                        isObsecure: false,
                      ),
                      CustomTextField(
                        controller: _emailController,
                        data: Icons.email,
                        hintText: AppStrings.email,
                        isObsecure: false,
                      ),
                      CustomTextField(
                        controller: _passwordController,
                        data: Icons.lock,
                        hintText: AppStrings.password,
                      ),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        data: Icons.lock,
                        hintText: AppStrings.confirmPassword,
                      ),
                      CustomTextField(
                        controller: _phoneController,
                        data: Icons.phone,
                        hintText: AppStrings.phone,
                        isObsecure: false,
                      ),
                      CustomTextField(
                        controller: _addressController,
                        data: Icons.location_city,
                        hintText: AppStrings.shopAddress,
                        isObsecure: false,
                        enabled: true,
                      ),
                      Container(
                        width: 400,
                        height: 40,
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          label: const Text(
                            AppStrings.getMyLocation,
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                          ),
                          onPressed: _getCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
