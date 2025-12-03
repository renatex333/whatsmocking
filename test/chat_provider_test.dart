import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:whatsmocking/providers/chat_provider.dart';
import 'package:whatsmocking/data/models/message.dart';

void main() {
  // Carrega variáveis de ambiente antes de todos os testes
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock do .env para testes
    dotenv.testLoad(fileInput: '''
APP_SECRET=test_secret_key
API_PORT=8080
API_ENDPOINT=/webhook
SERVER_PORT=9090
SERVER_ENDPOINT=/messages
''');
  });

  group('ChatProvider', () {
    late ChatProvider provider;

    setUp(() {
      provider = ChatProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('should start with empty contacts', () {
      expect(provider.contacts, isEmpty);
    });

    test('should start with no selected contact', () {
      expect(provider.selectedContact, isNull);
    });

    test('should start with empty messages when no contact selected', () {
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

    group('Contact Management', () {
      test('addContact should add new contact', () async {
        await provider.addContact('John Doe', '+5511999999999');

        expect(provider.contacts.length, 1);
        expect(provider.contacts.first.name, 'John Doe');
        expect(provider.contacts.first.phoneNumber, '+5511999999999');
      });

      test('selectContact should set selected contact', () async {
        await provider.addContact('John', '+5511999999999');
        final contact = provider.contacts.first;

        provider.selectContact(contact);

        expect(provider.selectedContact, isNotNull);
        expect(provider.selectedContact?.id, contact.id);
      });

      test('removeContact should delete contact', () async {
        await provider.addContact('John', '+5511999999999');
        final contact = provider.contacts.first;

        try {
          await provider.removeContact(contact.id);
        } catch (e) {
          // Ignora erro de SharedPreferences em testes
        }

        expect(provider.contacts, isEmpty);
      });

      test('updateContact should modify contact data', () async {
        await provider.addContact('John', '+5511999999999');
        final contact = provider.contacts.first;

        await provider.updateContact(contact.id, 'Jane', '+5511888888888');

        expect(provider.contacts.first.name, 'Jane');
        expect(provider.contacts.first.phoneNumber, '+5511888888888');
      });
    });

    group('Message Management', () {
      test('messages should return empty list when no contact selected', () {
        expect(provider.messages, isEmpty);
      });

      test('clearMessages should remove messages for selected contact',
          () async {
        await provider.addContact('John', '+5511999999999');
        provider.selectContact(provider.contacts.first);

        provider
            .addReceivedMessage(Message(content: 'Test', isSentByMe: false));
        expect(provider.messages.length, 1);

        provider.clearMessages();
        expect(provider.messages, isEmpty);
      });

      test('addReceivedMessage should add message with isSentByMe false',
          () async {
        await provider.addContact('John', '+5511999999999');
        provider.selectContact(provider.contacts.first);

        final message = Message(content: 'Received', isSentByMe: true);
        provider.addReceivedMessage(message);

        expect(provider.messages.length, 1);
        expect(provider.messages.first.content, 'Received');
        expect(provider.messages.first.isSentByMe, false);
      });
    });

    group('Error Handling', () {
      test('clearError should clear error message', () {
        provider.clearError();
        expect(provider.hasError, false);
        expect(provider.errorMessage, isNull);
      });

      test('sendMessage should reject empty content', () async {
        await provider.addContact('John', '+5511999999999');
        provider.selectContact(provider.contacts.first);

        final result = await provider.sendMessage('');
        expect(result, false);
        expect(provider.messages, isEmpty);
      });

      test('sendMessage should reject whitespace-only content', () async {
        await provider.addContact('John', '+5511999999999');
        provider.selectContact(provider.contacts.first);

        final result = await provider.sendMessage('   ');
        expect(result, false);
        expect(provider.messages, isEmpty);
      });

      test('sendMessage should reject when no contact selected', () async {
        final result = await provider.sendMessage('Hello');
        expect(result, false);
      });
    });

    test('messages list should be unmodifiable', () async {
      await provider.addContact('John', '+5511999999999');
      provider.selectContact(provider.contacts.first);
      provider.addReceivedMessage(Message(content: 'Test', isSentByMe: false));

      expect(
        () => provider.messages.add(Message(content: 'Hack', isSentByMe: true)),
        throwsUnsupportedError,
      );
    });
  });
}
