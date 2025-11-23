import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectz/authentication/authScreen.dart';
import 'package:projectz/mainScreens/editProfileScreen.dart';

/// Profile screen displays user information and provides account management
/// Following Single Responsibility Principle - handles only profile display and basic actions
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data state
  String _sellerName = "";
  String _sellerEmail = "";
  String _sellerImageUrl = "";
  String _sellerPhone = "";
  String _shopName = "";
  String _shopImage = "";
  String _shopAddress = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Loads user profile data from Firestore
  /// Separation of concerns - data fetching logic isolated
  Future<void> _loadUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _navigateToAuth();
        return;
      }

      final sellerSnapshot = await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .get();

      if (sellerSnapshot.exists && mounted) {
        final data = sellerSnapshot.data()!;
        setState(() {
          _sellerName = data["sellerName"] ?? "";
          _sellerEmail = data["sellerEmail"] ?? "";
          _sellerImageUrl = data["sellerAvatarUrl"] ?? "";
          _sellerPhone = data["phone"] ?? "";
          // Shop details with fallbacks to user details
          _shopName = data["shopName"] ?? data["sellerName"] ?? "My Shop";
          _shopImage = data["shopImage"] ?? data["sellerAvatarUrl"] ?? "";
          _shopAddress = data["address"] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage("Failed to load profile data");
      }
    }
  }

  /// Handles user sign out
  /// Clear local data and navigate to authentication
  Future<void> _handleSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _navigateToAuth();
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
      if (mounted) {
        _showErrorMessage("Failed to sign out");
      }
    }
  }

  /// Shows logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation helpers
  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildProfileContent(),
    );
  }

  /// Builds app bar with logout action
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.purple,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _showLogoutDialog,
        ),
      ],
    );
  }

  /// Loading indicator
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Main profile content
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildShopImage(),
          const SizedBox(height: 24),
          _buildShopInfo(),
          const SizedBox(height: 24),
          _buildUserInfo(),
          const SizedBox(height: 32),
          _buildProfileActions(),
        ],
      ),
    );
  }

  /// Shop image widget
  Widget _buildShopImage() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _shopImage.isNotEmpty
            ? Image.network(
                _shopImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultShopIcon();
                },
              )
            : _buildDefaultShopIcon(),
      ),
    );
  }

  /// Default shop icon when no image is set
  Widget _buildDefaultShopIcon() {
    return Container(
      color: Colors.purple.shade50,
      child: const Icon(
        Icons.store,
        size: 80,
        color: Colors.purple,
      ),
    );
  }

  /// Shop information display
  Widget _buildShopInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                _shopName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, "Contact", _sellerPhone),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, "Address", _shopAddress),
          ],
        ),
      ),
    );
  }

  /// User information display
  Widget _buildUserInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.purple.shade100,
                  backgroundImage: _sellerImageUrl.isNotEmpty
                      ? NetworkImage(_sellerImageUrl)
                      : null,
                  child: _sellerImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.purple,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sellerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sellerEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Individual info row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : "Not provided",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Profile action buttons
  Widget _buildProfileActions() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.edit,
          label: "Edit Profile",
          color: Colors.blue,
          onTap: _navigateToEditProfile,
        ),
      ],
    );
  }

  /// Navigate to edit profile screen
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    // Reload profile if changes were saved
    if (result == true) {
      _loadUserProfile();
    }
  }

  /// Reusable action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
