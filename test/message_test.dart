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

    test('copyWith should create a copy with updated fields', () {
      final original = Message(
        id: '1',
        content: 'Original',
        isSentByMe: true,
      );

      final copy = original.copyWith(content: 'Modified');

      expect(copy.id, '1');
      expect(copy.content, 'Modified');
      expect(copy.isSentByMe, true);
      expect(original.content, 'Original');
    });

    test('equality should work correctly', () {
      final message1 = Message(
        id: '1',
        content: 'Hello',
        isSentByMe: true,
      );
      final message2 = Message(
        id: '1',
        content: 'Hello',
        isSentByMe: true,
      );
      final message3 = Message(
        id: '2',
        content: 'Hello',
        isSentByMe: true,
      );

      expect(message1 == message2, true);
      expect(message1 == message3, false);
    });

    test('hashCode should be consistent with equality', () {
      final message1 = Message(
        id: '1',
        content: 'Hello',
        isSentByMe: true,
      );
      final message2 = Message(
        id: '1',
        content: 'Hello',
        isSentByMe: true,
      );

      expect(message1.hashCode, message2.hashCode);
    });

    test('toString should return readable format', () {
      final message = Message(
        id: '1',
        content: 'Test',
        isSentByMe: true,
      );

      final str = message.toString();

      expect(str.contains('Message'), true);
      expect(str.contains('id: 1'), true);
      expect(str.contains('content: Test'), true);
    });
  });
}
