import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration with adaptive URL detection for Android emulator and other platforms.
class ApiConfig {
  static const String _defaultPort = '3000';
  static const String _messagesEndpoint = '/messages';

  /// Returns the base URL based on the platform.
  /// 
  /// For Android emulator: uses 10.0.2.2 (special alias for host machine's localhost)
  /// For iOS simulator/other platforms: uses localhost
  /// For web: uses localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }

    try {
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to access host machine's localhost
        return 'http://10.0.2.2:$_defaultPort';
      }
    } catch (_) {
      // Platform not available (e.g., during tests)
    }

    // iOS simulator and other platforms use localhost directly
    return 'http://localhost:$_defaultPort';
  }

  /// Full URL for the messages endpoint.
  static String get messagesUrl => '$baseUrl$_messagesEndpoint';

  /// Default port for the API server.
  static String get port => _defaultPort;

  /// Creates a custom base URL with the given host and port.
  static String customBaseUrl(String host, {String port = _defaultPort}) {
    return 'http://$host:$port';
  }
}
