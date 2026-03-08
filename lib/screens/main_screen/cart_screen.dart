import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  Future<void> _processCheckout(CartProvider cart) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to checkout'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cartItems = cart.items.values.toList();

      // 1. Fetch all product data and validate BEFORE processing anything.
      //    This ensures no orders are created or inventory decremented if any
      //    item fails validation (own-product check or insufficient stock).
      final List<Map<String, dynamic>> productDataList = [];
      for (var item in cartItems) {
        final productData = await supabase
            .from('products')
            .select('quantity, seller_id, productName')
            .eq('id', item.id)
            .single();

        final String sellerId = productData['seller_id'] as String;
        final int currentStock = productData['quantity'] as int;

        // --- SECURITY CHECK: Prevent seller from buying their own product ---
        if (sellerId == user.id) {
          throw 'You cannot purchase your own product (${item.name}).';
        }
        // -------------------------------------------------------------------

        if (currentStock < item.quantity) {
          throw 'Sorry, ${item.name} only has $currentStock units left.';
        }

        productDataList.add(productData);
      }

      // 2. All checks passed — now safe to process all orders
      for (var i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final productData = productDataList[i];
        final int currentStock = productData['quantity'] as int;
        final String sellerId = productData['seller_id'] as String;

        // A. Create the Order Record
        await supabase.from('orders').insert({
          'buyer_id': user.id,
          'seller_id': sellerId,
          'total_amount': item.price * item.quantity,
          'status': 'pending',
          'items': [
            {
              'product_id': item.id,
              'product_name': item.name,
              'quantity': item.quantity,
              'price': item.price,
            }
          ],
        });

        // B. Update Inventory
        await supabase
            .from('products')
            .update({'quantity': currentStock - item.quantity})
            .eq('id', item.id);
      }

      // Call the checkout method in CartProvider to send messages to sellers and clear the cart
      await cart.checkout(supabase, user.id);

      // 3. Success Feedback
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Placed!'),
            content: const Text('The farmers have been notified. You can track your orders in your account.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart?'),
                    content: const Text('Do you want to remove all items from your cart?'),
                    actions: [
                      TextButton(child: const Text('No'), onPressed: () => Navigator.of(ctx).pop()),
                      TextButton(
                        child: const Text('Yes', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          cart.clearCart();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text("Your cart is empty!", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8.0),
              itemCount: cartItems.length,
              itemBuilder: (ctx, i) {
                final item = cartItems[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 60),
                      ),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Rs. ${item.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                          onPressed: () => cart.decrementItem(item.id),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                          onPressed: () => cart.incrementItem(item.id),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => cart.removeItem(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Total Amount", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("Rs. ${cart.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _processCheckout(cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Checkout", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}