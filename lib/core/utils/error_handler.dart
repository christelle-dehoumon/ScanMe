import 'package:logger/logger.dart';

/// Custom exception types for the app
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

class NetworkException extends AppException {
  NetworkException({String message = 'Network error', String? code})
      : super(message: message, code: code ?? 'NETWORK_ERROR');
}

class AuthException extends AppException {
  AuthException({String message = 'Authentication failed', String? code})
      : super(message: message, code: code ?? 'AUTH_ERROR');
}

class DatabaseException extends AppException {
  DatabaseException({String message = 'Database error', String? code})
      : super(message: message, code: code ?? 'DB_ERROR');
}

class ValidationException extends AppException {
  ValidationException({String message = 'Validation error', String? code})
      : super(message: message, code: code ?? 'VALIDATION_ERROR');
}

/// Centralized error handling
class ErrorHandler {
  static final _logger = Logger();

  /// Handle and log errors
  static Future<void> handleError(
    dynamic error, {
    required String context,
    bool shouldRethrow = false,
  }) async {
    _logger.e(
      'Error in $context',
      error: error,
      stackTrace: StackTrace.current,
    );

    // TODO: Send to error tracking service (Sentry, etc.)

    if (shouldRethrow) {
      throw error;
    }
  }

  /// Get user-friendly error message
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    } else if (error is NetworkException) {
      return 'Erreur de connexion. Vérifiez votre connexion Internet.';
    } else if (error is AuthException) {
      return 'Erreur d\'authentification. Veuillez réessayer.';
    } else if (error is DatabaseException) {
      return 'Erreur de stockage. Veuillez réessayer.';
    } else if (error is ValidationException) {
      return 'Données invalides. Veuillez vérifier votre saisie.';
    }
    return 'Une erreur inattendue s\'est produite.';
  }
}
