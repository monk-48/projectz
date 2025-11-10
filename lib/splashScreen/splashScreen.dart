import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projectz/authentication/authScreen.dart';
import 'package:projectz/mainScreens/homeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {

  Future<void> startTimer() async {
    // Wait for 1 second
    await Future.delayed(const Duration(seconds: 1));
    
    // Check if user is logged in using SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sellerUID = prefs.getString("sellerUID");
    String? sellerEmail = prefs.getString("sellerEmail");
    
    // Debug logging - check console/terminal output
    print("=== SharedPreferences Debug ===");
    print("sellerUID: $sellerUID");
    print("sellerEmail: $sellerEmail");
    print("Firebase currentUser: ${FirebaseAuth.instance.currentUser?.uid}");
    print("==============================");

    // Check if user is logged in
    if (sellerUID != null && sellerUID.isNotEmpty) {
      // User is logged in, go to HomeScreen
      print("✅ User found in SharedPreferences - Going to HomeScreen");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const HomeScreen()),
      );
    } else {
      // User is not logged in, go to AuthScreen
      print("❌ No user in SharedPreferences - Going to AuthScreen");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const AuthScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/vastukiLogo.jpg',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(18.0),
                child: Text(
                  'Welcome to Seller App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                    fontFamily: 'Signatra',
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}