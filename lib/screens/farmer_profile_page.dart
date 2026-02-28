import 'package:flutter/material.dart';
import 'main_screen/chat_page.dart';

class FarmerProfilePage extends StatelessWidget {
  final String farmerId;
  final String farmerName;

  // Mock data for products. In a real app, this would come from a database.
  final List<Map<String, dynamic>> products = [
    {'name': '1 Dozen of Banana', 'quantity': 100, 'image': 'assets/banana.png'},
    {'name': 'Bell peppers', 'quantity': 20, 'image': 'assets/peppers.png'},
  ];

  FarmerProfilePage({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total product sold (sum of quantities in this mock-up)
    int totalSold = products.fold(0, (sum, item) => sum + (item['quantity'] as int));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildFarmerHeader(context),
            const SizedBox(height: 10),
            _buildRatingSection(),
            const SizedBox(height: 20),
            _buildSalesStatsCard(totalSold),
            const SizedBox(height: 20),
            _buildSectionTitle('Farmer\'s Products'),
            ...products.map((product) => _buildProductItem(
                  product['name'],
                  '${product['quantity']} units',
                  product['image'],
                )),
            const SizedBox(height: 10),
            const Text('More products', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://via.placeholder.com/150')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Row(
                  children: [
                    Text('Product review ',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Icon(Icons.star, color: Colors.orange, size: 14),
                    Text(' 4.0',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverId: farmerId,
                    farmerName: farmerName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Rating',
              style: TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          Row(
            children: List.generate(
                5,
                (index) => Icon(
                      Icons.star,
                      color: index < 4 ? Colors.orangeAccent : Colors.grey.shade300,
                      size: 30,
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesStatsCard(int totalSold) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long, color: Colors.green),
          ),
          const SizedBox(width: 12),
          const Text('Total Product sold', style: TextStyle(fontSize: 16)),
          const Spacer(),
          Text('$totalSold units',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
          child: Text(title,
              style:
                  const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildProductItem(String name, String quantityInfo, String imagePath) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.image),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(quantityInfo, style: const TextStyle(color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
          onPressed: () {
            // TODO: Implement delete functionality
          },
        ),
      ),
    );
  }
}
