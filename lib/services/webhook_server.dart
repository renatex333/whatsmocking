import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../data/models/whatsapp_message.dart';

/// HTTP server to receive webhook responses from the API.
///
/// This server listens for POST requests from your backend
/// with WhatsApp message responses.
class WebhookServer {
  HttpServer? _server;
  final int port;
  final StreamController<WhatsAppMessage> _messageController =
      StreamController.broadcast();

  WebhookServer({required this.port});

  /// Stream of incoming messages from the API.
  Stream<WhatsAppMessage> get messageStream => _messageController.stream;

  /// Starts the HTTP server to receive webhooks.
  Future<void> start() async {
    // Web platform doesn't support HTTP servers
    if (kIsWeb) {
      print('⚠️ Webhook server not available on Web platform');
      print('💡 Use desktop (Linux/Windows/macOS) for full webhook functionality');
      return;
    }

    final router = Router();

    // Health check endpoint
    router.get('/health', (Request request) {
      return Response.ok(jsonEncode({'status': 'ok', 'port': port}));
    });

    // Endpoint to receive WhatsApp message responses (matching API URL pattern)
    router.post('/messages', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload) as Map<String, dynamic>;

        // Parse the incoming message
        final message = WhatsAppMessage.fromApiResponse(data);

        // Emit to stream
        _messageController.add(message);

        return Response.ok(jsonEncode({'status': 'received'}));
      } catch (e) {
        print('Error processing incoming message: $e');
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
        );
      }
    });

    // Default handler
    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Not found');
    });

    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      print('🚀 Webhook server running on http://localhost:$port');
      print('📥 Ready to receive messages at http://localhost:$port/messages');
    } catch (e) {
      print('❌ Failed to start server: $e');
      rethrow;
    }
  }

  /// Stops the HTTP server.
  Future<void> stop() async {
    await _server?.close(force: true);
    await _messageController.close();
    print('🛑 Webhook server stopped');
  }

  bool get isRunning => _server != null;
}
