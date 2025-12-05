import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectz/config/app_theme.dart';

/// Edit Profile Screen
/// Allows users to update shop details and login credentials
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Form controllers for shop details
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentShopImageUrl = "";
  String _currentProfileImageUrl = "";
  String _currentEmail = "";
  XFile? _newShopImage;
  Uint8List? _shopImageBytes;
  XFile? _newProfileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Section visibility flags
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Load existing user data from Firestore
  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorMessage("User not authenticated");
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
          _shopNameController.text = data["shopName"] ?? data["sellerName"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          _addressController.text = data["address"] ?? "";
          _emailController.text = currentUser.email ?? "";
          _currentEmail = currentUser.email ?? "";
          _currentShopImageUrl = data["shopImage"] ?? data["sellerAvatarUrl"] ?? "";
          _currentProfileImageUrl = data["sellerAvatarUrl"] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage("Failed to load profile data");
      }
    }
  }

  /// Pick shop image from gallery
  Future<void> _pickShopImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newShopImage = pickedFile;
          _shopImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      _showErrorMessage("Failed to pick image");
    }
  }

  /// Pick profile image from gallery
  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newProfileImage = pickedFile;
          _profileImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      _showErrorMessage("Failed to pick image");
    }
  }

  /// Upload shop image to Supabase Storage
  Future<String?> _uploadShopImage() async {
    if (_newShopImage == null || _shopImageBytes == null) return null;

    try {
      final fileName = 'shop_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = _newShopImage!.name.split('.').last;
      final fullFileName = '$fileName.$fileExtension';

      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.storage.from('user-images').uploadBinary(
            fullFileName,
            _shopImageBytes!,
            fileOptions: supabase.FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );

      return supabaseClient.storage.from('user-images').getPublicUrl(fullFileName);
    } catch (e) {
      debugPrint("Error uploading shop image: $e");
      _showErrorMessage("Failed to upload shop image");
      return null;
    }
  }

  /// Upload profile image to Supabase Storage
  Future<String?> _uploadProfileImage() async {
    if (_newProfileImage == null || _profileImageBytes == null) return null;

    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = _newProfileImage!.name.split('.').last;
      final fullFileName = '$fileName.$fileExtension';

      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.storage.from('user-images').uploadBinary(
            fullFileName,
            _profileImageBytes!,
            fileOptions: supabase.FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );

      return supabaseClient.storage.from('user-images').getPublicUrl(fullFileName);
    } catch (e) {
      debugPrint("Error uploading profile image: $e");
      _showErrorMessage("Failed to upload profile image");
      return null;
    }
  }

  /// Validate and save all changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorMessage("User not authenticated");
        return;
      }

      String? newShopImageUrl;
      if (_newShopImage != null) {
        newShopImageUrl = await _uploadShopImage();
        if (newShopImageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      String? newProfileImageUrl;
      if (_newProfileImage != null) {
        newProfileImageUrl = await _uploadProfileImage();
        if (newProfileImageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final updatedData = <String, dynamic>{
        'shopName': _shopNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (newShopImageUrl != null) updatedData['shopImage'] = newShopImageUrl;
      if (newProfileImageUrl != null) updatedData['sellerAvatarUrl'] = newProfileImageUrl;

      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .update(updatedData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shopName', _shopNameController.text.trim());
      await prefs.setString('phone', _phoneController.text.trim());
      await prefs.setString('address', _addressController.text.trim());
      if (newShopImageUrl != null) await prefs.setString('shopImage', newShopImageUrl);
      if (newProfileImageUrl != null) await prefs.setString('sellerAvatarUrl', newProfileImageUrl);

      if (_emailController.text.trim() != _currentEmail && _currentPasswordController.text.isNotEmpty) {
        await _updateEmail();
      }

      if (_newPasswordController.text.isNotEmpty && _currentPasswordController.text.isNotEmpty) {
        await _updatePassword();
      }

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessMessage("Profile updated successfully");
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving changes: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorMessage("Failed to save changes: ${e.toString()}");
      }
    }
  }

  Future<void> _updateEmail() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final credential = EmailAuthProvider.credential(
        email: _currentEmail,
        password: _currentPasswordController.text,
      );
      await currentUser.reauthenticateWithCredential(credential);
      await currentUser.verifyBeforeUpdateEmail(_emailController.text.trim());

      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .update({'sellerEmail': _emailController.text.trim()});

      _showSuccessMessage("Email verification sent. Please check your inbox.");
    } catch (e) {
      debugPrint("Error updating email: $e");
      _showErrorMessage("Failed to update email: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorMessage("New passwords do not match");
      throw Exception("Passwords do not match");
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorMessage("Password must be at least 6 characters");
      throw Exception("Password too short");
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );
      await currentUser.reauthenticateWithCredential(credential);
      await currentUser.updatePassword(_newPasswordController.text);

      _showSuccessMessage("Password updated successfully");
    } catch (e) {
      debugPrint("Error updating password: $e");
      _showErrorMessage("Failed to update password: ${e.toString()}");
      rethrow;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  ImageProvider? _getShopImageProvider() {
    if (_newShopImage != null && _shopImageBytes != null) {
      return MemoryImage(_shopImageBytes!);
    } else if (_currentShopImageUrl.isNotEmpty) {
      return NetworkImage(_currentShopImageUrl);
    }
    return null;
  }

  ImageProvider? _getProfileImageProvider() {
    if (_newProfileImage != null && _profileImageBytes != null) {
      return MemoryImage(_profileImageBytes!);
    } else if (_currentProfileImageUrl.isNotEmpty) {
      return NetworkImage(_currentProfileImageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildEditForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Edit Profile',
        style: AppTheme.titleLarge.copyWith(color: Colors.white),
      ),
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: AppTheme.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImageSection(),
            const SizedBox(height: 32),
            _buildShopImageSection(),
            const SizedBox(height: 32),
            _buildShopDetailsSection(),
            const SizedBox(height: 32),
            _buildLoginCredentialsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Profile Picture',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.backgroundColor,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: _getProfileImageProvider() != null
                    ? Image(image: _getProfileImageProvider()!, fit: BoxFit.cover, width: 120, height: 120)
                    : Icon(Icons.person, size: 50, color: AppTheme.textHint),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
            label: Text(
              'Change Profile Picture',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'Shop Image',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickShopImage,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
                boxShadow: AppTheme.cardShadow,
              ),
              child: _getShopImageProvider() != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image(image: _getShopImageProvider()!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 50, color: AppTheme.textHint),
                        const SizedBox(height: 8),
                        Text('Tap to upload', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickShopImage,
            icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
            label: Text(
              'Change Shop Image',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopDetailsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Shop Details',
                style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(controller: _shopNameController, label: 'Shop Name', icon: Icons.store_outlined),
          const SizedBox(height: 16),
          _buildTextField(controller: _phoneController, label: 'Contact Number', icon: Icons.phone_outlined),
          const SizedBox(height: 16),
          _buildTextField(controller: _addressController, label: 'Shop Address', icon: Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildLoginCredentialsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock_outline, color: AppTheme.warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Login Credentials',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _showPasswordSection = !_showPasswordSection),
                child: Text(
                  _showPasswordSection ? 'Hide' : 'Change Password',
                  style: AppTheme.labelLarge.copyWith(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined),
          if (_showPasswordSection) ...[
            const SizedBox(height: 24),
            Divider(color: AppTheme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'Change Password',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildTextField(controller: _currentPasswordController, label: 'Current Password', icon: Icons.lock, isPassword: true),
            const SizedBox(height: 16),
            _buildTextField(controller: _newPasswordController, label: 'New Password', icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 16),
            _buildTextField(controller: _confirmPasswordController, label: 'Confirm New Password', icon: Icons.lock_outline, isPassword: true),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error),
        ),
      ),
      validator: (value) {
        if (!isPassword && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
