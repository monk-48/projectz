class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number.';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'a number'}.';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number.';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    final num = int.tryParse(value ?? '');
    if (num != null && num <= 0) {
      return 'Please enter a positive number.';
    }
    return null;
  }
}

