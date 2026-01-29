import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showAddress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileTextField(
              icon: Icons.person_outline,
              hintText: 'Hari Bahadur',
            ),
            const SizedBox(height: 16),
            _buildProfileTextField(
              icon: Icons.email_outlined,
              hintText: 'Email address',
            ),
            const SizedBox(height: 16),
            _buildProfileTextField(
              icon: Icons.phone_outlined,
              hintText: 'Phone number',
            ),
            const SizedBox(height: 16),
            _buildProfileTextField(
              icon: Icons.location_on_outlined,
              hintText: 'Address',
            ),
            const SizedBox(height: 16),
            _buildProfileTextField(
              icon: Icons.notes_outlined,
              hintText: 'Zip code',
            ),
            const SizedBox(height: 16),
            _buildProfileTextField(
              icon: Icons.map_outlined,
              hintText: 'City',
            ),
            const SizedBox(height: 16),
            _buildCountryDropdown(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Show Address',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _showAddress,
                  onChanged: (value) {
                    setState(() {
                      _showAddress = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Handle add address
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB2FF59), // Light Green
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add address',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTextField({required IconData icon, required String hintText}) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hintText,
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Row(
      children: [
        const Icon(Icons.public_outlined, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButton<String>(
            value: null, // You can manage state for selected country
            isExpanded: true,
            hint: const Text('Country', style: TextStyle(color: Colors.grey)),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            underline: const SizedBox(),
            items: <String>['USA', 'Canada', 'Nepal', 'India']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                // handle country change
              });
            },
          ),
        ),
      ],
    );
  }
}
