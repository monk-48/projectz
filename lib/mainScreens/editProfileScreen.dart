import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:projectz/widgets/customTextField.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Edit Profile Screen
/// Allows users to update shop details and login credentials
/// Following Clean Code and Single Responsibility Principle
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
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
          _shopNameController.text =
              data["shopName"] ?? data["sellerName"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          _addressController.text = data["address"] ?? "";
          _emailController.text = currentUser.email ?? "";
          _currentEmail = currentUser.email ?? "";
          _currentShopImageUrl =
              data["shopImage"] ?? data["sellerAvatarUrl"] ?? "";
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
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
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
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
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
    if (_newShopImage == null || _shopImageBytes == null) {
      return null;
    }

    try {
      // Generate unique filename
      final fileName = 'shop_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = _newShopImage!.name.split('.').last;
      final fullFileName = '$fileName.$fileExtension';

      // Upload to Supabase
      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.storage.from('user-images').uploadBinary(
            fullFileName,
            _shopImageBytes!,
            fileOptions: supabase.FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );

      // Get public URL
      final String imageUrl =
          supabaseClient.storage.from('user-images').getPublicUrl(fullFileName);

      return imageUrl;
    } catch (e) {
      debugPrint("Error uploading shop image: $e");
      _showErrorMessage("Failed to upload shop image");
      return null;
    }
  }

  /// Upload profile image to Supabase Storage
  Future<String?> _uploadProfileImage() async {
    if (_newProfileImage == null || _profileImageBytes == null) {
      return null;
    }

    try {
      // Generate unique filename
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = _newProfileImage!.name.split('.').last;
      final fullFileName = '$fileName.$fileExtension';

      // Upload to Supabase
      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.storage.from('user-images').uploadBinary(
            fullFileName,
            _profileImageBytes!,
            fileOptions: supabase.FileOptions(
              contentType: 'image/$fileExtension',
              upsert: true,
            ),
          );

      // Get public URL
      final String imageUrl =
          supabaseClient.storage.from('user-images').getPublicUrl(fullFileName);

      return imageUrl;
    } catch (e) {
      debugPrint("Error uploading profile image: $e");
      _showErrorMessage("Failed to upload profile image");
      return null;
    }
  }

  /// Validate and save all changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorMessage("User not authenticated");
        return;
      }

      // Upload new shop image if selected
      String? newShopImageUrl;
      if (_newShopImage != null) {
        newShopImageUrl = await _uploadShopImage();
        if (newShopImageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      // Upload new profile image if selected
      String? newProfileImageUrl;
      if (_newProfileImage != null) {
        newProfileImageUrl = await _uploadProfileImage();
        if (newProfileImageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      // Prepare updated data
      final updatedData = <String, dynamic>{
        'shopName': _shopNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (newShopImageUrl != null) {
        updatedData['shopImage'] = newShopImageUrl;
      }

      if (newProfileImageUrl != null) {
        updatedData['sellerAvatarUrl'] = newProfileImageUrl;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .update(updatedData);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shopName', _shopNameController.text.trim());
      await prefs.setString('phone', _phoneController.text.trim());
      await prefs.setString('address', _addressController.text.trim());
      if (newShopImageUrl != null) {
        await prefs.setString('shopImage', newShopImageUrl);
      }
      if (newProfileImageUrl != null) {
        await prefs.setString('sellerAvatarUrl', newProfileImageUrl);
      }

      // Update email if changed
      if (_emailController.text.trim() != _currentEmail &&
          _currentPasswordController.text.isNotEmpty) {
        await _updateEmail();
      }

      // Update password if provided
      if (_newPasswordController.text.isNotEmpty &&
          _currentPasswordController.text.isNotEmpty) {
        await _updatePassword();
      }

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessMessage("Profile updated successfully");
        Navigator.pop(
            context, true); // Return true to indicate changes were saved
      }
    } catch (e) {
      debugPrint("Error saving changes: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorMessage("Failed to save changes: ${e.toString()}");
      }
    }
  }

  /// Update user email
  Future<void> _updateEmail() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Re-authenticate before email change
      final credential = EmailAuthProvider.credential(
        email: _currentEmail,
        password: _currentPasswordController.text,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update email using verifyBeforeUpdateEmail (Firebase v10+)
      await currentUser.verifyBeforeUpdateEmail(_emailController.text.trim());

      // Update Firestore
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

  /// Update user password
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

      // Re-authenticate before password change
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update password
      await currentUser.updatePassword(_newPasswordController.text);

      _showSuccessMessage("Password updated successfully");
    } catch (e) {
      debugPrint("Error updating password: $e");
      _showErrorMessage("Failed to update password: ${e.toString()}");
      rethrow;
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Get shop image provider for display
  ImageProvider? _getShopImageProvider() {
    if (_newShopImage != null && _shopImageBytes != null) {
      return MemoryImage(_shopImageBytes!);
    } else if (_currentShopImageUrl.isNotEmpty) {
      return NetworkImage(_currentShopImageUrl);
    }
    return null;
  }

  /// Get profile image provider for display
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
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildEditForm(),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Edit Profile',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.purple,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Build edit form
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

  /// Profile image section
  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Profile Picture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _getProfileImageProvider(),
              child: _getProfileImageProvider() == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey.shade400,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Profile Picture'),
          ),
        ],
      ),
    );
  }

  /// Shop image section
  Widget _buildShopImageSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Shop Image',
            style: TextStyle(
              fontSize: 18,
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
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: _getShopImageProvider() != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image(
                        image: _getShopImageProvider()!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickShopImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Shop Image'),
          ),
        ],
      ),
    );
  }

  /// Shop details section
  Widget _buildShopDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _shopNameController,
          data: Icons.store,
          hintText: 'Shop Name',
          isObsecure: false,
        ),
        CustomTextField(
          controller: _phoneController,
          data: Icons.phone,
          hintText: 'Contact Number',
          isObsecure: false,
        ),
        CustomTextField(
          controller: _addressController,
          data: Icons.location_on,
          hintText: 'Shop Address',
          isObsecure: false,
        ),
      ],
    );
  }

  /// Login credentials section
  Widget _buildLoginCredentialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Login Credentials',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showPasswordSection = !_showPasswordSection;
                });
              },
              child: Text(
                _showPasswordSection ? 'Hide' : 'Change Password',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          data: Icons.email,
          hintText: 'Email',
          isObsecure: false,
        ),
        if (_showPasswordSection) ...[
          const SizedBox(height: 16),
          const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _currentPasswordController,
            data: Icons.lock,
            hintText: 'Current Password (required for changes)',
            isObsecure: true,
          ),
          CustomTextField(
            controller: _newPasswordController,
            data: Icons.lock_outline,
            hintText: 'New Password',
            isObsecure: true,
          ),
          CustomTextField(
            controller: _confirmPasswordController,
            data: Icons.lock_outline,
            hintText: 'Confirm New Password',
            isObsecure: true,
          ),
        ],
      ],
    );
  }
}
