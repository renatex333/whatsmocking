import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for generating HMAC-SHA256 signatures for webhook requests.
///
/// Implements the same signature validation used by WhatsApp webhooks.
class SignatureService {
  final String _appSecret;

  SignatureService({required String appSecret}) : _appSecret = appSecret;

  /// Generates the X-Hub-Signature-256 header value for the given payload.
  ///
  /// Format: "sha256=<hex_hash>"
  ///
  /// Example:
  /// ```dart
  /// final signature = service.generateSignature('{"message": "hello"}');
  /// // Returns: "sha256=abc123..."
  /// ```
  String generateSignature(String payload) {
    final key = utf8.encode(_appSecret);
    final bytes = utf8.encode(payload);

    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    return 'sha256=${digest.toString()}';
  }

  /// Validates if a signature matches the expected value for the given payload.
  ///
  /// Returns true if the signature is valid, false otherwise.
  bool validateSignature(String payload, String signature) {
    if (!signature.startsWith('sha256=')) {
      return false;
    }

    final expectedSignature = generateSignature(payload);

    // Use constant-time comparison to prevent timing attacks
    return _secureCompare(signature, expectedSignature);
  }

  /// Secure string comparison that prevents timing attacks.
  bool _secureCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}
