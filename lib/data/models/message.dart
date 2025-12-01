/// Message model representing a chat message.
/// 
/// Follows the repository pattern and provides JSON serialization methods.
class Message {
  final String? id;
  final String content;
  final bool isSentByMe;
  final DateTime timestamp;

  Message({
    this.id,
    required this.content,
    required this.isSentByMe,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a Message from JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      isSentByMe: json['isSentByMe'] as bool? ?? json['is_sent_by_me'] as bool? ?? true,
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

  /// Creates a copy with updated fields.
  Message copyWith({
    String? id,
    String? content,
    bool? isSentByMe,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      timestamp: timestamp ?? this.timestamp,
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
