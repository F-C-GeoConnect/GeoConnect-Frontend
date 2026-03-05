import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';


/// BRIDGE CLASS: This ensures your existing navigation from main.dart and product_profile.dart still works.
class ChatPage extends StatelessWidget {
  final String? farmerName;
  final String? receiverId;

  const ChatPage({super.key, this.farmerName, this.receiverId});

  @override
  Widget build(BuildContext context) {
    if (receiverId != null && farmerName != null) {
      // If we have a receiver, go to the specific room
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return const Scaffold(body: Center(child: Text('Please log in')));

      final currentUserId = currentUser.id;
      final ids = [currentUserId, receiverId!];
      ids.sort();
      final conversationId = ids.join('_');

      return ChatRoomPage(
        conversationId: conversationId,
        productId: 'general',
        otherUserId: receiverId!,
        otherUserName: farmerName!,
        productImageUrl: '', // Placeholder
      );
    }

    return const ChatListView();
  }
}

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), backgroundColor: Colors.white, elevation: 1),
      body: const Center(
        child: Text('Your conversations will appear here.', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String conversationId;
  final String productId;
  final String otherUserId;
  final String otherUserName;
  final String productImageUrl;

  const ChatRoomPage({
    super.key,
    required this.conversationId,
    required this.productId,
    required this.otherUserId,
    required this.otherUserName,
    required this.productImageUrl,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isSending = false;
  bool _isUploading = false;
  // Track last message count to avoid scrolling/animating on every rebuild
  int _lastMessageCount = 0;

  // Track whether there is text in the input without rebuilding on every char
  bool _hasText = false;
  late final VoidCallback _messageListener;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();

    // Use a dedicated listener so we don't call setState on every character unnecessarily.
    _messageListener = () {
      final has = _messageController.text.trim().isNotEmpty;
      if (has != _hasText) {
        if (mounted) setState(() => _hasText = has);
      }
    };
    _messageController.addListener(_messageListener);
  }

  @override
  void dispose() {
    _messageController.removeListener(_messageListener);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Auto-scroll to bottom - FIXED: In a normal ListView, maxScrollExtent is the bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final current = _scrollController.position.pixels;
        if ((max - current) > 5.0) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', widget.conversationId)
          .eq('receiver_id', uid);
    } catch (e) {
      debugPrint('Read status error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': uid,
        'receiver_id': widget.otherUserId,
        'content': text,
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$uid/$fileName';

      await _supabase.storage.from('chat_images').upload(filePath, file);
      final imageUrl = _supabase.storage.from('chat_images').getPublicUrl(filePath);

      await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': uid,
        'receiver_id': widget.otherUserId,
        'content': 'Sent an image',
        'image_url': imageUrl,
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('bucket not found')) {
          msg = 'Error: Please create the "chat_images" bucket in Supabase Storage.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUserId;
    if (uid == null) return const Scaffold(body: Center(child: Text('Session expired. Please log in.')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            if (widget.productImageUrl.isNotEmpty)
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.productImageUrl))
            else
              const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.otherUserName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('conversation_id', widget.conversationId)
                  .order('created_at', ascending: false) // load newest first from server
                  .limit(200), // keep stream bounded to recent messages
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Stream Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Reverse the received list so UI shows oldest -> newest
                final raw = snapshot.data!;
                final messages = List<Map<String, dynamic>>.from(raw.reversed);

                // AUTO-SCROLL logic: only scroll when the message count changes
                // This avoids calling animateTo on every build which can cause jank.
                if (messages.length != _lastMessageCount) {
                  // schedule scroll after frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _scrollToBottom();
                  });
                  _lastMessageCount = messages.length;
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false, // Normal list (oldest at top)
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => MessageBubble(
                    message: messages[index],
                    isMe: messages[index]['sender_id'] == uid,
                  ),
                );
              },
            ),
          ),
          if (_isUploading) const LinearProgressIndicator(color: Color(0xFF2E7D32)),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: _isUploading ? null : _sendImage),
            Expanded(
              child: TextField(
                controller: _messageController,
                // onChanged replaced by listener to reduce rebuilds
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: (!_hasText || _isSending) ? Colors.grey : const Color(0xFF2E7D32)),
              onPressed: (!_hasText || _isSending) ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final imageUrl = message['image_url'];

    String timeString = '--:--';
    if (message['created_at'] != null) {
      try {
        final DateTime createdAt = DateTime.parse(message['created_at']).toLocal();
        timeString = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        debugPrint('Time parse error: $e');
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF2E7D32) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 200,
                      placeholder: (c, u) => const SizedBox(width: 200, height: 150, child: Center(child: CircularProgressIndicator())),
                      errorWidget: (c, u, e) => const Icon(Icons.error),
                    ),
                  ),
                if (message['content'] != null && message['content'] != 'Sent an image')
                  Text(
                    message['content'],
                    style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              timeString,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}