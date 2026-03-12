// lib/screens/admin/tabs/admin_products_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin_helpers.dart';
import '../widgets/admin_widgets.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);
    try {
      final data = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(data);
          _applySearch();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Products fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySearch() {
    if (_search.isEmpty) {
      _filtered = List.from(_products);
    } else {
      final q = _search.toLowerCase();
      _filtered = _products
          .where((p) =>
      (p['productName'] ?? '').toString().toLowerCase().contains(q) ||
          (p['sellerName'] ?? '').toString().toLowerCase().contains(q) ||
          (p['category'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
  }

  Future<void> _deleteProduct(int id, String name) async {
    final ok = await AdminHelpers.confirmDialog(
      context,
      'Delete Product',
      'Permanently delete "$name"? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (!ok) return;
    try {
      await _supabase.from('products').delete().eq('id', id);
      AdminHelpers.showSnack(context, 'Product deleted.');
      _fetchProducts();
    } catch (e) {
      AdminHelpers.showSnack(context, 'Error: $e', error: true);
    }
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final nameCtrl  = TextEditingController(text: product['productName'] ?? '');
    final priceCtrl = TextEditingController(
        text: product['price']?.toString() ?? '');
    final descCtrl  = TextEditingController(
        text: product['description'] ?? '');
    final qtyCtrl   = TextEditingController(
        text: product['total_quantity']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Product Name', Icons.inventory_2),
              const SizedBox(height: 12),
              _field(priceCtrl, 'Price (Rs.)', Icons.currency_rupee,
                  numeric: true),
              const SizedBox(height: 12),
              _field(qtyCtrl, 'Quantity', Icons.scale, numeric: true),
              const SizedBox(height: 12),
              _field(descCtrl, 'Description', Icons.description,
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    try {
      await _supabase.from('products').update({
        'productName':     nameCtrl.text.trim(),
        'price':           double.tryParse(priceCtrl.text) ?? product['price'],
        'description':     descCtrl.text.trim(),
        'total_quantity':  double.tryParse(qtyCtrl.text) ?? product['total_quantity'],
      }).eq('id', product['id']);
      AdminHelpers.showSnack(context, 'Product updated.');
      _fetchProducts();
    } catch (e) {
      AdminHelpers.showSnack(context, 'Error: $e', error: true);
    }
  }

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool numeric = false,
        int maxLines = 1,
      }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.multiline,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products…',
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
              message: 'No products found',
              icon: Icons.inventory_2)
              : RefreshIndicator(
            onRefresh: _fetchProducts,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              itemCount: _filtered.length,
              itemBuilder: (_, i) =>
                  _buildProductCard(_filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final imageUrl = p['imageUrl']?.toString() ?? '';
    final name     = p['productName'] ?? 'No name';
    // ── FIX: raw number only, no currency symbol — we apply it once ──
    final price    = num.tryParse(p['price'].toString()) ?? 0;
    final qty      = p['total_quantity'] ?? 0;
    final seller   = p['sellerName'] ?? 'Unknown';
    final category = p['category']?.toString() ?? '';
    final lowStock = (num.tryParse(qty.toString()) ?? 0) < 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),

            // Details — Expanded prevents overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Text(seller,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (category.isNotEmpty)
                        AdminBadge(label: category, color: Colors.green),
                      // Single currency format — no double "Rs."
                      Text(
                        AdminHelpers.currency.format(price),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: lowStock ? Colors.red : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: $qty',
                        style: TextStyle(
                          fontSize: 11,
                          color: lowStock ? Colors.red : Colors.grey.shade500,
                          fontWeight: lowStock
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (lowStock) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('LOW',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),

            // Action icons — Column, not inline to prevent overflow
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  onPressed: () => _editProduct(p),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () =>
                      _deleteProduct(p['id'] as int, name),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.eco, color: Colors.green, size: 30),
    );
  }
}