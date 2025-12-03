import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/message.dart';
import '../data/models/whatsapp_message.dart';
import '../data/models/contact.dart';
import '../data/repositories/chat_repository.dart';
import '../services/webhook_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// State management provider for chat functionality.
///
/// Uses ChangeNotifier (Provider pattern) for reactive state management.
class ChatProvider with ChangeNotifier {
  final ChatRepository _repository;
  WebhookServer? _webhookServer;

  List<Contact> _contacts = [];
  Contact? _selectedContact;
  final Map<String, List<Message>> _messagesByContact = {};
  final bool _isLoading = false;
  String? _errorMessage;
  bool _isServerRunning = false;

  static const String _contactsKey = 'contacts';
  static const String _messagesKeyPrefix = 'messages_';

  ChatProvider({ChatRepository? repository})
      : _repository = repository ?? ChatRepository() {
    _initializeWebhookServer();
    _loadContacts();
  }

  /// List of all contacts.
  List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Currently selected contact.
  Contact? get selectedContact => _selectedContact;

  /// Messages for the currently selected contact.
  List<Message> get messages {
    if (_selectedContact == null) return [];
    return List.unmodifiable(_messagesByContact[_selectedContact!.id] ?? []);
  }

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether there's an active error.
  bool get hasError => _errorMessage != null;

  /// Current API base URL.
  String get currentBaseUrl => _repository.currentBaseUrl;

  /// Whether the webhook server is running.
  bool get isServerRunning => _isServerRunning;

  /// Server port.
  int get serverPort =>
      int.tryParse(dotenv.env['SERVER_PORT'] ?? '9090') ?? 9090;

  /// Loads contacts from SharedPreferences.
  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString(_contactsKey);

      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        _contacts = decoded
            .map((json) => Contact.fromJson(json as Map<String, dynamic>))
            .toList();

        // Load messages for each contact
        for (var contact in _contacts) {
          await _loadMessagesForContact(contact.id);
        }

