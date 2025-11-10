import 'package:flutter/material.dart';
import 'package:projectz/widgets/customTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projectz/widgets/loadingDialog.dart';
import 'package:projectz/mainScreens/homeScreen.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({Key? key}) : super(key: key);

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailFieldController = TextEditingController();
  TextEditingController passwordFieldController = TextEditingController();

  Future<void> formValidation() async {
    if (emailFieldController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Please enter your email."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (!emailFieldController.text.contains("@")) {
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Please enter a valid email."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (passwordFieldController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Please enter your password."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (passwordFieldController.text.length < 6) {
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Password must be at least 6 characters."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      // Proceed with login
      await signInUser();
    }
  }

  Future<void> signInUser() async {
    showDialog(
      context: context,
      builder: (c) {
        return LoadingDialog(
          message: "Checking credentials...",
        );
      },
    );

    User? currentUser;

    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

      await firebaseAuth.signInWithEmailAndPassword(
        email: emailFieldController.text.trim(),
        password: passwordFieldController.text.trim(),
      ).then((auth) {
        currentUser = auth.user;
      });

      if (currentUser != null) {
        // Check if user exists in sellers collection
        await checkIfSellerRecordExists(currentUser!);
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading dialog

      String errorMessage = "";
      
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This account has been disabled.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many login attempts. Please try again later.";
      } else {
        errorMessage = "Login failed: ${e.message}";
      }

      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Login Error"),
            content: Text(errorMessage),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("An unexpected error occurred: ${e.toString()}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> checkIfSellerRecordExists(User currentUser) async {
    try {
      DocumentSnapshot sellerSnapshot = await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .get();

      if (sellerSnapshot.exists) {
        // Save user data to SharedPreferences
        await saveUserDataToSharedPreferences(currentUser, sellerSnapshot);

        Navigator.pop(context); // Close loading dialog

        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const HomeScreen()),
        );
      } else {
        Navigator.pop(context); // Close loading dialog

        // User not found in sellers collection
        await FirebaseAuth.instance.signOut();

        showDialog(
          context: context,
          builder: (c) {
            return AlertDialog(
              title: const Text("No Record Found"),
              content: const Text(
                  "This account is not registered as a seller. Please sign up first."),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(c);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("Error checking user record: ${e.toString()}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> saveUserDataToSharedPreferences(
      User currentUser, DocumentSnapshot sellerSnapshot) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("sellerUID", currentUser.uid);
    await prefs.setString("sellerEmail", currentUser.email ?? "");
    await prefs.setString(
        "sellerName", sellerSnapshot.get("sellerName") ?? "");
    await prefs.setString(
        "sellerAvatarUrl", sellerSnapshot.get("sellerAvatarUrl") ?? "");
    await prefs.setString("phone", sellerSnapshot.get("phone") ?? "");
    await prefs.setString("address", sellerSnapshot.get("address") ?? "");

    // Debug logging
    print("=== LOGIN: SharedPreferences Saved ===");
    print("sellerUID: ${currentUser.uid}");
    print("sellerEmail: ${currentUser.email}");
    print("sellerName: ${sellerSnapshot.get("sellerName")}");
    print("=====================================");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'images/seller.png',
                  height: 270,
                ),
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: emailFieldController,
                    data: Icons.email,
                    hintText: 'Email',
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: passwordFieldController,
                    data: Icons.lock,
                    hintText: 'Password',
                  ),
                ],
              ),
            ),
            ElevatedButton(
              child: const Text(
                "LogIn",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () {
                formValidation();
              },
            ),
            const SizedBox( height: 30, ),
          ],
        ),
    );
  }
}