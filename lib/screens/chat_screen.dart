import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../data/models/message.dart';
import '../widgets/conversations_panel.dart';

/// Main chat screen with conversations panel and message list.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await context.read<ChatProvider>().sendMessage(text);

    if (success) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const ConversationsPanel(),
          Expanded(child: _buildChatArea()),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.selectedContact == null) {
          return _buildNoContactSelected();
        }

        return Container(
          decoration: const BoxDecoration(color: Color(0xFFECE5DD)),
          child: Column(
            children: [
              _buildChatHeader(provider),
              _buildErrorBanner(),
              Expanded(child: _buildMessagesList(provider)),
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoContactSelected() {
    return Container(
      color: const Color(0xFFECE5DD),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a contact to start chatting',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('or add a new contact',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(ChatProvider provider) {
    final contact = provider.selectedContact!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF075E54),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 20,
            child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(contact.phoneNumber,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(provider.currentBaseUrl,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
              Row(
                children: [
                  Icon(
                      provider.isServerRunning
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 8,
                      color: provider.isServerRunning
                          ? Colors.greenAccent
                          : Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                      provider.isServerRunning
                          ? ':${provider.serverPort}'
                          : 'Offline',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => provider.clearMessages(),
              tooltip: 'Clear Chat'),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (!provider.hasError) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.red.shade100,
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(provider.errorMessage ?? 'An error occurred',
                      style: const TextStyle(color: Colors.red))),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => provider.clearError(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(ChatProvider provider) {
    if (provider.isLoading && provider.messages.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF075E54)));
    }
    if (provider.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Send a message to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) =>
          MessageBubble(message: provider.messages[index]),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFFF0F0F0),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25)),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12)),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF075E54),
              child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSentByMe;
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            top: 4, bottom: 4, left: isSent ? 64 : 0, right: isSent ? 0 : 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSent ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSent ? 16 : 4),
              bottomRight: Radius.circular(isSent ? 4 : 16)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isInteractive && message.hasButtons)
              _buildInteractiveButtons(context)
            else if (message.isInteractive && message.isList)
              _buildInteractiveList(context)
            else
              SelectableText(message.content,
                  style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(message.timestamp),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all, size: 16, color: Colors.blue.shade400),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(message.interactiveBodyText,
            style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        ...message.buttons.map((button) {
          final reply = button['reply'] as Map<String, dynamic>?;
          if (reply == null) return const SizedBox.shrink();
          final title = reply['title'] as String? ?? '';
          final id = reply['id'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) => OutlinedButton(
                onPressed: () => provider.sendButtonReply(id, title),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF075E54),
                    side:
                        const BorderSide(color: Color(0xFF075E54), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radio_button_unchecked, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInteractiveList(BuildContext context) {
    final interactive = message.interactive!;
    final header = interactive['header'] as Map<String, dynamic>?;
    final body = interactive['body'] as Map<String, dynamic>?;
    final action = interactive['action'] as Map<String, dynamic>?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null && header['text'] != null) ...[
          Row(
            children: [
              const Icon(Icons.list_alt, size: 18, color: Color(0xFF075E54)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(header['text'] as String,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (body != null && body['text'] != null)
          SelectableText(body['text'] as String,
              style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        if (action != null && action['button'] != null)
          Consumer<ChatProvider>(
            builder: (context, provider, _) => OutlinedButton.icon(
              onPressed: () => _showListOptions(
                  context, action['sections'] as List, provider),
              icon: const Icon(Icons.list, size: 18),
              label: Text(action['button'] as String),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF075E54),
                  side: const BorderSide(color: Color(0xFF075E54), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
        const SizedBox(height: 8),
        if (action != null && action['sections'] != null) ...[
          const Divider(),
          ..._buildSectionsPreviews(action['sections'] as List),
        ],
      ],
    );
  }

  void _showListOptions(
      BuildContext context, List sections, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section =
                      sections[sectionIndex] as Map<String, dynamic>;
                  final title = section['title'] as String?;
                  final rows = section['rows'] as List? ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ),
                      ...rows.map((row) {
                        final rowMap = row as Map<String, dynamic>;
                        final rowId = rowMap['id'] as String? ?? '';
                        final rowTitle = rowMap['title'] as String? ?? '';
                        final rowDescription = rowMap['description'] as String?;
                        return ListTile(
                          leading: const Icon(Icons.circle_outlined,
                              color: Color(0xFF075E54)),
                          title: Text(rowTitle),
                          subtitle: rowDescription != null
                              ? Text(rowDescription,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                          onTap: () {
                            provider.sendListReply(rowId, rowTitle);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSectionsPreviews(List sections) {
    final widgets = <Widget>[];
    for (var section in sections) {
      final sectionMap = section as Map<String, dynamic>;
      final title = sectionMap['title'] as String?;
      final rows = sectionMap['rows'] as List?;
      if (title != null) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF075E54))),
        ));
      }
      if (rows != null) {
        for (var row in rows) {
          final rowMap = row as Map<String, dynamic>;
          final rowTitle = rowMap['title'] as String?;
          final description = rowMap['description'] as String?;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rowTitle != null)
                          Text(rowTitle, style: const TextStyle(fontSize: 13)),
                        if (description != null)
                          Text(description,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
