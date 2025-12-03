import 'package:flutter_test/flutter_test.dart';
import 'package:whatsmocking/data/models/message.dart';

void main() {
  group('Message Model', () {
    test('should create a Message with required fields', () {
      final message = Message(
        content: 'Hello World',
        isSentByMe: true,
      );

      expect(message.content, 'Hello World');
      expect(message.isSentByMe, true);
      expect(message.id, isNull);
      expect(message.timestamp, isNotNull);
    });

    test('should create a Message with all fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final message = Message(
        id: '123',
        content: 'Hello World',
        isSentByMe: false,
        timestamp: timestamp,
      );

      expect(message.id, '123');
      expect(message.content, 'Hello World');
      expect(message.isSentByMe, false);
      expect(message.timestamp, timestamp);
    });

    group('fromJson', () {
      test('should parse JSON with all fields', () {
        final json = {
          'id': '123',
          'content': 'Test message',
          'isSentByMe': true,
          'timestamp': '2024-01-15T10:30:00.000Z',
        };

        final message = Message.fromJson(json);

        expect(message.id, '123');
        expect(message.content, 'Test message');
        expect(message.isSentByMe, true);
        expect(message.timestamp.year, 2024);
      });

      test('should parse JSON with snake_case fields', () {
        final json = {
          'id': '456',
          'message': 'Alternative content field',
          'is_sent_by_me': false,
        };

        final message = Message.fromJson(json);

        expect(message.id, '456');
        expect(message.content, 'Alternative content field');
        expect(message.isSentByMe, false);
      });

      test('should handle missing optional fields', () {
        final json = <String, dynamic>{};

        final message = Message.fromJson(json);

        expect(message.id, isNull);
        expect(message.content, '');
        expect(message.isSentByMe, true);
        expect(message.timestamp, isNotNull);
      });

      test('should handle numeric id', () {
        final json = {
          'id': 123,
          'content': 'Test',
          'isSentByMe': true,
        };

        final message = Message.fromJson(json);

        expect(message.id, '123');
      });
    });

    group('toJson', () {
      test('should convert Message to JSON with all fields', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        final message = Message(
          id: '123',
          content: 'Hello World',
          isSentByMe: true,
          timestamp: timestamp,
        );

        final json = message.toJson();

        expect(json['id'], '123');
        expect(json['content'], 'Hello World');
        expect(json['isSentByMe'], true);
        expect(json['timestamp'], timestamp.toIso8601String());
      });

      test('should not include id when null', () {
        final message = Message(
          content: 'Test',
          isSentByMe: true,
        );

        final json = message.toJson();

        expect(json.containsKey('id'), false);
        expect(json['content'], 'Test');
      });
    });

    test('should handle interactive messages with buttons', () {
      final message = Message(
        content: 'Choose an option',
        isSentByMe: false,
        messageType: 'interactive',
        interactive: {
          'type': 'button',
          'body': {'text': 'Button message'},
          'action': {
            'buttons': [
              {
                'reply': {'id': 'btn1', 'title': 'Option 1'}
              },
              {
                'reply': {'id': 'btn2', 'title': 'Option 2'}
              },
            ]
          }
        },
      );

      expect(message.isInteractive, true);
      expect(message.hasButtons, true);
      expect(message.isList, false);
      expect(message.buttons.length, 2);
      expect(message.interactiveBodyText, 'Button message');
    });

    test('should handle interactive messages with lists', () {
      final message = Message(
        content: 'Select from list',
        isSentByMe: false,
        messageType: 'interactive',
        interactive: {
          'type': 'list',
          'body': {'text': 'List message'},
          'action': {
            'sections': [
              {
                'title': 'Section 1',
                'rows': [
                  {'id': 'row1', 'title': 'Item 1'},
                ]
              }
            ]
          }
        },
      );

      expect(message.isInteractive, true);
      expect(message.isList, true);
      expect(message.hasButtons, false);
      expect(message.interactiveBodyText, 'List message');
    });

    test('toWhatsAppWebhookJson should format correctly', () {
      final message = Message(
        id: 'msg_123',
        content: 'Hello',
        isSentByMe: true,
      );

      final webhook = message.toWhatsAppWebhookJson(
        waId: '5511999999999',
        displayPhoneNumber: '+55 11 99999-9999',
        profileName: 'John Doe',
      );

      expect(webhook['object'], 'whatsapp_business_account');
      expect(webhook['entry'], isNotNull);
      expect(webhook['entry'][0]['changes'][0]['value']['messages'], isNotNull);

      final webhookMessage =
          webhook['entry'][0]['changes'][0]['value']['messages'][0];
      expect(webhookMessage['from'], '5511999999999');
      expect(webhookMessage['text']['body'], 'Hello');
    });
  });
}
