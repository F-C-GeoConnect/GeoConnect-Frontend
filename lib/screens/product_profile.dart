import 'package:flutter/material.dart';
import 'package:geo_connect/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'farmer_profile_page.dart';
import 'main_screen/chat_page.dart';

class ProductProfilePage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductProfilePage({super.key, required this.product});

  @override
  State<ProductProfilePage> createState() => _ProductProfilePageState();
}

class _ProductProfilePageState extends State<ProductProfilePage> {
  int _quantity = 1;

  String _daysAgo() {
    final createdAtString = widget.product['created_at'] as String?;
    if (createdAtString == null) {
      return 'Unknown';
    }
    final createdAt = DateTime.parse(createdAtString);
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else {
      return 'Today';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProductHeader(),
            const SizedBox(height: 24),
            _buildAddToCartButton(),
            const SizedBox(height: 24),
            _buildSectionHeader('Products Details'),
            _buildProductDetails(),
            const SizedBox(height: 24),
            _buildSectionHeader('Shipping Details'),
            _buildShippingDetails(),
            const SizedBox(height: 24),
            _buildMessageButton(),
            const SizedBox(height: 16),
            _buildShowProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    final productName = (widget.product['productName'] as String?)?.trim() ?? 'Unnamed Product';
    final imageUrl = (widget.product['imageUrl'] as String?)?.trim() ?? '';
    final price = widget.product['price'];

    // Validate price
    if (price == null || (price is! num) || price < 0) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Invalid product data'),
      );
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 60),
                )
              : const Icon(Icons.image_not_supported, size: 60),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text('Add more Items'),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Rs.${price.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.green),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                      });
                    }
                  },
                ),
                Text('$_quantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productId = widget.product['id'] as int?;
    if (productId == null) {
      return const SizedBox.shrink(); // Don't build the button if there's no ID
    }

    final isAdded = cart.isItemInCart(productId);
    final productName = widget.product['productName'] as String? ?? 'Unnamed Product';
    final price = widget.product['price'] as double? ?? 0.0;
    final imageUrl = widget.product['imageUrl'] as String? ?? '';

    return ElevatedButton(
      onPressed: () {
        cart.toggleCartStatus(
          productId,
          productName,
          price,
          imageUrl,
        );
        // We need to rebuild the widget to see the button color change
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isAdded ? Colors.red : Colors.white,
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        isAdded ? 'Remove from DOOKO' : 'Add to DOOKO',
        style: TextStyle(color: isAdded ? Colors.white : Colors.green, fontSize: 16),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductDetails() {
    final productName = widget.product['productName'] as String? ?? 'Unnamed Product';
    final description = widget.product['description'] as String? ?? 'No description available.';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _daysAgo(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetails() {
    final sellerName = widget.product['sellerName'] as String? ?? 'Unknown Seller';
    final location = widget.product['location'] as String? ?? 'Unknown Location';
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sellerName,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Farmer\'s Location: $location'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageButton() {
    return OutlinedButton(
      onPressed: () {
        final sellerId = widget.product['seller_id'] as String?;
        final sellerName = widget.product['sellerName'] as String?;

        if (sellerId != null && sellerName != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverId: sellerId,
                farmerName: sellerName,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not initiate chat. Seller not found.')),
          );
        }
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Message',
        style: TextStyle(color: Colors.green, fontSize: 16),
      ),
    );
  }
  Widget _buildShowProfileButton() {
    return OutlinedButton(
      onPressed: () {
        final sellerName = widget.product['sellerName'] as String? ?? 'Unknown Farmer';
        final sellerId = widget.product['seller_id'] as String? ?? '';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmerProfilePage(
              farmerId: sellerId,
              farmerName: sellerName,
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Show Farmer\'s Profile',
        style: TextStyle(color: Colors.green, fontSize: 16),
      ),
    );
  }

}
