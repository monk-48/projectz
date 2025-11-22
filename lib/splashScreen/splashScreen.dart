import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projectz/core/constants/app_strings.dart';
import 'package:projectz/core/routes/app_routes.dart';
import 'package:projectz/core/utils/logger.dart';
import 'package:projectz/features/auth/presentation/providers/auth_provider.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for 1 second for splash screen display
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    // Check if user is logged in
    // Wait a bit for AuthProvider to initialize
    await Future.delayed(const Duration(milliseconds: 100));
    
    final isLoggedIn = await authProvider.isLoggedIn();
    final hasCurrentUser = authProvider.currentUser != null;
    
    Logger.info('Splash screen: User logged in status: $isLoggedIn');
    Logger.debug('Splash screen: Current user: ${authProvider.currentUser?.uid}');

    if (!mounted) return;

    if (isLoggedIn && hasCurrentUser) {
      // User is logged in, load seller data and go to HomeScreen
      Logger.info('User found - Navigating to HomeScreen');
      await authProvider.loadSellerData();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      // User is not logged in, go to AuthScreen
      Logger.info('No user found - Navigating to AuthScreen');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.auth);
      }
    }
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
                  AppStrings.welcome,
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
