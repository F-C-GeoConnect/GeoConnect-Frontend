import 'package:flutter/material.dart';
import 'package:geo_connect/screens/product_profile.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/refreshable_scaffold.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import 'map.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<List<Map<String, dynamic>>> _productsStream;
  final _searchController = TextEditingController();
  String _searchText = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initStream();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  void _initStream() {
    _productsStream = Supabase.instance.client
        .from('products')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
            Text('DOKO',
                style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
            Row(
              children: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.shopping_basket_outlined,
                          color: Colors.grey.shade700),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartScreen()),
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
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Consumer<CartProvider>(
                          builder: (context, cart, child) => Text(
                            cart.itemCount.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Colors.grey.shade700),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshableWrapper(
        onRefresh: _handleRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              const PromoBanner(),
              const SizedBox(height: 20),
              _buildSectionHeader('Browse Products', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPage()),
                );
              }),
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
          onPressed: () {
            /* TODO: Show filter options */
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onMapPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onMapPressed,
          icon: const Icon(Icons.map_outlined, color: Colors.green),
        ),
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
          return Center(
              child: Text('Error fetching products: ${snapshot.error}'));
        }
        final allProducts = snapshot.data;
        if (allProducts == null || allProducts.isEmpty) {
          return const Center(child: Text('No products available yet.'));
        }

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

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Image.network(
        'https://clipart-library.com/2023/5f0d0ab64520712d29e2c2fd_NEW20Summer20Market20Logo20white.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'Summer Market',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['imageUrl'] as String? ?? 'https://i.imgur.com/S8A4L5p.png';
    final productId = (product['id'] as num?)?.toInt() ?? 0;
    final productName = product['productName'] as String? ?? 'No Name';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductProfilePage(product: product),
          ),
        );
      },
      child: Card(
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
                        return const Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey);
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
                      child: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final isAdded = cart.isItemInCart(productId);
                          return IconButton(
                            iconSize: 20,
                            icon: Icon(
                              isAdded ? Icons.favorite : Icons.favorite_border,
                              color: isAdded ? Colors.red : Colors.black54,
                            ),
                            onPressed: () {
                              try {
                                cart.toggleCartStatus(
                                    productId, productName, price, imageUrl);
                              } catch (e) {
                                print('Error toggling cart: $e');
                              }
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          );
                        },
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
                  Text(productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Rs.${price.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.grey.shade800, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('4.5', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('(123)',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
