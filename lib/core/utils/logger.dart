import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final levelStr = level.name.toUpperCase();
      
      switch (level) {
        case LogLevel.debug:
          debugPrint('[$timestamp] [DEBUG] $message');
          break;
        case LogLevel.info:
          debugPrint('[$timestamp] [INFO] $message');
          break;
        case LogLevel.warning:
          debugPrint('[$timestamp] [WARNING] $message');
          break;
        case LogLevel.error:
          debugPrint('[$timestamp] [ERROR] $message');
          if (error != null) {
            debugPrint('Error: $error');
          }
          if (stackTrace != null) {
            debugPrint('StackTrace: $stackTrace');
          }
          break;
      }
    }
  }

  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
}

