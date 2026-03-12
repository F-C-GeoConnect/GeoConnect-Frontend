import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminHelpers {
  static final NumberFormat currency =
  NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

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