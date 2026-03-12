// lib/screens/admin/tabs/admin_broadcast_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_helpers.dart';
import '../widgets/admin_widgets.dart';

class AdminBroadcastTab extends StatefulWidget {
  const AdminBroadcastTab({super.key});

  @override
  State<AdminBroadcastTab> createState() => _AdminBroadcastTabState();
}

class _AdminBroadcastTabState extends State<AdminBroadcastTab> {
  final _supabase     = Supabase.instance.client;
  final _titleCtrl    = TextEditingController();
  final _messageCtrl  = TextEditingController();
  String _selectedType = 'general';
  bool _sending        = false;

  static const _types = [
    'general', 'order', 'delivery', 'selling', 'availability'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final msg   = _messageCtrl.text.trim();

    if (title.isEmpty || msg.isEmpty) {
      AdminHelpers.showSnack(context, 'Fill in both title and message.',
          error: true);
      return;
    }

    final ok = await AdminHelpers.confirmDialog(
      context,
      'Send Broadcast',
      'Send "$title" to ALL users in the system?',
      confirmLabel: 'Send',
      confirmColor: Colors.red,
    );
    if (!ok) return;

    setState(() => _sending = true);
    try {
      final users =
      await _supabase.from('profiles').select('id');
      final batch = (users as List)
          .map((u) => {
        'user_id':  u['id'],
        'title':    title,
        'message':  msg,
        'type':     _selectedType,
        'is_read':  false,
      })
          .toList();

      for (int i = 0; i < batch.length; i += 50) {
        final end = (i + 50).clamp(0, batch.length);
        await _supabase.from('notifications').insert(batch.sublist(i, end));
      }

      if (mounted) {
        AdminHelpers.showSnack(
            context, 'Broadcast sent to ${batch.length} users.');
        _titleCtrl.clear();
        _messageCtrl.clear();
        setState(() {});  // rebuild recent list
      }
    } catch (e) {
      if (mounted) {
        AdminHelpers.showSnack(context, 'Error: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200)),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This will send a notification to ALL users in the system.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const AdminSectionTitle('Notification Type'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types
                .map((t) => ChoiceChip(
              label: Text(t.toUpperCase(),
                  style: const TextStyle(fontSize: 11)),
              selected: _selectedType == t,
              selectedColor: Colors.red.shade100,
              backgroundColor: Colors.grey.shade100,
              onSelected: (_) =>
                  setState(() => _selectedType = t),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),

          const AdminSectionTitle('Compose Message'),
          const SizedBox(height: 10),

          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.message)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _sending
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sending…' : 'Send to All Users',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: _sending ? null : _send,
            ),
          ),
          const SizedBox(height: 32),

          const AdminSectionTitle('Recent Notifications'),
          const SizedBox(height: 12),
          _buildRecentNotifications(),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }
        final notifs = snapshot.data ?? [];
        if (notifs.isEmpty) {
          return const AdminEmptyState(
              message: 'No notifications yet',
              icon: Icons.notifications_off);
        }
        return Column(
          children: notifs
              .map((n) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.grey.shade100)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      shape: BoxShape.circle),
                  child: const Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: Colors.red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(n['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(n['message'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(AdminHelpers.timeAgo(n['created_at']),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ))
              .toList(),
        );
      },
    );
  }
}