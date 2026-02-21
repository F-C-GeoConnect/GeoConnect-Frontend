import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_screen.dart';
import 'cart_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<List<Map<String, dynamic>>> _productsStream;
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _productsStream = Supabase.instance.client
        .from('products')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DOKO', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 24)),
            Row(
              children: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.shopping_basket_outlined, color: Colors.grey.shade700),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CartScreen()),
                        );
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Consumer<CartProvider>(
                          builder: (context, cart, child) => Text(
                            cart.itemCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: Colors.grey.shade700),
                  onPressed: () { /* TODO: Navigate to Notifications */ },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildPromoBanner(),
              const SizedBox(height: 20),
              _buildSectionHeader('Browse Products', () { /* TODO: View all products */ }),
              const SizedBox(height: 10),
              _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () { /* TODO: Show filter options */ },
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: NetworkImage('https://clipart-library.com/2023/5f0d0ab64520712d29e2c2fd_NEW20Summer20Market20Logo20white.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onViewAll, child: const Text('View all')),
      ],
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching products: ${snapshot.error}'));
        }
        final allProducts = snapshot.data;
        if (allProducts == null || allProducts.isEmpty) {
          return const Center(child: Text('No products available yet.'));
        }

        // --- Filter products based on search text ---
        final filteredProducts = allProducts.where((product) {
          final productName = product['productName'] as String? ?? '';
          return productName.toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        if (filteredProducts.isEmpty) {
          return const Center(child: Text('No products match your search.'));
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final imageUrl = product['imageUrl'] as String? ?? 'https://i.imgur.com/S8A4L5p.png';
    final productId = product['id'] as int;
    final productName = product['productName'] as String? ?? 'No Name';
    final price = product['price'] ?? 0.0;

    final isAdded = cartProvider.isItemInCart(productId);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 40, color: Colors.grey);
                    },
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 20,
                      icon: Icon(
                        isAdded ? Icons.favorite : Icons.favorite_border,
                        color: isAdded ? Colors.red : Colors.black54,
                      ),
                      onPressed: () {
                        cartProvider.toggleCartStatus(productId, productName, price, imageUrl);
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Rs.${price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('4.5', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text('(123)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
