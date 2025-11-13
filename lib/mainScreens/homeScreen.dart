import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectz/mainScreens/addInventoryScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectz/authentication/authScreen.dart';
import 'package:projectz/mainScreens/inventoryScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String sellerName = "";
  String sellerEmail = "";
  String sellerImageUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSellerInfo();
  }

  Future<void> loadSellerInfo() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot sellerSnapshot = await FirebaseFirestore.instance
            .collection("sellers")
            .doc(currentUser.uid)
            .get();

        if (sellerSnapshot.exists) {
          setState(() {
            sellerName = sellerSnapshot.get("sellerName") ?? "";
            sellerEmail = sellerSnapshot.get("sellerEmail") ?? "";
            sellerImageUrl = sellerSnapshot.get("sellerAvatarUrl") ?? "";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading seller info: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signOut() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Home',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) {
                  return AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(c);
                          signOut();
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
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    
                    // Profile Image
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.purple.shade100,
                      backgroundImage: sellerImageUrl.isNotEmpty
                          ? NetworkImage(sellerImageUrl)
                          : null,
                      child: sellerImageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.purple,
                            )
                          : null,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Seller Name
                    Text(
                      sellerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Seller Email
                    Text(
                      sellerEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Welcome Card
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Icon(
                              Icons.store,
                              size: 60,
                              color: Colors.purple.shade300,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Welcome to Your Seller Dashboard!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Your account has been successfully created. Start managing your products and orders.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.inventory,
                          label: 'Inventory',
                          color: const Color.fromARGB(255, 237, 42, 42),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InventoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.add_box,
                          label: 'Add Product',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddInventoryScreen()));
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.list_alt,
                          label: 'My Orders',
                          color: Colors.orange,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('My Orders feature coming soon!'),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.insights,
                          label: 'Analytics',
                          color: Colors.blue,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Analytics feature coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
