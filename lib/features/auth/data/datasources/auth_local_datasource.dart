import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUserData(Map<String, String> userData);
  Future<Map<String, String?>> getUserData();
  Future<void> clearUserData();
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveUserData(Map<String, String> userData) async {
    try {
      for (var entry in userData.entries) {
        await sharedPreferences.setString(entry.key, entry.value);
      }
      await sharedPreferences.setBool(AppConstants.isLoggedInKey, true);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  @override
  Future<Map<String, String?>> getUserData() async {
    try {
      return {
        AppConstants.sellerUIDKey: sharedPreferences.getString(AppConstants.sellerUIDKey),
        AppConstants.sellerEmailKey: sharedPreferences.getString(AppConstants.sellerEmailKey),
        AppConstants.sellerNameKey: sharedPreferences.getString(AppConstants.sellerNameKey),
        AppConstants.sellerAvatarUrlKey: sharedPreferences.getString(AppConstants.sellerAvatarUrlKey),
        AppConstants.phoneKey: sharedPreferences.getString(AppConstants.phoneKey),
        AppConstants.addressKey: sharedPreferences.getString(AppConstants.addressKey),
      };
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  @override
  Future<void> clearUserData() async {
    try {
      await sharedPreferences.remove(AppConstants.sellerUIDKey);
      await sharedPreferences.remove(AppConstants.sellerEmailKey);
      await sharedPreferences.remove(AppConstants.sellerNameKey);
      await sharedPreferences.remove(AppConstants.sellerAvatarUrlKey);
      await sharedPreferences.remove(AppConstants.phoneKey);
      await sharedPreferences.remove(AppConstants.addressKey);
      await sharedPreferences.setBool(AppConstants.isLoggedInKey, false);
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      return sharedPreferences.getBool(AppConstants.isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }
}

