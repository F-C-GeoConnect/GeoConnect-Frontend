import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login_screen.dart';

class ListingPage extends StatefulWidget {
  const ListingPage({super.key});

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _productsStream;
  late StreamSubscription? _productsSubscription;

  @override
  void initState() {
    super.initState();
    final currentUser = _supabase.auth.currentUser;
    _productsStream = _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('sellerID', currentUser?.id ?? '')
        .order('created_at', ascending: false);

    _productsSubscription = _productsStream.listen((_) {});
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateQuantity(int productId, int currentQuantity, int change) async {
    int newQuantity = currentQuantity + change;
    if (newQuantity > 0) {
      await _supabase
          .from('products')
          .update({'quantity': newQuantity})
          .eq('id', productId);
    }
  }

  // --- Updated Delete Function ---
  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final imageUrl = product['imageUrl'] as String?;
    final productId = product['id'] as int;

    try {
      // 1. Delete the image from Storage if it exists
      if (imageUrl != null) {
        // Extract the file name from the URL
        final fileName = imageUrl.split('/').last;
        await _supabase.storage.from('product_images').remove([fileName]);
      }

      // 2. Delete the product record from the database
      await _supabase.from('products').delete().eq('id', productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Updated Confirmation Dialog to accept the full product map ---
  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> product) async {
    final productName = product['productName'] ?? 'the product';
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete "$productName"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes'),
              onPressed: () {
                _deleteProduct(product); // Pass the full product map
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _supabase.auth.currentUser;
    final sellerName = currentUser?.userMetadata?['full_name'] as String? ?? 'My Listings';

    return Scaffold(
      appBar: AppBar(
        title: Text(sellerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
                child: Text('You have not posted any products yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: product['imageUrl'] != null
                      ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : const SizedBox(width: 50, height: 50, child: Icon(Icons.image_not_supported)),
                  title: Text(product['productName'] ?? 'No Name'),
                  subtitle: Text('Rs.${product['price'] ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Updated to pass the full product map to the dialog
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirmationDialog(product)),
                      IconButton(icon: const Icon(Icons.remove), onPressed: () => _updateQuantity(product['id'], product['quantity'], -1)),
                      Text('${product['quantity']}', style: const TextStyle(fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => _updateQuantity(product['id'], product['quantity'], 1)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}