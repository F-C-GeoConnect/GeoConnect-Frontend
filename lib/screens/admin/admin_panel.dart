// lib/screens/admin/admin_panel.dart

import 'package:flutter/material.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_orders_tab.dart';
import 'tabs/admin_products_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_broadcast_tab.dart';
import 'tabs/admin_verification_tab.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    AdminDashboardTab(),
    AdminOrdersTab(),
    AdminProductsTab(),
    AdminUsersTab(),
    AdminVerificationTab(),
    AdminBroadcastTab(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Admin Control Panel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18),
                text: 'Dashboard'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 18),
                text: 'Orders'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18),
                text: 'Products'),
            Tab(icon: Icon(Icons.people_outline, size: 18),
                text: 'Users'),
            Tab(icon: Icon(Icons.verified_user_outlined, size: 18),
                text: 'Verify'),
            Tab(icon: Icon(Icons.campaign_outlined, size: 18),
                text: 'Broadcast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs,
      ),
    );
  }
}