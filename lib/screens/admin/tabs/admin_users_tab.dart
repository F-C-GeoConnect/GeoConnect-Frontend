// lib/screens/admin/tabs/admin_users_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin_helpers.dart';
import '../widgets/admin_widgets.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _supabase = Supabase.instance.client;
  static const _usersCacheKey = 'admin.users.list';
  List<Map<String, dynamic>> _users    = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final data = await AdminHelpers.cachedLoad<List<dynamic>>(
        _usersCacheKey,
        () => _supabase
            .from('profiles')
            .select('id, full_name, phone, address, avatar_url, is_admin, is_banned, is_verified')
            .order('full_name'),
        ttl: const Duration(seconds: 30),
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _applySearch();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Users fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySearch() {
    if (_search.isEmpty) {
      _filtered = List.from(_users);
    } else {
      final q = _search.toLowerCase();
      _filtered = _users
          .where((u) =>
      (u['full_name'] ?? '').toString().toLowerCase().contains(q) ||
          (u['phone'] ?? '').toString().toLowerCase().contains(q) ||
          (u['address'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
  }

  void _patchUserFlagLocally(String userId, String key, bool value) {
    _users = _users.map((u) {
      if (u['id'].toString() != userId) return u;
      return {...u, key: value};
    }).toList();
    _applySearch();
  }

  List<Map<String, dynamic>> _cloneUsers(List<Map<String, dynamic>> source) {
    return source.map((u) => Map<String, dynamic>.from(u)).toList();
  }

  Future<void> _toggleBan(String userId, String name, bool isBanned) async {
    final currentId = _supabase.auth.currentUser?.id;
    if (userId == currentId) {
      AdminHelpers.showSnack(context, 'You cannot ban yourself!',
          error: true);
      return;
    }
    final ok = await AdminHelpers.confirmDialog(
      context,
      isBanned ? 'Unban User' : 'Ban User',
      isBanned
          ? 'Unban "$name"? They will regain access to the app.'
          : 'Ban "$name"? They will be blocked from the app.',
      confirmLabel: isBanned ? 'Unban' : 'Ban',
      confirmColor: isBanned ? Colors.green : Colors.red,
    );
    if (!ok) return;

    final previousUsers = _cloneUsers(_users);
    if (mounted) {
      setState(() => _patchUserFlagLocally(userId, 'is_banned', !isBanned));
    }

    try {
      final updatedRows = await _supabase
          .from('profiles')
          .update({'is_banned': !isBanned})
          .eq('id', userId)
          .select('id');

      if (updatedRows.isEmpty) {
        throw Exception('Ban update did not persist (user not found or permission denied).');
      }

      if (mounted) {
        AdminHelpers.showSnack(
            context, 'User ${isBanned ? "unbanned" : "banned"}.');
      }
      AdminHelpers.invalidateCache(_usersCacheKey);
      AdminHelpers.invalidateCache('admin.dashboard.summary');
      await _fetchUsers(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _users = previousUsers;
          _applySearch();
        });
        AdminHelpers.showError(context, e,
            fallback: 'Unable to update ban status.');
      }
    }
  }

  Future<void> _toggleVerify(
      String userId, String name, bool isVerified) async {
    final ok = await AdminHelpers.confirmDialog(
      context,
      isVerified ? 'Remove Verification' : 'Verify Seller',
      isVerified
          ? 'Remove verified badge from "$name"?'
          : 'Mark "$name" as a verified seller?',
      confirmLabel: isVerified ? 'Unverify' : 'Verify',
      confirmColor: isVerified ? Colors.orange : Colors.blue,
    );
    if (!ok) return;

    final previousUsers = _cloneUsers(_users);
    if (mounted) {
      setState(() => _patchUserFlagLocally(userId, 'is_verified', !isVerified));
    }

    try {
      final updatedRows = await _supabase
          .from('profiles')
          .update({'is_verified': !isVerified})
          .eq('id', userId)
          .select('id');

      if (updatedRows.isEmpty) {
        throw Exception('Verify update did not persist (user not found or permission denied).');
      }

      if (mounted) {
        AdminHelpers.showSnack(
            context, 'User ${isVerified ? "unverified" : "verified"}.');
      }
      AdminHelpers.invalidateCache(_usersCacheKey);
      AdminHelpers.invalidateCache('admin.dashboard.summary');
      await _fetchUsers(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _users = previousUsers;
          _applySearch();
        });
        AdminHelpers.showError(context, e,
            fallback: 'Unable to update verification status.');
      }
    }
  }

  Future<void> _toggleAdmin(
      String userId, String name, bool isAdmin) async {
    final currentId = _supabase.auth.currentUser?.id;
    if (userId == currentId) {
      AdminHelpers.showSnack(context, 'You cannot change your own role!',
          error: true);
      return;
    }
    final ok = await AdminHelpers.confirmDialog(
      context,
      isAdmin ? 'Remove Admin Role' : 'Grant Admin Role',
      isAdmin
          ? 'Remove admin privileges from "$name"?'
          : 'Grant admin privileges to "$name"?',
      confirmLabel: isAdmin ? 'Remove' : 'Grant',
      confirmColor: isAdmin ? Colors.red : Colors.purple,
    );
    if (!ok) return;
    try {
      await _supabase
          .from('profiles')
          .update({'is_admin': !isAdmin}).eq('id', userId);
      AdminHelpers.showSnack(
          context,
          isAdmin ? 'Admin role removed.' : 'Admin role granted.');
      AdminHelpers.invalidateCache(_usersCacheKey);
      AdminHelpers.invalidateCache('admin.dashboard.summary');
      _fetchUsers(forceRefresh: true);
    } catch (e) {
      AdminHelpers.showError(context, e,
          fallback: 'Unable to update admin role.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() {
              _search = v;
              _applySearch();
            }),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.red))
              : _filtered.isEmpty
              ? const AdminEmptyState(
              message: 'No users found', icon: Icons.people)
              : RefreshIndicator(
            onRefresh: () => _fetchUsers(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              itemCount: _filtered.length,
              itemBuilder: (_, i) =>
                  _buildUserCard(_filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final bool isAdmin    = u['is_admin']    ?? false;
    final bool isBanned   = u['is_banned']   ?? false;
    final bool isVerified = u['is_verified'] ?? false;
    final String userId   = u['id'];
    final String name     = u['full_name'] ?? 'No Name';
    final String avatar   = u['avatar_url'] ?? '';
    // IMPROVED: display phone and address separately (was merged before)
    final String phone    = u['phone']   ?? '';
    final String address  = u['address'] ?? '';
    final bool isMe =
        userId == _supabase.auth.currentUser?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green.shade50,
                  backgroundImage: avatar.isNotEmpty
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar.isEmpty
                      ? Text(name[0].toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green.shade700))
                      : null,
                ),
                const SizedBox(width: 12),

                // Name + badges + contact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMPROVED: Wrap prevents name+badges from overflowing on small screens
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                decoration: isBanned
                                    ? TextDecoration.lineThrough
                                    : null,
                                color:
                                isBanned ? Colors.grey : Colors.black),
                          ),
                          if (isVerified)
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 15),
                          if (isAdmin)
                            const AdminBadge(
                                label: 'ADMIN', color: Colors.purple),
                          if (isBanned)
                            const AdminBadge(
                                label: 'BANNED', color: Colors.red),
                          if (isMe)
                            const AdminBadge(
                                label: 'YOU', color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Phone
                      if (phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(phone,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      // Address
                      if (address.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(address,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      if (phone.isEmpty && address.isEmpty)
                        Text('No contact info',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // IMPROVED: Wrap prevents action buttons from overflowing
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminActionButton(
                  label: isVerified ? 'Unverify' : 'Verify',
                  icon: isVerified
                      ? Icons.verified_outlined
                      : Icons.verified,
                  color: isVerified ? Colors.orange : Colors.blue,
                  onTap: () => _toggleVerify(userId, name, isVerified),
                ),
                if (!isMe) ...[
                  AdminActionButton(
                    label: isBanned ? 'Unban' : 'Ban',
                    icon: isBanned ? Icons.lock_open : Icons.block,
                    color: isBanned ? Colors.green : Colors.red,
                    onTap: () => _toggleBan(userId, name, isBanned),
                  ),
                  AdminActionButton(
                    label: isAdmin ? 'Remove Admin' : 'Make Admin',
                    icon: Icons.admin_panel_settings,
                    color: isAdmin ? Colors.red : Colors.purple,
                    onTap: () => _toggleAdmin(userId, name, isAdmin),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
