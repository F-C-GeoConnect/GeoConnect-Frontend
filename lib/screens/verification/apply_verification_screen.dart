// lib/screens/verification/apply_verification_screen.dart
//
// User-facing screen. Accessible from my_account.dart for non-verified users.
// Lets a farmer fill in details and upload up to 3 document photos.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplyVerificationScreen extends StatefulWidget {
  const ApplyVerificationScreen({super.key});

  @override
  State<ApplyVerificationScreen> createState() =>
      _ApplyVerificationScreenState();
}

class _ApplyVerificationScreenState extends State<ApplyVerificationScreen> {
  final _supabase    = Supabase.instance.client;
  static const _verificationDocsBucket = 'verification_docs';
  final _formKey     = GlobalKey<FormState>();
  final _picker      = ImagePicker();

  // Form controllers
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _farmCtrl    = TextEditingController();
  final _sizeCtrl    = TextEditingController();
  final _noteCtrl    = TextEditingController();

  // Selected files
  File? _identityFile;
  File? _landFile;
  File? _selfieFile;

  bool _submitting = false;
  String? _existingStatus; // 'pending' | 'rejected' | null
  String? _adminNote;

  @override
  void initState() {
    super.initState();
    _prefillAndCheckStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _farmCtrl.dispose();
    _sizeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillAndCheckStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Pre-fill from profile
    final profile = await _supabase
        .from('profiles')
        .select('full_name, phone, address')
        .eq('id', userId)
        .maybeSingle();
    if (profile != null && mounted) {
      _nameCtrl.text    = profile['full_name'] ?? '';
      _phoneCtrl.text   = profile['phone']     ?? '';
      _addressCtrl.text = profile['address']   ?? '';
    }

    // Check for existing pending / rejected request
    final existing = await _supabase
        .from('verification_requests')
        .select('status, admin_note')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null && mounted) {
      setState(() {
        _existingStatus = existing['status'];
        _adminNote      = existing['admin_note'];
      });
    }
  }

  Future<void> _pickImage(_DocType type) async {
    final xFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    setState(() {
      switch (type) {
        case _DocType.identity: _identityFile = File(xFile.path); break;
        case _DocType.land:     _landFile     = File(xFile.path); break;
        case _DocType.selfie:   _selfieFile   = File(xFile.path); break;
      }
    });
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> _uploadDoc(File file, String label) async {
    final userId  = _supabase.auth.currentUser!.id;
    final ext     = file.path.split('.').last;
    final path    = '$userId/${label}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _supabase.storage.from(_verificationDocsBucket).upload(path, file);
      // Store object path, not a long-lived signed URL.
      return path;
    } on StorageException catch (e) {
      if ((e.statusCode == '404') ||
          (e.message.toLowerCase().contains('bucket not found'))) {
        throw Exception(
          'Verification upload is not configured yet. Please create a storage bucket named "$_verificationDocsBucket".',
        );
      }
      rethrow;
    }
  }

  String _friendlySubmitError(Object error) {
    if (error is PostgrestException) {
      return 'Could not submit your application. Please try again shortly.';
    }
    if (error is StorageException) {
      return 'Document upload failed. Please try again.';
    }
    return error.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_identityFile == null) {
      _snack('Please upload your Identity Document (e.g. citizenship card).',
          error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      String? identityUrl, landUrl, selfieUrl;
      identityUrl = await _uploadDoc(_identityFile!, 'identity');
      if (_landFile   != null) landUrl   = await _uploadDoc(_landFile!,   'land');
      if (_selfieFile != null) selfieUrl = await _uploadDoc(_selfieFile!, 'selfie');

      await _supabase.from('verification_requests').insert({
        'user_id':          _supabase.auth.currentUser!.id,
        'full_name':        _nameCtrl.text.trim(),
        'phone':            _phoneCtrl.text.trim(),
        'address':          _addressCtrl.text.trim(),
        'farm_name':        _optionalText(_farmCtrl.text),
        'farm_size':        _optionalText(_sizeCtrl.text),
        'note':             _optionalText(_noteCtrl.text),
        'doc_identity_url': identityUrl,
        'doc_land_url':     landUrl,
        'doc_selfie_url':   selfieUrl,
        'status':           'pending',
      });

      if (mounted) {
        setState(() => _existingStatus = 'pending');
        _snack('Application submitted! Admin will review it shortly.');
      }
    } catch (e) {
      debugPrint('Verification submit error: $e');
      _snack(_friendlySubmitError(e), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Apply for Verification',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _existingStatus == 'pending'
          ? _buildStatusView(
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.orange,
        title: 'Application Under Review',
        subtitle:
        'Your verification request has been submitted and is being reviewed by our admin team. You will be notified once a decision is made.',
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rejection notice
            if (_existingStatus == 'rejected') ...[
              _buildRejectionBanner(),
              const SizedBox(height: 20),
            ],

            // Info card
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 12),
                  _field(_nameCtrl,    'Full Name',  Icons.person,     required: true),
                  const SizedBox(height: 12),
                  _field(_phoneCtrl,   'Phone Number', Icons.phone,    required: true),
                  const SizedBox(height: 12),
                  _field(_addressCtrl, 'Home Address', Icons.location_on, required: true),
                  const SizedBox(height: 20),

                  _sectionLabel('Farm Information'),
                  const SizedBox(height: 12),
                  _field(_farmCtrl, 'Farm / Business Name (optional)',
                      Icons.agriculture),
                  const SizedBox(height: 12),
                  _field(_sizeCtrl, 'Farm Size (optional, e.g. 2 ropani)',
                      Icons.landscape),
                  const SizedBox(height: 20),

                  _sectionLabel('Supporting Documents'),
                  const SizedBox(height: 4),
                  Text(
                    'Upload clear photos of your documents. JPG or PNG only.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  _docPicker(
                    type: _DocType.identity,
                    file: _identityFile,
                    label: 'Identity Document *',
                    hint: 'Citizenship card, Passport, or Voter ID',
                    icon: Icons.badge_outlined,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _docPicker(
                    type: _DocType.land,
                    file: _landFile,
                    label: 'Land / Farm Certificate (optional)',
                    hint: 'Lalpurja or land ownership certificate',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),
                  _docPicker(
                    type: _DocType.selfie,
                    file: _selfieFile,
                    label: 'Selfie Holding ID (optional)',
                    hint: 'Photo of you holding your identity document',
                    icon: Icons.face,
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel('Additional Note (optional)'),
                  const SizedBox(height: 12),
                  _field(_noteCtrl,
                      'Any additional information for the admin…',
                      Icons.notes,
                      maxLines: 3),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _submitting
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(
                        _submitting ? 'Submitting…' : 'Submit Application',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitting ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 56, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Previous Application Rejected',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700)),
            ],
          ),
          if (_adminNote != null && _adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Admin note: $_adminNote',
                style: TextStyle(
                    fontSize: 13, color: Colors.red.shade800)),
          ],
          const SizedBox(height: 6),
          Text('You may re-apply with updated information below.',
              style:
              TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Why get verified?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800)),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            'A blue ✓ badge appears on your profile and products',
            'Buyers trust verified farmers more',
            'Priority listing in search results',
          ].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle,
                    size: 14, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade800))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style:
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
  }

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool required = false,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: Colors.green.shade400, width: 1.5)),
      ),
    );
  }

  Widget _docPicker({
    required _DocType type,
    required File? file,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: file != null
                ? Colors.green.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: file != null
                    ? Colors.green.shade300
                    : Colors.grey.shade200,
                width: file != null ? 1.5 : 1)),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file != null
                  ? Image.file(file,
                  width: 52, height: 52, fit: BoxFit.cover)
                  : Container(
                width: 52,
                height: 52,
                color: Colors.grey.shade100,
                child: Icon(icon,
                    size: 24, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    file != null
                        ? '✓ Document selected'
                        : hint,
                    style: TextStyle(
                        fontSize: 11,
                        color: file != null
                            ? Colors.green.shade700
                            : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(
              file != null ? Icons.check_circle : Icons.add_photo_alternate_outlined,
              color: file != null ? Colors.green : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

enum _DocType { identity, land, selfie }