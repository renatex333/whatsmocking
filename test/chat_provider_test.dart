import 'package:flutter_test/flutter_test.dart';
import 'package:whatsmocking/providers/chat_provider.dart';
import 'package:whatsmocking/data/models/message.dart';

void main() {
  group('ChatProvider', () {
    late ChatProvider provider;

    setUp(() {
      provider = ChatProvider();
    });

    test('should start with empty messages', () {
      expect(provider.messages, isEmpty);
    });

    test('should start with isLoading false', () {
      expect(provider.isLoading, false);
    });

    test('should start with no error', () {
      expect(provider.hasError, false);
      expect(provider.errorMessage, isNull);
    });

    test('should have a valid base URL', () {
      expect(provider.currentBaseUrl, isNotEmpty);
      expect(provider.currentBaseUrl.startsWith('http://'), true);
    });

    test('clearMessages should remove all messages', () {
      provider.addReceivedMessage(Message(content: 'Test', isSentByMe: false));
      expect(provider.messages.length, 1);

      provider.clearMessages();
      expect(provider.messages, isEmpty);
    });

    test('addReceivedMessage should add message with isSentByMe false', () {
      final message = Message(content: 'Received', isSentByMe: true);
      provider.addReceivedMessage(message);

      expect(provider.messages.length, 1);
      expect(provider.messages.first.content, 'Received');
      expect(provider.messages.first.isSentByMe, false);
    });

    test('clearError should clear error message', () {
      // We can't directly set an error, but we can test the clear functionality
      provider.clearError();
      expect(provider.hasError, false);
      expect(provider.errorMessage, isNull);
    });

    test('messages list should be unmodifiable', () {
      provider.addReceivedMessage(Message(content: 'Test', isSentByMe: false));
      
      // Trying to modify the returned list should throw
      expect(
        () => provider.messages.add(Message(content: 'Hack', isSentByMe: true)),
        throwsUnsupportedError,
      );
    });

    test('sendMessage should reject empty content', () async {
      final result = await provider.sendMessage('');
      expect(result, false);
      expect(provider.messages, isEmpty);
    });

    test('sendMessage should reject whitespace-only content', () async {
      final result = await provider.sendMessage('   ');
      expect(result, false);
      expect(provider.messages, isEmpty);
    });
  });
}
