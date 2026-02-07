import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Usa --dart-define=API_BASE_URL=...
  ///
  /// Producción (default):
  ///   https://API.pty5m.com/api
  ///
  /// Desarrollo:
  /// - Web local       -> http://localhost:3000/api
  /// - Android emulator-> http://10.0.2.2:3000/api
  /// - iOS simulator   -> http://127.0.0.1:3000/api
  /// URL base del API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.pty5m.com/api',
  );

  /// URL base para archivos subidos (SIN /api)
  static const String uploadsUrl = String.fromEnvironment(
    'UPLOADS_BASE_URL',
    defaultValue: 'https://api.pty5m.com',
  );

  /// Helper opcional
  static bool get isProd => !kDebugMode;
}