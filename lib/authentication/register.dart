import 'package:flutter/material.dart';
import 'package:projectz/widgets/customTextField.dart';
import 'package:projectz/widgets/loadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectz/mainScreens/profileSetupScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameFieldController = TextEditingController();
  TextEditingController emailFieldController = TextEditingController();
  TextEditingController passwordFieldController = TextEditingController();
  TextEditingController confirmPasswordFieldController =
      TextEditingController();
  TextEditingController phoneFieldController = TextEditingController();

  bool _usePhone = false;

  Future<void> formValidation() async {
    if (nameFieldController.text.trim().isEmpty) {
      _showError("Please enter your name.");
      return;
    }

    if (_usePhone) {
      if (phoneFieldController.text.trim().isEmpty) {
        _showError("Please enter your phone number.");
        return;
      }
      if (phoneFieldController.text.trim().length < 10) {
        _showError("Please enter a valid phone number.");
        return;
      }
    } else {
      if (emailFieldController.text.trim().isEmpty) {
        _showError("Please enter your email.");
        return;
      }
      if (!emailFieldController.text.contains("@")) {
        _showError("Please enter a valid email.");
        return;
      }
    }

    if (passwordFieldController.text.trim().isEmpty) {
      _showError("Please enter a password.");
      return;
    }
    if (passwordFieldController.text.length < 6) {
      _showError("Password must be at least 6 characters.");
      return;
    }
    if (confirmPasswordFieldController.text.trim().isEmpty) {
      _showError("Please confirm your password.");
      return;
    }
    if (passwordFieldController.text != confirmPasswordFieldController.text) {
      _showError("Passwords do not match.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => LoadingDialog(message: "Creating Account..."),
    );

    await _registerUser();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _registerUser() async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      User? currentUser;

      String email = _usePhone
          ? "${phoneFieldController.text.trim()}@phone.projectz.com"
          : emailFieldController.text.trim();

      await firebaseAuth
          .createUserWithEmailAndPassword(
        email: email,
        password: passwordFieldController.text.trim(),
      )
          .then((auth) {
        currentUser = auth.user;
      });

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection("sellers")
            .doc(currentUser!.uid)
            .set({
          "sellerUID": currentUser!.uid,
          "sellerEmail": _usePhone ? "" : emailFieldController.text.trim(),
          "sellerName": nameFieldController.text.trim(),
          "phone": phoneFieldController.text.trim(),
          "sellerAvatarUrl": "",
          "shopName": "",
          "shopImage": "",
          "address": "",
          "addressLine": "",
          "pincode": "",
          "district": "",
          "state": "",
          "city": "",
          "contactDetails": "",
          "status": "pending_setup",
          "profileComplete": false,
          "earnings": 0.0,
          "lat": 0.0,
          "lng": 0.0,
          "createdAt": FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const ProfileSetupScreen()),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      String errorMessage = e.toString();
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = "This email/phone is already registered.";
        } else if (e.code == 'weak-password') {
          errorMessage = "Password is too weak.";
        }
      }

      _showError(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.store,
              size: 100,
              color: Colors.purple.shade300,
            ),
            const SizedBox(height: 10),
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Email"),
                  selected: !_usePhone,
                  selectedColor: Colors.purple.shade200,
                  onSelected: (selected) {
                    setState(() => _usePhone = false);
                  },
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("Phone"),
                  selected: _usePhone,
                  selectedColor: Colors.purple.shade200,
                  onSelected: (selected) {
                    setState(() => _usePhone = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: nameFieldController,
                    data: Icons.person,
                    hintText: 'Full Name',
                    isObsecure: false,
                  ),
                  if (_usePhone)
                    CustomTextField(
                      controller: phoneFieldController,
                      data: Icons.phone,
                      hintText: 'Phone Number',
                      isObsecure: false,
                    )
                  else
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
                  CustomTextField(
                    controller: confirmPasswordFieldController,
                    data: Icons.lock,
                    hintText: 'Confirm Password',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: formValidation,
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You'll complete your shop profile in the next step",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
