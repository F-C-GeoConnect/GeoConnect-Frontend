import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// This single page will handle both showing a list of conversations and a single conversation.
class ChatPage extends StatefulWidget {
  // These are optional. If they are null, we show the list of chats.
  // If they are provided, we show the conversation with that user.
  final String? farmerName;
  final String? receiverId;

  const ChatPage({
    super.key,
    this.farmerName,
    this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // This determines if we are showing a single conversation or the list of all chats.
  bool get isConversationView => widget.receiverId != null && widget.farmerName != null;

  @override
  Widget build(BuildContext context) {
    return isConversationView
        ? ConversationView(
            farmerName: widget.farmerName!,
            receiverId: widget.receiverId!,
          )
        : const ChatListView();
  }
}

/// WIDGET: Shows a list of all ongoing conversations.
class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement a real list of conversations.
    // This would involve fetching all unique users the current user has messaged.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          'Your conversations will appear here.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

/// WIDGET: The actual conversation UI for a single chat.
class ConversationView extends StatefulWidget {
  final String farmerName;
  final String receiverId;

  const ConversationView({
    super.key,
    required this.farmerName,
    required this.receiverId,
  });

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final _messageController = TextEditingController();
  final SupabaseClient _client = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  late StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _messagesStream = _getMessagesStream(widget.receiverId);
    _messagesSubscription = _messagesStream.listen(
      (_) {},
      onError: (error) {
        print("Stream error: $error");
      },
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  // Gets a real-time stream of messages for the conversation.
  Stream<List<Map<String, dynamic>>> _getMessagesStream(String otherUserId) {
    final currentUserId = _client.auth.currentUser!.id;
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps
            .where((map) =>
                (map['sender_id'] == currentUserId && map['receiver_id'] == otherUserId) ||
                (map['sender_id'] == otherUserId && map['receiver_id'] == currentUserId))
            .toList());
  }

  // Sends a message to Supabase.
  Future<void> _sendMessage() async {
    final content = _messageController.text;
    if (content.trim().isEmpty) return;

    final senderId = _client.auth.currentUser!.id;
    await _client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': widget.receiverId,
      'content': content.trim(),
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmerName),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hello!'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == _client.auth.currentUser!.id;
                    return MessageBubble(isMe: isMe, message: message);
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// WIDGET: A message bubble for displaying a single chat message.
class MessageBubble extends StatelessWidget {
  final bool isMe;
  final Map<String, dynamic> message;

  const MessageBubble({super.key, required this.isMe, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(message['content'] as String? ?? ''),
      ),
    );
  }
}
