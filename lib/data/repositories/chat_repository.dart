import 'package:dio/dio.dart';
import '../models/message.dart';
import '../../config/api_config.dart';

/// Repository for chat API operations.
/// 
/// Implements the Repository Pattern to separate data access logic from the UI layer.
/// Uses Dio for HTTP networking.
class ChatRepository {
  final Dio _dio;
  final String _baseUrl;

  ChatRepository({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Fetches all messages from the API.
  /// 
  /// Returns a list of [Message] objects.
  /// Throws [DioException] on network errors.
  Future<List<Message>> getMessages() async {
    try {
      final response = await _dio.get('$_baseUrl/messages');
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sends a new message to the API via POST.
  /// 
  /// Returns the created [Message] with server-assigned ID.
  /// Throws [DioException] on network errors.
  Future<Message> sendMessage(Message message) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/messages',
        data: message.toJson(),
      );
      
      if (response.data is Map<String, dynamic>) {
        return Message.fromJson(response.data as Map<String, dynamic>);
      }
      
      return message;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Deletes a message by ID.
  /// 
  /// Throws [DioException] on network errors.
  Future<void> deleteMessage(String id) async {
    try {
      await _dio.delete('$_baseUrl/messages/$id');
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
        return Exception('Connection timeout. Please check if the server is running.');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check your network and server.');
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
