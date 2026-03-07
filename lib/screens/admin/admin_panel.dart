import 'package:flutter/material.dart';
import 'package:geo_connect/models/user_profile.dart';
import 'package:geo_connect/models/produce_listing.dart';
import 'package:geo_connect/services/admin_repository.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final AdminRepository _adminRepo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.shopping_basket), text: 'Listings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            _buildListingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return FutureBuilder<List<UserProfile>>(
      future: _adminRepo.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final users = snapshot.data ?? [];
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text('${user.phone} - Role: ${user.role.name}'),
              trailing: PopupMenuButton<UserRole>(
                onSelected: (UserRole role) async {
                  await _adminRepo.updateUserRole(user.id, role);
                  setState(() {}); // Refresh
                },
                itemBuilder: (context) => UserRole.values
                    .map((role) => PopupMenuItem(
                          value: role,
                          child: Text('Set as ${role.name}'),
                        ))
                    .toList(),
              ),
              onLongPress: () => _confirmDeleteUser(user),
            );
          },
        );
      },
    );
  }

  Widget _buildListingsTab() {
    return FutureBuilder<List<ProduceListing>>(
      future: _adminRepo.getAllListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final listings = snapshot.data ?? [];
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return ListTile(
              title: Text(listing.name),
              subtitle: Text('Price: \$${listing.price}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteListing(listing),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _adminRepo.deleteUser(user.id);
              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteListing(ProduceListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete ${listing.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _adminRepo.deleteListing(listing.id);
              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}