class AppConstants {
  // App Info
  static const String appName = 'Seller App';
  static const String appVersion = '1.0.0';

  // Collections
  static const String sellersCollection = 'sellers';
  static const String inventoryCollection = 'inventory';
  static const String ordersCollection = 'orders';

  // SharedPreferences Keys
  static const String sellerUIDKey = 'sellerUID';
  static const String sellerEmailKey = 'sellerEmail';
  static const String sellerNameKey = 'sellerName';
  static const String sellerAvatarUrlKey = 'sellerAvatarUrl';
  static const String phoneKey = 'phone';
  static const String addressKey = 'address';
  static const String isLoggedInKey = 'isLoggedIn';

  // Storage Buckets
  static const String userImagesBucket = 'user-images';
  static const String productImagesBucket = 'product-images';

  // Validation
  static const int minPasswordLength = 6;
  static const int minPhoneLength = 10;

  // Stock Thresholds
  static const double lowStockThreshold = 0.2; // 20% of capacity

  // Pagination
  static const int itemsPerPage = 20;

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unexpected error occurred.';
  static const String authError = 'Authentication failed. Please try again.';
}

