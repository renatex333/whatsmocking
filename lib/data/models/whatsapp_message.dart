/// Model representing a WhatsApp message received from the API.
///
/// Supports different message types: text, interactive (buttons/lists).
class WhatsAppMessage {
  final String to;
  final String type;
  final TextContent? text;
  final InteractiveContent? interactive;
  final DateTime timestamp;

  WhatsAppMessage({
    required this.to,
    required this.type,
    this.text,
    this.interactive,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a WhatsAppMessage from the API response format.
  factory WhatsAppMessage.fromApiResponse(Map<String, dynamic> json) {
    final type = json['type'] as String;

    TextContent? text;
    InteractiveContent? interactive;

    if (type == 'text' && json['text'] != null) {
      text = TextContent.fromJson(json['text'] as Map<String, dynamic>);
    } else if (type == 'interactive' && json['interactive'] != null) {
      interactive = InteractiveContent.fromJson(
          json['interactive'] as Map<String, dynamic>);
    }

    return WhatsAppMessage(
      to: json['to'] as String,
      type: type,
      text: text,
      interactive: interactive,
    );
  }

  /// Gets the display text for the message.
  String getDisplayText() {
    if (text != null) {
      return text!.body;
    } else if (interactive != null) {
      return interactive!.getDisplayText();
    }
    return '[Unknown message type: $type. To support this project, please open an issue on GitHub.]';
  }

  /// Checks if this is a text message.
  bool get isText => type == 'text';

  /// Checks if this is an interactive message.
  bool get isInteractive => type == 'interactive';
}

/// Text message content.
class TextContent {
  final String body;

  TextContent({required this.body});

  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(body: json['body'] as String);
  }
}

/// Interactive message content (buttons or list).
class InteractiveContent {
  final String type; // "button" or "list"
  final Map<String, dynamic>? header;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? action;

  InteractiveContent({
    required this.type,
    this.header,
    this.body,
    this.action,
  });

  factory InteractiveContent.fromJson(Map<String, dynamic> json) {
    return InteractiveContent(
      type: json['type'] as String,
      header: json['header'] as Map<String, dynamic>?,
      body: json['body'] as Map<String, dynamic>?,
      action: json['action'] as Map<String, dynamic>?,
    );
  }

  /// Gets display text for interactive messages.
  String getDisplayText() {
    final buffer = StringBuffer();

    // Add header if present
    if (header != null && header!['text'] != null) {
      buffer.writeln('📋 ${header!['text']}');
      buffer.writeln();
    }

    // Add body text
    if (body != null && body!['text'] != null) {
      buffer.writeln(body!['text']);
    }

    // Add buttons or list items
    if (action != null) {
      buffer.writeln();

      if (type == 'button') {
        // Display buttons
        final buttons = action!['buttons'] as List?;
        if (buttons != null) {
          buffer.writeln('🔘 Buttons:');
          for (var button in buttons) {
            final reply = button['reply'] as Map<String, dynamic>?;
            if (reply != null) {
              buffer.writeln('  • ${reply['title']}');
            }
          }
        }
      } else if (type == 'list') {
        // Display list button
        final buttonText = action!['button'] as String?;
        if (buttonText != null) {
          buffer.writeln('📝 $buttonText');
        }

        // Display sections
        final sections = action!['sections'] as List?;
        if (sections != null) {
          for (var section in sections) {
            final sectionTitle = section['title'] as String?;
            if (sectionTitle != null) {
              buffer.writeln('\n  $sectionTitle:');
            }

            final rows = section['rows'] as List?;
            if (rows != null) {
              for (var row in rows) {
                buffer.write('    • ${row['title']}');
                if (row['description'] != null) {
                  buffer.write(' - ${row['description']}');
                }
                buffer.writeln();
              }
            }
          }
        }
      }
    }

    return buffer.toString().trim();
  }

  /// Checks if this is a button interactive message.
  bool get isButton => type == 'button';

  /// Checks if this is a list interactive message.
  bool get isList => type == 'list';
}
