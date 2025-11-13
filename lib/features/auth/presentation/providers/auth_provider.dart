import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final _authRepository = ServiceLocator().authRepository;

  User? _currentUser;
  Map<String, dynamic>? _sellerData;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get sellerData => _sellerData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  String get sellerName => _sellerData?['sellerName'] ?? '';
  String get sellerEmail => _sellerData?['sellerEmail'] ?? _currentUser?.email ?? '';
  String get sellerImageUrl => _sellerData?['sellerAvatarUrl'] ?? '';

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _currentUser = _authRepository.getCurrentUser();
    if (_currentUser != null) {
      await loadSellerData();
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      return await _authRepository.isLoggedIn();
    } catch (e) {
      Logger.error('Error checking login status', error: e);
      // Fallback to checking current user
      return _currentUser != null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signIn(email, password);
      _currentUser = user;
      await loadSellerData();
      Logger.info('User signed in successfully: ${user.uid}');
      _setLoading(false);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Sign in error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signUp(email, password);
      _currentUser = user;
      Logger.info('User signed up successfully: ${user.uid}');
      _setLoading(false);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Sign up error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> createSellerProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authRepository.createSellerProfile(_currentUser!.uid, data);
      await loadSellerData();
      Logger.info('Seller profile created successfully');
      _setLoading(false);
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Create seller profile error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadSellerData() async {
    if (_currentUser == null) return;

    try {
      _sellerData = await _authRepository.getSellerData(_currentUser!.uid);
      notifyListeners();
    } catch (e) {
      Logger.error('Load seller data error', error: e);
    }
  }

  Future<bool> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _sellerData = null;
      Logger.info('User signed out successfully');
      _setLoading(false);
      notifyListeners();
      return true;
    } on Failure catch (failure) {
      _setError(failure.message);
      _setLoading(false);
      return false;
    } catch (e) {
      Logger.error('Sign out error', error: e);
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}

