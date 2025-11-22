import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/utils/logger.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> signIn(String email, String password) async {
    try {
      Logger.info('Signing in user: $email');
      final user = await remoteDataSource.signInWithEmailAndPassword(email, password);
      
      // Check if seller profile exists
      try {
        final sellerData = await remoteDataSource.getSellerData(user.uid);
        await _saveUserDataToLocal(user, sellerData);
        Logger.info('User signed in successfully: ${user.uid}');
        return user;
      } catch (e) {
        // If seller profile doesn't exist, sign out
        await remoteDataSource.signOut();
        throw const AuthFailure('This account is not registered as a seller. Please sign up first.');
      }
    } on Failure {
      rethrow;
    } catch (e) {
      Logger.error('Sign in error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<User> signUp(String email, String password) async {
    try {
      Logger.info('Signing up user: $email');
      final user = await remoteDataSource.signUpWithEmailAndPassword(email, password);
      Logger.info('User created successfully: ${user.uid}');
      return user;
    } on Failure {
      rethrow;
    } catch (e) {
      Logger.error('Sign up error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> createSellerProfile(String uid, Map<String, dynamic> data) async {
    try {
      Logger.info('Creating seller profile: $uid');
      await remoteDataSource.createSellerProfile(uid, data);
      Logger.info('Seller profile created successfully');
    } catch (e) {
      Logger.error('Create seller profile error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      Logger.info('Signing out user');
      await remoteDataSource.signOut();
      await localDataSource.clearUserData();
      Logger.info('User signed out successfully');
    } catch (e) {
      Logger.error('Sign out error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSellerData(String uid) async {
    try {
      return await remoteDataSource.getSellerData(uid);
    } catch (e) {
      Logger.error('Get seller data error', error: e);
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  User? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  Future<void> _saveUserDataToLocal(User user, Map<String, dynamic> sellerData) async {
    await localDataSource.saveUserData({
      'sellerUID': user.uid,
      'sellerEmail': user.email ?? '',
      'sellerName': sellerData['sellerName']?.toString() ?? '',
      'sellerAvatarUrl': sellerData['sellerAvatarUrl']?.toString() ?? '',
      'phone': sellerData['phone']?.toString() ?? '',
      'address': sellerData['address']?.toString() ?? '',
    });
  }
}

