import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    final userId = _supabase.auth.currentUser?.id;
    
    if (userId != null) {
      _notificationsStream = _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } else {
      _notificationsStream = Stream.value([]);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all read', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification['is_read'] ?? false;
              final String type = notification['type'] ?? 'general';

              return Dismissible(
                key: Key(notification['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _deleteNotification(notification['id']),
                child: ListTile(
                  onTap: () {
                    if (!isRead) _markAsRead(notification['id']);
                    _handleNotificationTap(type, notification['related_id']);
                  },
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  leading: _getNotificationIcon(type, isRead),
                  title: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification['created_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  trailing: !isRead 
                    ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))
                    : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type, bool isRead) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'order':
        iconData = Icons.shopping_bag_outlined;
        color = Colors.blue;
        break;
      case 'delivery':
        iconData = Icons.local_shipping_outlined;
        color = Colors.orange;
        break;
      case 'selling':
        iconData = Icons.sell_outlined;
        color = Colors.green;
        break;
      case 'availability':
        iconData = Icons.check_circle_outline;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.notifications_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _handleNotificationTap(String type, dynamic relatedId) {
    // TODO: Add actual navigation when these screens are built
    switch (type) {
      case 'order':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetails(id: relatedId)));
        break;
      case 'selling':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryPage()));
        break;
      case 'availability':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductProfile(id: relatedId)));
        break;
      case 'delivery':
        // Navigator.push(context, MaterialPageRoute(builder: (context) => MapTracking(id: relatedId)));
        break;
    }
  }
}
