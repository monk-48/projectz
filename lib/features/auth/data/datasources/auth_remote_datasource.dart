import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exception_handler.dart';

abstract class AuthRemoteDataSource {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<Map<String, dynamic>> getSellerData(String uid);
  Future<void> createSellerProfile(String uid, Map<String, dynamic> data);
  User? getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw const AuthFailure('User is null after sign in');
      }
      return credential.user!;
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<User> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw const AuthFailure('User is null after sign up');
      }
      return credential.user!;
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSellerData(String uid) async {
    try {
      final doc = await firestore.collection('sellers').doc(uid).get();
      if (!doc.exists) {
        throw const AuthFailure('Seller profile not found');
      }
      return doc.data()!;
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> createSellerProfile(String uid, Map<String, dynamic> data) async {
    try {
      await firestore.collection('sellers').doc(uid).set(data);
    } catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  User? getCurrentUser() {
    return firebaseAuth.currentUser;
  }
}

