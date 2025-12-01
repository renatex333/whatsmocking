import 'package:flutter/foundation.dart';
import '../data/models/message.dart';
import '../data/repositories/chat_repository.dart';

/// State management provider for chat functionality.
/// 
/// Uses ChangeNotifier (Provider pattern) for reactive state management.
class ChatProvider with ChangeNotifier {
  final ChatRepository _repository;
  
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  ChatProvider({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  /// List of all messages.
  List<Message> get messages => List.unmodifiable(_messages);

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether there's an active error.
  bool get hasError => _errorMessage != null;

  /// Current API base URL.
  String get currentBaseUrl => _repository.currentBaseUrl;

  /// Fetches messages from the API.
  Future<void> fetchMessages() async {
    _setLoading(true);
    _clearError();

    try {
      _messages = await _repository.getMessages();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Sends a new message.
  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) {
      return false;
    }

    _clearError();

    final message = Message(
      content: content.trim(),
      isSentByMe: true,
    );

    // Optimistically add message to the list
    _messages.add(message);
    notifyListeners();

    try {
      final sentMessage = await _repository.sendMessage(message);
      
      // Replace optimistic message with server response
      final index = _messages.indexOf(message);
      if (index != -1) {
        _messages[index] = sentMessage;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      // Remove optimistic message on error
      _messages.remove(message);
      _setError(e.toString());
      return false;
    }
  }

  /// Adds a received message (e.g., from webhook).
  void addReceivedMessage(Message message) {
    _messages.add(message.copyWith(isSentByMe: false));
    notifyListeners();
  }

  /// Clears all messages.
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _clearError();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
