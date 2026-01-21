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
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pty5m.com/api',
  );

  /// Helpers opcionales (solo para debug)
  static bool get isProd => !kDebugMode;
}