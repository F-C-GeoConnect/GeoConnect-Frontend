import 'package:flutter/material.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  // Dummy Data
  final List<Map<String, dynamic>> myProducts = [
    {
      'id': 1,
      'name': '1 Dozen of Banana',
      'price': 'Rs.100',
      'qty': 1,
      'image': 'https://images.unsplash.com/photo-1587132137056-bfbf0166836e?auto=format&fit=crop&q=80&w=200',
    },
    {
      'id': 2,
      'name': 'Bell peppers',
      'price': 'Rs.20',
      'qty': 1,
      'image': 'https://images.unsplash.com/photo-1563565375-f3fdf5bcd474?auto=format&fit=crop&q=80&w=200',
    },
    {
      'id': 3,
      'name': '1 kg of Orange',
      'price': 'Rs.140',
      'qty': 1,
      'image': 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&q=80&w=200',
    },
    {
      'id': 4,
      'name': '6 Piece of lemon',
      'price': 'Rs.60',
      'qty': 1,
      'image': 'https://images.unsplash.com/photo-1595855709940-08d717271367?auto=format&fit=crop&q=80&w=200',
    },
  ];

  // Logic to increment quantity
  void _incrementQty(int index) {
    setState(() {
      myProducts[index]['qty']++;
    });
  }

  // Logic to remove item (simulating the trash icon behavior)
  void _removeItem(int index) {
    setState(() {
      myProducts.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removed from listings'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            children: [
              // 1. User Profile Header
              _buildUserHeader(),
              const SizedBox(height: 25),

              // 2. Product List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                // Scroll handled by SingleChildScrollView
                shrinkWrap: true,
                itemCount: myProducts.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildProductItem(index);
                },
              ),

              const SizedBox(height: 30),

              // 3. Bottom Text Section
              Text(
                "Most sold products",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=100'),
          ),
          const SizedBox(width: 12),

          // User Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dolly Chaiwala',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Row(
                children: const [
                  Text(
                    'Product review ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Icon(Icons.star, color: Colors.amber, size: 14),
                  Text(
                    ' 3.8',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),

          const Spacer(),

          // Action Buttons (Chat/Call)
          _buildCircleAction(Icons.chat_bubble_outline),
          const SizedBox(width: 8),
          _buildCircleAction(Icons.phone_outlined),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon, size: 18, color: Colors.black54),
    );
  }

  Widget _buildProductItem(int index) {
    final product = myProducts[index];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Subtle shadow to separate items like in the design
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image Container
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product['image'],
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) =>
                const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['price'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Control
          Container(
            height: 36,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trash / Remove Button
                IconButton(
                  icon: const Icon(
                      Icons.delete_outline, size: 18, color: Colors.black87),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  onPressed: () => _removeItem(index),
                ),

                // Qty Text
                Text(
                  '${product['qty']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),

                // Add Button
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: Colors.black87),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  onPressed: () => _incrementQty(index),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
