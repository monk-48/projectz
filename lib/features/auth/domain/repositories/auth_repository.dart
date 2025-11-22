import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<User> signIn(String email, String password);
  Future<User> signUp(String email, String password);
  Future<void> createSellerProfile(String uid, Map<String, dynamic> data);
  Future<void> signOut();
  Future<Map<String, dynamic>> getSellerData(String uid);
  User? getCurrentUser();
  Future<bool> isLoggedIn();
}

