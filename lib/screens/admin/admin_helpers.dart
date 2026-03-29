import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHelpers {
  static final NumberFormat currency =
  NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  static final Map<String, _AdminCacheEntry<dynamic>> _cache = {};

  static Future<T> cachedLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration ttl = const Duration(seconds: 45),
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && now.isBefore(cached.expiresAt)) {
        return cached.value as T;
      }
    }

    final value = await loader();
    _cache[key] = _AdminCacheEntry<dynamic>(value, now.add(ttl));
    return value;
  }

  static void invalidateCache(String key) {
    _cache.remove(key);
  }

  static void invalidateCachePrefix(String prefix) {
    final keys = _cache.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      _cache.remove(key);
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':          return Colors.orange;
      case 'accepted':         return Colors.blue;
      case 'shipped':          return Colors.purple;
      case 'out_for_delivery': return Colors.indigo;
      case 'completed':        return Colors.green;
      case 'cancelled':        return Colors.red;
      default:                 return Colors.grey;
    }
  }

  static String timeAgo(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inDays > 0)    return '${diff.inDays}d ago';
    if (diff.inHours > 0)   return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  static Future<bool> confirmDialog(
      BuildContext context,
      String title,
      String content, {
        required String confirmLabel,
        required Color confirmColor,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  static String friendlyError(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
    if (error is PostgrestException) {
      // Avoid leaking raw DB errors to end users.
      return 'Request could not be completed. Please check permissions and try again.';
    }
    if (error is StorageException) {
      return 'File operation failed. Please retry in a moment.';
    }
    if (error is AuthException) {
      return 'Session expired. Please sign in again.';
    }
    return fallback;
  }

  static void showError(
    BuildContext context,
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    debugPrint('Admin action error: $error');
    showSnack(context, friendlyError(error, fallback: fallback), error: true);
  }

  static void showSnack(BuildContext context, String msg,
      {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

class _AdminCacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _AdminCacheEntry(this.value, this.expiresAt);
}
