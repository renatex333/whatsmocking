import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/message.dart';
import '../../config/api_config.dart';
import '../../config/signature_service.dart';

/// Repository for chat API operations.
///
/// Implements the Repository Pattern to separate data access logic from the UI layer.
/// Uses Dio for HTTP networking.
class ChatRepository {
  final Dio _dio;
  final String _baseUrl;
  final String _messagesEndpoint;
  final SignatureService _signatureService;

  ChatRepository({
    Dio? dio,
    String? baseUrl,
    String? messagesEndpoint,
    SignatureService? signatureService,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _messagesEndpoint = messagesEndpoint ?? ApiConfig.messagesUrl,
        _signatureService = signatureService ??
            SignatureService(appSecret: ApiConfig.appSecret) {
    _dio.options.connectTimeout = const Duration(seconds: 180);
    _dio.options.receiveTimeout = const Duration(seconds: 180);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Sends a new message to the API via POST in WhatsApp Business API webhook format.
  ///
  /// Returns the created [Message] with server-assigned ID.
  /// Throws [DioException] on network errors.
  ///
  /// If [customPayload] is provided, it will be used instead of converting the message.
  Future<Message> sendMessage(Message message,
      {Map<String, dynamic>? customPayload}) async {
    try {
      // Use custom payload if provided, otherwise convert message to webhook format
      final webhookPayload = customPayload ?? message.toWhatsAppWebhookJson();

      // Serialize to JSON string
      final jsonPayload = jsonEncode(webhookPayload);

      // Generate HMAC-SHA256 signature
      final signature = _signatureService.generateSignature(jsonPayload);

      final response = await _dio.post(
        _messagesEndpoint,
        data: jsonPayload,
        options: Options(
          headers: {
            'X-Hub-Signature-256': signature,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return Message.fromJson(response.data as Map<String, dynamic>);
      }

      return message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handles Dio errors and provides meaningful error messages.
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
            'Connection timeout. Please check if the server is running.');
      case DioExceptionType.connectionError:
        return Exception(
            'Connection error. Please check your network and server.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return Exception('Server error: $statusCode');
      default:
        return Exception('Network error: ${e.message}');
    }
  }

  /// Gets the current base URL being used.
  String get currentBaseUrl => _baseUrl;
}
