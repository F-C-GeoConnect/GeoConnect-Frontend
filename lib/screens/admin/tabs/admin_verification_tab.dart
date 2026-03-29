// lib/screens/admin/tabs/admin_verification_tab.dart
//
// Admin-side verification review tab. Add this as the 6th tab in admin_panel.dart.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin_helpers.dart';
import '../widgets/admin_widgets.dart';

class AdminVerificationTab extends StatefulWidget {
  const AdminVerificationTab({super.key});

  @override
  State<AdminVerificationTab> createState() => _AdminVerificationTabState();
}

class _AdminVerificationTabState extends State<AdminVerificationTab> {
  final _supabase   = Supabase.instance.client;
  static const _verificationDocsBucket = 'verification_docs';
  static const _verificationCachePrefix = 'admin.verification.';
  String _filter    = 'pending';
  List<Map<String, dynamic>> _requests = [];
  bool _loading     = true;
  final Map<String, String> _docUrlCache = {};

  static const _requestSelect =
      'id, user_id, full_name, phone, address, farm_name, farm_size, note, '
      'doc_identity_url, doc_land_url, doc_selfie_url, status, admin_note, created_at';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final data = await AdminHelpers.cachedLoad<List<dynamic>>(
        '$_verificationCachePrefix$_filter',
        () => _filter == 'all'
            ? _supabase
                .from('verification_requests')
                .select(_requestSelect)
                .order('created_at', ascending: false)
            : _supabase
                .from('verification_requests')
                .select(_requestSelect)
                .eq('status', _filter)
                .order('created_at', ascending: false),
        ttl: const Duration(seconds: 30),
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(data);
          _loading  = false;
        });
      }
    } catch (e) {
      debugPrint('Verification fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> req) async {
    final ok = await AdminHelpers.confirmDialog(
      context,
      'Approve Verification',
      'Approve "${req['full_name']}" as a verified farmer?\n\nTheir profile will show the verified badge immediately.',
      confirmLabel: 'Approve',
      confirmColor: Colors.green,
    );
    if (!ok) return;

    try {
      final adminId = _supabase.auth.currentUser!.id;
      // 1. Update request status
      await _supabase.from('verification_requests').update({
        'status':      'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminId,
        'admin_note':  null,
      }).eq('id', req['id']);

      // 2. Mark profile as verified
      await _supabase
          .from('profiles')
          .update({'is_verified': true})
          .eq('id', req['user_id']);

      // 3. Notify the user
      await _supabase.from('notifications').insert({
        'user_id': req['user_id'],
        'title':   '🎉 Verification Approved!',
        'message': 'Congratulations! Your farmer account has been verified. A badge now appears on your profile.',
        'type':    'selling',
        'is_read': false,
      });

      AdminHelpers.showSnack(context, 'User verified successfully!');
      AdminHelpers.invalidateCachePrefix(_verificationCachePrefix);
      AdminHelpers.invalidateCache('admin.users.list');
      AdminHelpers.invalidateCache('admin.dashboard.summary');
      _fetch(forceRefresh: true);
    } catch (e) {
      AdminHelpers.showError(context, e,
          fallback: 'Unable to approve this request.');
    }
  }

  Future<void> _reject(Map<String, dynamic> req) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting "${req['full_name']}".',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (shown to user)…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final adminId = _supabase.auth.currentUser!.id;
      await _supabase.from('verification_requests').update({
        'status':      'rejected',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminId,
        'admin_note':  noteCtrl.text.trim().isEmpty
            ? 'Your application did not meet our requirements.'
            : noteCtrl.text.trim(),
      }).eq('id', req['id']);

      // Notify user
      await _supabase.from('notifications').insert({
        'user_id': req['user_id'],
        'title':   'Verification Application Update',
        'message': noteCtrl.text.trim().isEmpty
            ? 'Your verification application was not approved at this time. You may re-apply.'
            : 'Your application was not approved: ${noteCtrl.text.trim()}',
        'type':    'general',
        'is_read': false,
      });

      AdminHelpers.showSnack(context, 'Application rejected.');
      AdminHelpers.invalidateCachePrefix(_verificationCachePrefix);
      AdminHelpers.invalidateCache('admin.dashboard.summary');
      _fetch(forceRefresh: true);
    } catch (e) {
      AdminHelpers.showError(context, e,
          fallback: 'Unable to reject this request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['pending', 'approved', 'rejected', 'all']
                  .map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: _filter == s,
                  selectedColor: _chipColor(s).withOpacity(0.2),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                      color: _filter == s
                          ? _chipColor(s).withOpacity(0.5)
                          : Colors.transparent),
                  onSelected: (_) {
                    setState(() => _filter = s);
                    _fetch();
                  },
                ),
              ))
                  .toList(),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.red))
              : _requests.isEmpty
              ? AdminEmptyState(
              message: _filter == 'pending'
                  ? 'No pending applications'
                  : 'No $_filter applications',
              icon: Icons.verified_user_outlined)
              : RefreshIndicator(
            onRefresh: () => _fetch(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _requests.length,
              itemBuilder: (_, i) =>
                  _buildCard(_requests[i]),
            ),
          ),
        ),
      ],
    );
  }

  Color _chipColor(String s) {
    switch (s) {
      case 'pending':  return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default:         return Colors.grey;
    }
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final status      = req['status'] ?? 'pending';
    final statusColor = _chipColor(status);
    final createdAt   = AdminHelpers.timeAgo(req['created_at']);
    final hasIdentity = req['doc_identity_url'] != null;
    final hasLand     = req['doc_land_url']     != null;
    final hasSelfie   = req['doc_selfie_url']   != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.agriculture,
                      color: Colors.green.shade600, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(req['phone'] ?? '',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                AdminBadge(
                    label: status.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 12),

            // Details grid
            _infoRow(Icons.location_on_outlined, req['address'] ?? ''),
            if ((req['farm_name'] ?? '').isNotEmpty)
              _infoRow(Icons.storefront_outlined, req['farm_name']),
            if ((req['farm_size'] ?? '').isNotEmpty)
              _infoRow(Icons.landscape_outlined, req['farm_size']),
            if ((req['note'] ?? '').isNotEmpty)
              _infoRow(Icons.notes, req['note']),

            const SizedBox(height: 12),

            // Document chips
            Row(
              children: [
                const Text('Documents: ',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                if (hasIdentity)
                  _docChip('ID', Icons.badge_outlined,
                      req['doc_identity_url']),
                if (hasLand)
                  _docChip('Land', Icons.description_outlined,
                      req['doc_land_url']),
                if (hasSelfie)
                  _docChip('Selfie', Icons.face_outlined, req['doc_selfie_url']),
                if (!hasIdentity && !hasLand && !hasSelfie)
                  Text('None uploaded',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),

            // Admin note (on rejection)
            if ((req['admin_note'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(req['admin_note'],
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade800)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(createdAt,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),

            // Action buttons (only for pending)
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject'),
                      onPressed: () => _reject(req),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.verified, size: 16),
                      label: const Text('Approve'),
                      onPressed: () => _approve(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  Widget _docChip(String label, IconData icon, String? url) {
    return GestureDetector(
      onTap: url != null ? () => _viewDocument(url, label) : null,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 3),
            Icon(Icons.open_in_new,
                size: 10, color: Colors.blue.shade400),
          ],
        ),
      ),
    );
  }

  Future<String> _resolveDocumentUrl(String storedValue) async {
    final value = storedValue.trim();
    final cachedUrl = _docUrlCache[value];
    if (cachedUrl != null) return cachedUrl;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      _docUrlCache[value] = value;
      return value;
    }
    final signed = await _supabase.storage
        .from(_verificationDocsBucket)
        .createSignedUrl(value, 60 * 5);
    _docUrlCache[value] = signed;
    return signed;
  }

  Future<void> _viewDocument(String value, String label) async {
    try {
      final imageUrl = await _resolveDocumentUrl(value);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheKey: value,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.broken_image,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Could not load image',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AdminHelpers.showError(context, e,
          fallback: 'Unable to open this document.');
    }
  }
}