        // Select first contact if available
        if (_contacts.isNotEmpty && _selectedContact == null) {
          _selectedContact = _contacts.first;
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  /// Saves contacts to SharedPreferences.
  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          jsonEncode(_contacts.map((c) => c.toJson()).toList());
      await prefs.setString(_contactsKey, contactsJson);
    } catch (e) {
      print('Error saving contacts: $e');
    }
  }

  /// Loads messages for a specific contact.
  Future<void> _loadMessagesForContact(String contactId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('$_messagesKeyPrefix$contactId');

      if (messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        _messagesByContact[contactId] = decoded
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _messagesByContact[contactId] = [];
      }
    } catch (e) {
      print('Error loading messages for contact $contactId: $e');
      _messagesByContact[contactId] = [];
    }
  }

  /// Saves messages for a specific contact.
  Future<void> _saveMessagesForContact(String contactId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messages = _messagesByContact[contactId] ?? [];
      final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString('$_messagesKeyPrefix$contactId', messagesJson);
    } catch (e) {
      print('Error saving messages for contact $contactId: $e');
    }
  }

  /// Adds a new contact.
  Future<void> addContact(String name, String phoneNumber) async {
    final contact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phoneNumber: phoneNumber,
    );

    _contacts.add(contact);
    _messagesByContact[contact.id] = [];

    await _saveContacts();

    // Select the new contact
    _selectedContact = contact;
    notifyListeners();
  }

  /// Removes a contact and its messages.
  Future<void> removeContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
    _messagesByContact.remove(contactId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_messagesKeyPrefix$contactId');
    await _saveContacts();

    // Select first contact or null
    if (_selectedContact?.id == contactId) {
      _selectedContact = _contacts.isNotEmpty ? _contacts.first : null;
    }

    notifyListeners();
  }

  /// Updates an existing contact.
  Future<void> updateContact(
      String contactId, String name, String phoneNumber) async {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        name: name,
        phoneNumber: phoneNumber,
      );
      await _saveContacts();
      notifyListeners();
    }
  }

  /// Selects a contact to view its messages.
  void selectContact(Contact contact) {
    _selectedContact = contact;
    notifyListeners();
  }

  /// Initializes the webhook server to receive messages from API.
  Future<void> _initializeWebhookServer() async {
    try {
      _webhookServer = WebhookServer(port: serverPort);
      await _webhookServer!.start();
      _isServerRunning = true;

      // Listen to incoming messages
      _webhookServer!.messageStream.listen((whatsappMessage) {
        _handleIncomingMessage(whatsappMessage);
      });

      notifyListeners();
    } catch (e) {
      print('Failed to start webhook server: $e');
      _isServerRunning = false;
    }
  }

  /// Handles incoming messages from the webhook server.
  void _handleIncomingMessage(WhatsAppMessage whatsappMessage) {
    if (_selectedContact == null) return;

    final message = Message(
      content: whatsappMessage.getDisplayText(),
      isSentByMe: false,
      messageType: whatsappMessage.type,
      interactive: whatsappMessage.interactive != null
          ? {
              'type': whatsappMessage.interactive!.type,
              'body': whatsappMessage.interactive!.body,
              'header': whatsappMessage.interactive!.header,
              'action': whatsappMessage.interactive!.action,
            }
          : null,
    );

    final contactId = _selectedContact!.id;
    _messagesByContact[contactId] = _messagesByContact[contactId] ?? [];
    _messagesByContact[contactId]!.add(message);

    // Update contact's last message
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
      );
      _saveContacts();
    }

    _saveMessagesForContact(contactId);
    notifyListeners();
  }

  /// Sends a new message.
  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty || _selectedContact == null) {
      return false;
    }

    _clearError();

    final message = Message(
      content: content.trim(),
      isSentByMe: true,
    );

    final contactId = _selectedContact!.id;
    _messagesByContact[contactId] = _messagesByContact[contactId] ?? [];

    // Optimistically add message to the list
    _messagesByContact[contactId]!.add(message);

    // Update contact's last message
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        lastMessage: content.trim(),
        lastMessageTime: message.timestamp,
      );
    }

    notifyListeners();

    try {
      // Send with contact's phone number in webhook format
      final contact = _selectedContact!;
      await _repository.sendMessage(
        message,
        customPayload: message.toWhatsAppWebhookJson(
          waId: contact.phoneNumber,
          displayPhoneNumber: contact.phoneNumber,
          profileName: contact.name,
        ),
      );

      await _saveMessagesForContact(contactId);
      await _saveContacts();
      notifyListeners();

      return true;
    } catch (e) {
      // Remove optimistic message on error
      _messagesByContact[contactId]!.remove(message);
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Sends an interactive button reply.
  Future<bool> sendButtonReply(String buttonId, String buttonTitle) async {
    if (_selectedContact == null) return false;

    _clearError();

    // Create message with button reply format
    final displayMessage = Message(
      content: buttonTitle,
      isSentByMe: true,
      messageType: 'interactive',
    );

    final contactId = _selectedContact!.id;
    _messagesByContact[contactId] = _messagesByContact[contactId] ?? [];

    // Add to UI
    _messagesByContact[contactId]!.add(displayMessage);

    // Update contact's last message
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        lastMessage: buttonTitle,
        lastMessageTime: displayMessage.timestamp,
      );
    }

    notifyListeners();

    try {
      // Send in WhatsApp webhook format for button reply
      final payload = {
        "object": "whatsapp_business_account",
        "entry": [
          {
            "id": contactId,
            "changes": [
              {
                "value": {
                  "messaging_product": "whatsapp",
                  "metadata": {
                    "display_phone_number": _selectedContact!.phoneNumber,
                    "phone_number_id": contactId
                  },
                  "contacts": [
                    {
                      "profile": {"name": _selectedContact!.name},
                      "wa_id": _selectedContact!.phoneNumber
                    }
                  ],
                  "messages": [
                    {
                      "from": _selectedContact!.phoneNumber,
                      "id": "wamid.${DateTime.now().millisecondsSinceEpoch}",
                      "timestamp":
                          "${DateTime.now().millisecondsSinceEpoch ~/ 1000}",
                      "type": "interactive",
                      "interactive": {
                        "type": "button_reply",
                        "button_reply": {"id": buttonId, "title": buttonTitle}
                      }
                    }
                  ]
                },
                "field": "messages"
              }
            ]
          }
        ]
      };

      final message = Message(
        content: buttonTitle,
        isSentByMe: true,
      );

      await _repository.sendMessage(message, customPayload: payload);
      await _saveMessagesForContact(contactId);
      await _saveContacts();

      return true;
    } catch (e) {
      _messagesByContact[contactId]!.remove(displayMessage);
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Sends an interactive list reply.
  Future<bool> sendListReply(String rowId, String rowTitle) async {
    if (_selectedContact == null) return false;

    _clearError();

    // Create message with list reply format
    final displayMessage = Message(
      content: rowTitle,
      isSentByMe: true,
      messageType: 'interactive',
    );

    final contactId = _selectedContact!.id;
    _messagesByContact[contactId] = _messagesByContact[contactId] ?? [];

    // Add to UI
    _messagesByContact[contactId]!.add(displayMessage);

    // Update contact's last message
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        lastMessage: rowTitle,
        lastMessageTime: displayMessage.timestamp,
      );
    }

    notifyListeners();

    try {
      // Send in WhatsApp webhook format for list reply
      final payload = {
        "object": "whatsapp_business_account",
        "entry": [
          {
            "id": contactId,
            "changes": [
              {
                "value": {
                  "messaging_product": "whatsapp",
                  "metadata": {
                    "display_phone_number": _selectedContact!.phoneNumber,
                    "phone_number_id": contactId
                  },
                  "contacts": [
                    {
                      "profile": {"name": _selectedContact!.name},
                      "wa_id": _selectedContact!.phoneNumber
                    }
                  ],
                  "messages": [
                    {
                      "from": _selectedContact!.phoneNumber,
                      "id": "wamid.${DateTime.now().millisecondsSinceEpoch}",
                      "timestamp":
                          "${DateTime.now().millisecondsSinceEpoch ~/ 1000}",
                      "type": "interactive",
                      "interactive": {
                        "type": "list_reply",
                        "list_reply": {"id": rowId, "title": rowTitle}
                      }
                    }
                  ]
                },
                "field": "messages"
              }
            ]
          }
        ]
      };

      final message = Message(
        content: rowTitle,
        isSentByMe: true,
      );

      await _repository.sendMessage(message, customPayload: payload);
      await _saveMessagesForContact(contactId);
      await _saveContacts();

      return true;
    } catch (e) {
      _messagesByContact[contactId]!.remove(displayMessage);
      _setError(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Adds a received message (e.g., from webhook).
  void addReceivedMessage(Message message) {
    if (_selectedContact == null) return;

    final contactId = _selectedContact!.id;
    _messagesByContact[contactId] = _messagesByContact[contactId] ?? [];
    _messagesByContact[contactId]!.add(message.copyWith(isSentByMe: false));

    // Update contact's last message
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
      );
      _saveContacts();
    }

    _saveMessagesForContact(contactId);
    notifyListeners();
  }

  /// Clears all messages for the selected contact.
  void clearMessages() {
    if (_selectedContact == null) return;

    _messagesByContact[_selectedContact!.id] = [];
    _saveMessagesForContact(_selectedContact!.id);
    notifyListeners();
  }

  /// Clears the current error.
  void clearError() {
    _clearError();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _webhookServer?.stop();
    super.dispose();
  }
}
