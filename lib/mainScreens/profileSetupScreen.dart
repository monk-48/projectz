import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:projectz/mainScreens/homeScreen.dart';
import 'package:projectz/widgets/loadingDialog.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressLineController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingPincode = false;
  bool _showPasswordSection = false;
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _contactController.dispose();
    _addressLineController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
          _contactController.text =
              data["contactDetails"] ?? data["phone"] ?? "";
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
      debugPrint("Error loading user data: $e");
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
            _cityController.text =
                postOffice['Block'] ?? postOffice['Name'] ?? '';
          });
        } else {
          _showMessage("Invalid pincode", isError: true);
        }
      }
    } catch (e) {
      debugPrint("Error fetching pincode data: $e");
      _showMessage("Failed to fetch location data", isError: true);
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
          _showMessage("Location permission denied", isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage("Location permissions are permanently denied",
            isError: true);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => LoadingDialog(message: "Getting location..."),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });

      // Get address from coordinates using Nominatim
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ProjectZApp/1.0'},
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        if (address != null) {
          setState(() {
            _pincodeController.text = address['postcode'] ?? '';
            _districtController.text =
                address['county'] ?? address['city_district'] ?? '';
            _stateController.text = address['state'] ?? '';
            _cityController.text =
                address['city'] ?? address['town'] ?? address['village'] ?? '';

            // Build address line
            List<String> parts = [];
            if (address['road'] != null) parts.add(address['road']);
            if (address['suburb'] != null) parts.add(address['suburb']);
            if (address['neighbourhood'] != null)
              parts.add(address['neighbourhood']);
            _addressLineController.text = parts.join(', ');
          });

          _showMessage("Location captured successfully!", isError: false);
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint("Error getting location: $e");
      _showMessage("Error getting location", isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage("Please fill all password fields", isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showMessage("New password must be at least 6 characters", isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage("New passwords do not match", isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordSection = false);

      _showMessage("Password updated successfully!", isError: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showMessage("Current password is incorrect", isError: true);
      } else {
        _showMessage("Error: ${e.message}", isError: true);
      }
    } catch (e) {
      _showMessage("Error updating password", isError: true);
    }
  }

  /// Pick profile image from gallery
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
        setState(() {
          _profileImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking profile image: $e");
      _showMessage("Failed to pick image", isError: true);
    }
  }

  /// Pick shop image from gallery
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
        setState(() {
          _shopImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking shop image: $e");
      _showMessage("Failed to pick image", isError: true);
    }
  }

  /// Upload image to Supabase
  Future<String?> _uploadImage(Uint8List imageBytes, String prefix) async {
    try {
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
      final fullFileName = '$fileName.jpg';

      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.storage.from('user-images').uploadBinary(
            fullFileName,
            imageBytes,
            fileOptions: supabase.FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final String imageUrl =
          supabaseClient.storage.from('user-images').getPublicUrl(fullFileName);
      return imageUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required address fields
    if (_pincodeController.text.trim().isEmpty) {
      _showMessage("Pincode is required", isError: true);
      return;
    }
    if (_districtController.text.trim().isEmpty) {
      _showMessage("District is required", isError: true);
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      _showMessage("State is required", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage("User not authenticated", isError: true);
        setState(() => _isSaving = false);
        return;
      }

      // Upload images if selected
      String? profileImageUrl;
      String? shopImageUrl;

      if (_profileImageBytes != null) {
        profileImageUrl = await _uploadImage(_profileImageBytes!, 'profile');
      }
      if (_shopImageBytes != null) {
        shopImageUrl = await _uploadImage(_shopImageBytes!, 'shop');
      }

      // Build full address
      String fullAddress = [
        _addressLineController.text.trim(),
        _cityController.text.trim(),
        _districtController.text.trim(),
        _stateController.text.trim(),
        _pincodeController.text.trim(),
      ].where((s) => s.isNotEmpty).join(', ');

      // Prepare update data
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
        "status": "approved",
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // Add image URLs if uploaded
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

      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("sellerUID", currentUser.uid);
      await prefs.setString("sellerEmail", _email);
      await prefs.setString("sellerName", _sellerName);
      await prefs.setString("shopName", _shopNameController.text.trim());
      await prefs.setString("phone", _phone);
      await prefs.setString("address", fullAddress);

      _showMessage("Profile saved successfully!", isError: false);

      // Navigate to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint("Error saving profile: $e");
      _showMessage("Error saving profile", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Welcome, $_sellerName!",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Complete your shop profile to get started",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Profile & Shop Images Section
              _buildSectionTitle("Profile & Shop Images"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Profile Picture
                  _buildImagePicker(
                    label: "Profile Picture",
                    currentImageUrl: _currentProfileImageUrl,
                    newImageBytes: _profileImageBytes,
                    onTap: _pickProfileImage,
                    size: 100,
                    isCircle: true,
                  ),
                  // Shop Image
                  _buildImagePicker(
                    label: "Shop Image",
                    currentImageUrl: _currentShopImageUrl,
                    newImageBytes: _shopImageBytes,
                    onTap: _pickShopImage,
                    size: 120,
                    isCircle: false,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Account Info Section
              _buildSectionTitle("Account Information"),
              _buildInfoCard([
                _buildInfoRow(Icons.email, "Email",
                    _email.isNotEmpty ? _email : "Not provided"),
                _buildInfoRow(Icons.phone, "Phone",
                    _phone.isNotEmpty ? _phone : "Not provided"),
              ]),
              const SizedBox(height: 10),

              // Change Password Button
              TextButton.icon(
                onPressed: () {
                  setState(() => _showPasswordSection = !_showPasswordSection);
                },
                icon: Icon(
                  _showPasswordSection ? Icons.expand_less : Icons.expand_more,
                  color: Colors.purple,
                ),
                label: Text(
                  _showPasswordSection
                      ? "Hide Password Section"
                      : "Change Password",
                  style: const TextStyle(color: Colors.purple),
                ),
              ),

              if (_showPasswordSection) _buildPasswordSection(),
              const SizedBox(height: 20),

              // Shop Details Section
              _buildSectionTitle("Shop Details"),
              _buildTextField(
                controller: _shopNameController,
                label: "Shop Name *",
                hint: "Enter your shop name",
                icon: Icons.storefront,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Shop name is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _contactController,
                label: "Contact Number *",
                hint: "Phone number for customers",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Contact number is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Address Section
              _buildSectionTitle("Shop Address"),

              // Get Location Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  label: const Text(
                    "Get Current Location",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pincode with auto-fill
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pincodeController,
                      label: "Pincode *",
                      hint: "6-digit pincode",
                      icon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: (value) {
                        if (value.length == 6) {
                          _fetchLocationFromPincode(value);
                        }
                      },
                    ),
                  ),
                  if (_isLoadingPincode)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // District and State (auto-filled)
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _districtController,
                      label: "District *",
                      hint: "District",
                      icon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: "State *",
                      hint: "State",
                      icon: Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // City
              _buildTextField(
                controller: _cityController,
                label: "City / Town",
                hint: "City or Town name",
                icon: Icons.apartment,
              ),
              const SizedBox(height: 16),

              // Address Line (editable)
              _buildTextField(
                controller: _addressLineController,
                label: "Address Line",
                hint: "Street, Building, Landmark etc.",
                icon: Icons.home,
                maxLines: 2,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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
                      : const Text(
                          "Save & Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Change Password",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _currentPasswordController,
            label: "Current Password",
            hint: "Enter current password",
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _newPasswordController,
            label: "New Password",
            hint: "Enter new password",
            icon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Confirm New Password",
            hint: "Confirm new password",
            icon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                "Update Password",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.purple),
            counterText: "",
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
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required String currentImageUrl,
    required Uint8List? newImageBytes,
    required VoidCallback onTap,
    required double size,
    required bool isCircle,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(12),
              border: Border.all(color: Colors.purple, width: 2),
              image: newImageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(newImageBytes),
                      fit: BoxFit.cover,
                    )
                  : currentImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(currentImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: (newImageBytes == null && currentImageUrl.isEmpty)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCircle ? Icons.person_add : Icons.add_photo_alternate,
                        size: size * 0.4,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to add",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            newImageBytes != null || currentImageUrl.isNotEmpty
                ? "Change"
                : "Add",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
