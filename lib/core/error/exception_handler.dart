import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../error/failures.dart';
import '../utils/logger.dart';

class ExceptionHandler {
  static Failure handleException(dynamic exception) {
    Logger.error('Exception occurred', error: exception);

    if (exception is FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    }

    if (exception is FirebaseException) {
      return _handleFirebaseException(exception);
    }

    if (exception is FormatException) {
      return ValidationFailure('Invalid data format: ${exception.message}');
    }

    if (exception.toString().contains('network') ||
        exception.toString().contains('Network')) {
      return NetworkFailure('Network error. Please check your connection.');
    }

    return UnknownFailure('An unexpected error occurred: ${exception.toString()}');
  }

  static Failure _handleFirebaseAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return AuthFailure('No user found with this email.');
      case 'wrong-password':
        return AuthFailure('Incorrect password. Please try again.');
      case 'invalid-email':
        return AuthFailure('Invalid email format.');
      case 'user-disabled':
        return AuthFailure('This account has been disabled.');
      case 'too-many-requests':
        return AuthFailure('Too many login attempts. Please try again later.');
      case 'email-already-in-use':
        return AuthFailure('This email is already registered.');
      case 'weak-password':
        return AuthFailure('Password is too weak.');
      default:
        return AuthFailure('Authentication failed: ${exception.message}');
    }
  }

  static Failure _handleFirebaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return ServerFailure('Permission denied. Please check your access.');
      case 'unavailable':
        return NetworkFailure('Service is currently unavailable.');
      case 'deadline-exceeded':
        return NetworkFailure('Request timeout. Please try again.');
      default:
        return ServerFailure('Database error: ${exception.message}');
    }
  }

  static String getErrorMessage(Failure failure) {
    return failure.message;
  }
}

