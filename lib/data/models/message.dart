/// Message model representing a chat message.
///
/// Follows the repository pattern and provides JSON serialization methods.
class Message {
  final String? id;
  final String content;
  final bool isSentByMe;
  final DateTime timestamp;
  final Map<String, dynamic>? interactive;
  final String? messageType; // 'text', 'interactive'

  Message({
    this.id,
    required this.content,
    required this.isSentByMe,
    DateTime? timestamp,
    this.interactive,
    this.messageType,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if this is an interactive message
  bool get isInteractive => messageType == 'interactive' && interactive != null;

  /// Check if interactive message has buttons
  bool get hasButtons => isInteractive && interactive!['type'] == 'button';

  /// Check if interactive message is a list
  bool get isList => isInteractive && interactive!['type'] == 'list';

  /// Get interactive buttons
  List<Map<String, dynamic>> get buttons {
    if (!hasButtons) return [];
    final action = interactive!['action'] as Map<String, dynamic>?;
    if (action == null) return [];
    return List<Map<String, dynamic>>.from(action['buttons'] ?? []);
  }

  /// Get interactive body text
  String get interactiveBodyText {
    if (!isInteractive) return content;
    final body = interactive!['body'] as Map<String, dynamic>?;
    return body?['text'] as String? ?? content;
  }

  /// Creates a Message from JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      isSentByMe:
          json['isSentByMe'] as bool? ?? json['is_sent_by_me'] as bool? ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Converts Message to JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'isSentByMe': isSentByMe,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Converts Message to WhatsApp Business API webhook format.
  ///
  /// This format mimics the structure sent by WhatsApp webhooks.
  Map<String, dynamic> toWhatsAppWebhookJson({
    String? phoneNumberId,
    String? displayPhoneNumber,
    String? waId,
    String? profileName,
  }) {
    // Generate a unique message ID if not provided
    final messageId = id ?? 'wamid.${DateTime.now().millisecondsSinceEpoch}';

    // Convert timestamp to Unix timestamp (seconds)
    final unixTimestamp =
        (timestamp.millisecondsSinceEpoch / 1000).floor().toString();

    return {
      'object': 'whatsapp_business_account',
      'entry': [
        {
          'id': phoneNumberId ?? '1234567898765432',
          'changes': [
            {
              'value': {
                'messaging_product': 'whatsapp',
                'metadata': {
                  'display_phone_number': displayPhoneNumber ?? '551198765432',
                  'phone_number_id': phoneNumberId ?? '1234567898765432',
                },
                'contacts': [
                  {
                    'profile': {
                      'name': profileName ?? 'User',
                    },
                    'wa_id': waId ?? '551198765432',
                  }
                ],
                'messages': [
                  {
                    'from': waId ?? '551198765432',
                    'id': messageId,
                    'timestamp': unixTimestamp,
                    'text': {
                      'body': content,
                    },
                    'type': 'text',
                  }
                ],
              },
              'field': 'messages',
            }
          ],
        }
      ],
    };
  }

  /// Creates a copy with updated fields.
  Message copyWith({
    String? id,
    String? content,
    bool? isSentByMe,
    DateTime? timestamp,
    Map<String, dynamic>? interactive,
    String? messageType,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      timestamp: timestamp ?? this.timestamp,
      interactive: interactive ?? this.interactive,
      messageType: messageType ?? this.messageType,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, isSentByMe: $isSentByMe, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.content == content &&
        other.isSentByMe == isSentByMe;
  }

  @override
  int get hashCode => Object.hash(id, content, isSentByMe);
}
