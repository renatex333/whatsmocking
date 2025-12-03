/// Model representing a contact/phone number in the chat system.
///
/// Each contact has its own conversation thread with separate message history.
class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    DateTime? createdAt,
    this.lastMessage,
    this.lastMessageTime,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a Contact from JSON (for SharedPreferences).
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
    );
  }

  /// Converts Contact to JSON (for SharedPreferences).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }

  /// Creates a copy with updated fields.
  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phoneNumber: $phoneNumber)';
  }
}
