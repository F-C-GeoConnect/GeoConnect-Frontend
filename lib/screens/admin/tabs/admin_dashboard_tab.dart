import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../admin_helpers.dart';
import '../widgets/admin_widgets.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _supabase = Supabase.instance.client;
  static const _dashboardCacheKey = 'admin.dashboard.summary';

  int _totalUsers           = 0;
  int _totalProducts        = 0;
  int _totalOrders          = 0;
  int _pendingOrders        = 0;
  int _totalRevenue         = 0;
  int _bannedUsers          = 0;
  int _pendingVerifications = 0;
  bool _loading             = true;
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final payload = await AdminHelpers.cachedLoad<Map<String, dynamic>>(
        _dashboardCacheKey,
            () async {
          final results = await Future.wait([
            _supabase.from('profiles').count(),
            _supabase.from('products').count(),
            _supabase.from('orders').count(),
            _supabase.from('orders').count().eq('status', 'pending'),
            _supabase.from('profiles').count().eq('is_banned', true),
            _supabase.from('verification_requests').count().eq('status', 'pending'),
          ]);

          final revenueRows = await _supabase
              .from('orders')
              .select('total_amount')
              .eq('status', 'completed');

          int rev = 0;
          for (final row in revenueRows as List) {
            rev += (num.tryParse(row['total_amount'].toString()) ?? 0).toInt();
          }

          final recent = await _supabase
              .from('orders')
              .select('id, status, total_amount, created_at, items')
              .order('created_at', ascending: false)
              .limit(15);

          return {
            'users': results[0],
            'products': results[1],
            'orders': results[2],
            'pendingOrders': results[3],
            'bannedUsers': results[4],
            'pendingVerifications': results[5],
            'revenue': rev,
            'recent': List<Map<String, dynamic>>.from(recent),
          };
        },
        ttl: const Duration(seconds: 30),
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _totalUsers           = payload['users'] as int;
          _totalProducts        = payload['products'] as int;
          _totalOrders          = payload['orders'] as int;
          _pendingOrders        = payload['pendingOrders'] as int;
          _bannedUsers          = payload['bannedUsers'] as int;
          _pendingVerifications = payload['pendingVerifications'] as int;
          _totalRevenue         = payload['revenue'] as int;
          _recentOrders         = payload['recent'] as List<Map<String, dynamic>>;
          _loading              = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminSectionTitle('Overview'),
          const SizedBox(height: 12),
          _loading
              ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.red),
              ))
              : _buildGrid(),
          const SizedBox(height: 24),
          const AdminSectionTitle('Recent Orders'),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: Colors.red))
          else if (_recentOrders.isEmpty)
            const AdminEmptyState(
                message: 'No recent orders', icon: Icons.receipt_long)
          else
            ..._recentOrders.map(_buildMiniOrderCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Stat grid ──────────────────────────────────────────────────────

  Widget _buildGrid() {
    final items = [
      _DashItem('Users',          _totalUsers,           Icons.people_alt,           Colors.blue,   null),
      _DashItem('Products',       _totalProducts,        Icons.storefront,            Colors.green,  null),
      _DashItem('Orders',         _totalOrders,          Icons.receipt,               Colors.purple, null),
      _DashItem('Pending Orders', _pendingOrders,        Icons.hourglass_top,         Colors.orange, null),
      _DashItem('Revenue',        _totalRevenue,         Icons.currency_rupee,        Colors.teal,   'Rs.'),
      _DashItem('Banned Users',   _bannedUsers,          Icons.block,                 Colors.red,    null),
      _DashItem('Pending Verif.', _pendingVerifications, Icons.verified_user_outlined, Colors.indigo, null),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_DashItem item) {
    final formatted = item.prefix != null
        ? '${item.prefix} ${NumberFormat('#,##0').format(item.value)}'
        : '${item.value}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: item.color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // never over-expand
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: item.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(height: 4),
          // IMPROVED: FittedBox prevents large numbers from overflowing
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatted,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: item.color),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent orders mini-card ────────────────────────────────────────

  Widget _buildMiniOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final color  = AdminHelpers.statusColor(status);
    final items  = order['items'] as List<dynamic>? ?? [];
    final first  = items.isNotEmpty
        ? (items.first['product_name'] ?? 'Item').toString()
        : 'Order';
    final amount = num.tryParse(order['total_amount'].toString()) ?? 0;
    // IMPROVED: Shorten long UUID order IDs to prevent overflow
    final rawId   = order['id'].toString();
    final shortId = rawId.length > 8 ? '${rawId.substring(0, 8)}…' : rawId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child:
            Icon(Icons.shopping_bag_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$shortId',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(first,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AdminHelpers.currency.format(amount),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? prefix;
  const _DashItem(
      this.label, this.value, this.icon, this.color, this.prefix);
}