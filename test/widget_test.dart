import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:whatsmocking/main.dart';

void main() {
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

  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica se o app construiu sem erros
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Should show conversations panel', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica se há um botão de adicionar
    expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
  });

  testWidgets('App title should be correct', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica o título do app
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'WhatsMocking');
  });
}
