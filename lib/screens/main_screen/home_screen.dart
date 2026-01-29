import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Dummy Data for Categories
  final List<Map<String, dynamic>> categories = [
    {'name': 'Fruits', 'icon': '🍌', 'color': const Color(0xFFE8F5E9)},
    {'name': 'Grains', 'icon': '🌾', 'color': const Color(0xFFFFF3E0)},
    {'name': 'Herbs', 'icon': '🌿', 'color': const Color(0xFFE0F2F1)},
  ];

  // Dummy Data for Products
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Berries',
      'price': 'Rs.500',
      'rating': 4.5,
      'reviews': 672,
      'image': 'https://images.unsplash.com/photo-1596591606975-97ee5cef3a1e?auto=format&fit=crop&q=80&w=300'
    },
    {
      'name': 'Oranges',
      'price': 'Rs.100',
      'rating': 4.9,
      'reviews': 324,
      'image': 'https://plus.unsplash.com/premium_photo-1675365595481-809eff408d96?q=80&w=687&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'
    },
    {
      'name': 'Fresh Milk',
      'price': 'Rs.120',
      'rating': 4.7,
      'reviews': 120,
      'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&q=80&w=300'
    },
    {
      'name': 'Tomatoes',
      'price': 'Rs.80',
      'rating': 4.3,
      'reviews': 450,
      'image': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=300'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Logo + Icons)
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. Search Bar
              _buildSearchBar(),
              const SizedBox(height: 20),

              // 3. Promo Banner (Farmer)
              _buildPromoBanner(),
              const SizedBox(height: 20),

              // 4. Categories Section
              _buildSectionHeader('Categories', () {}),
              const SizedBox(height: 10),
              _buildCategoriesList(),
              const SizedBox(height: 20),

              // 5. Browse Products Section
              _buildSectionHeader('Browse Products', () {}),
              const SizedBox(height: 10),
              _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Components ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'DOOKO',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00AA00), // Custom Green
            letterSpacing: 1.0,
          ),
        ),
        Row(
          children: [
            // Cart Icon with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withValues(alpha:0.5)),
                  ),
                  child: const Icon(Icons.shopping_basket_outlined, color: Colors.green),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '4',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            // Notification Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.black54),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search..',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter Button
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(Icons.tune, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Beige background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background illustration elements (abstract curves)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFAFB42B).withValues(alpha:0.8),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
            ),
          ),

          // Text Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Are you a',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: const Color(0xFF00897B),
                  child: const Text('Farmer ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sell your\nProducts here',
                  style: TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),

          // Illustration Placeholder (Right side)
          Positioned(
            right: 10,
            bottom: 0,
            child: SizedBox(
              height: 140,
              width: 120,
              // Using a placeholder icon , add a person image here later
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/2829/2829824.png',
                fit: BoxFit.contain,
                errorBuilder: (c,o,s) => const Icon(Icons.person, size: 80),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            'View all',
            style: TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cat['color'],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                // Use circle avatar for image placeholder
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  radius: 16,
                  child: Text(cat['icon'], style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Text(
                  cat['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Important inside SingleChildScrollView
      shrinkWrap: true,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Adjusts height of the card
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Container
        Expanded(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(product['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, size: 20, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product['name'],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product['price'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  "${product['rating']} (${product['reviews']})",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          ],
        )
      ],
    );
  }}
