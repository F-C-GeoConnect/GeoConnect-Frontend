import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_helpers.dart';
import '../widgets/admin_widgets.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final _supabase = Supabase.instance.client;
  String _statusFilter = 'all';
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  static const _statuses = [
    'all', 'pending', 'accepted', 'shipped',
    'out_for_delivery', 'completed', 'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('orders')
          .select('*, items')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _orders  = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Orders fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'all') return _orders;
    return _orders.where((o) => o['status'] == _statusFilter).toList();
  }

  Future<void> _updateStatus(dynamic orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      AdminHelpers.showSnack(context, 'Order updated to $newStatus.');
      _fetchOrders();
    } catch (e) {
      AdminHelpers.showSnack(context, 'Error: $e', error: true);
    }
  }

  Future<void> _deleteOrder(dynamic orderId) async {
    final ok = await AdminHelpers.confirmDialog(
      context,
      'Delete Order',
      'Permanently delete order #$orderId?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (!ok) return;
    try {
      await _supabase.from('orders').delete().eq('id', orderId);
      AdminHelpers.showSnack(context, 'Order deleted.');
      _fetchOrders();
    } catch (e) {
      AdminHelpers.showSnack(context, 'Error: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter chips ───────────────────────────────────────────
        Container(
          color: Colors.white,
          padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final color = s == 'all'
                    ? Colors.red
                    : AdminHelpers.statusColor(s);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      s == 'all'
                          ? 'All'
                          : s
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map((w) =>
                      w[0].toUpperCase() + w.substring(1))
                          .join(' '),
                      style: TextStyle(
                          fontSize: 11,
                          color: _statusFilter == s
                              ? color
                              : Colors.black87),
                    ),
                    selected: _statusFilter == s,
                    selectedColor: color.withOpacity(0.15),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(
                        color: _statusFilter == s
                            ? color.withOpacity(0.4)
                            : Colors.transparent),
                    onSelected: (_) =>
                        setState(() => _statusFilter = s),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── List ───────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.red))
              : _filtered.isEmpty
              ? const AdminEmptyState(
              message: 'No orders found',
              icon: Icons.receipt_long)
              : RefreshIndicator(
            onRefresh: _fetchOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (_, i) =>
                  _buildOrderCard(_filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final color  = AdminHelpers.statusColor(status);
    final items  = order['items'] as List<dynamic>? ?? [];
    final amount = num.tryParse(order['total_amount'].toString()) ?? 0;
    // IMPROVED: Shorten long UUID order IDs to prevent overflow
    final shortId = order['id'].toString().length > 12
        ? order['id'].toString().substring(0, 12) + '…'
        : order['id'].toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$shortId',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: color.withOpacity(0.4))),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items list
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      size: 5, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item['product_name'] ?? 'Item'} × ${item['quantity']}',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 8),
            // Time + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(AdminHelpers.timeAgo(order['created_at']),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  AdminHelpers.currency.format(amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // IMPROVED: Wrap prevents overflow for action buttons
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AdminActionButton(
                  label: 'Details',
                  icon: Icons.info_outline,
                  color: Colors.blue,
                  onTap: () => _showDetailsSheet(order),
                ),
                if (status == 'pending')
                  AdminActionButton(
                    label: 'Accept',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onTap: () => _updateStatus(order['id'], 'accepted'),
                  ),
                if (status == 'accepted')
                  AdminActionButton(
                    label: 'Ship',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.purple,
                    onTap: () => _updateStatus(order['id'], 'shipped'),
                  ),
                if (status == 'shipped')
                  AdminActionButton(
                    label: 'Out for Delivery',
                    icon: Icons.delivery_dining,
                    color: Colors.indigo,
                    onTap: () =>
                        _updateStatus(order['id'], 'out_for_delivery'),
                  ),
                if (status == 'out_for_delivery')
                  AdminActionButton(
                    label: 'Complete',
                    icon: Icons.done_all,
                    color: Colors.green,
                    onTap: () =>
                        _updateStatus(order['id'], 'completed'),
                  ),
                if (status != 'completed' && status != 'cancelled')
                  AdminActionButton(
                    label: 'Cancel',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    onTap: () =>
                        _updateStatus(order['id'], 'cancelled'),
                  ),
                AdminActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: Colors.red.shade900,
                  onTap: () => _deleteOrder(order['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final color  = AdminHelpers.statusColor(status);
    final items  = order['items'] as List<dynamic>? ?? [];
    final amount = num.tryParse(order['total_amount'].toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Order #${order['id']}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  AdminBadge(
                      label: status
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      color: color),
                ],
              ),
              const SizedBox(height: 16),
              AdminDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: AdminHelpers.timeAgo(order['created_at'])),
              AdminDetailRow(
                  icon: Icons.payment,
                  label: 'Payment',
                  value: order['payment_method'] ?? 'N/A'),
              AdminDetailRow(
                  icon: Icons.location_on,
                  label: 'Delivery',
                  value: order['delivery_address'] ?? 'N/A'),
              const Divider(height: 24),
              const Text('Items',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...items.map((item) {
                final lineTotal =
                    (num.tryParse(item['price'].toString()) ?? 0) *
                        (num.tryParse(
                            item['quantity'].toString()) ??
                            0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.eco,
                            color: Colors.green, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? 'Item',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                'Qty: ${item['quantity']}  ×  Rs. ${item['price']}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        AdminHelpers.currency.format(lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(AdminHelpers.currency.format(amount),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Update Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'pending', 'accepted', 'shipped',
                  'out_for_delivery', 'completed', 'cancelled'
                ]
                    .map((s) => ChoiceChip(
                  label: Text(
                      s.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 12)),
                  selected: status == s,
                  selectedColor:
                  AdminHelpers.statusColor(s).withOpacity(0.2),
                  onSelected: (_) {
                    Navigator.pop(ctx);
                    _updateStatus(order['id'], s);
                  },
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}