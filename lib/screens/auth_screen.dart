import 'package:flutter/material.dart';
import 'package:geo_connect/screens/phone_number_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
            children: [
        // Tab Bar
        Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7ED321),
          indicatorWeight: 2.5,
          labelColor: const Color(0xFF7ED321),
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Log in'),
            Tab(text: 'Sign up'),
          ],
        ),
      ),

      // Form Content
      Expanded(
          child: TabBarView(
              controller: _tabController,
              children: [
          // Login Tab (placeholder)
          const Center(child: Text('Login Form')),

      // Sign Up Tab
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create an account to continue!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 30),

                // Full Name Field
                _buildLabel('Full Name'),
                _buildTextField(
                  controller: _nameController,
                ),
                const SizedBox(height: 20),

                // Email Field
                _buildLabel('Email'),
                _buildTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Date of Birth Field
                _buildLabel('Date of Birth'),
                _buildTextField(
                  controller: _dobController,
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today_outlined,
                        color: Colors.grey.shade400, size: 18),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 20),

                // Phone Number Field
                _buildLabel('Phone Number'),
                _buildTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_drop_down,
                            color: Colors.grey.shade600, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Set Password Field
                _buildLabel('Set Password'),
                _buildTextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Register as a Farmer Button
                _buildButton(
                  text: 'Register as a Farmer',
                  onPressed: () {
                    // Handle farmer registration
                  },
                ),
                const SizedBox(height: 12),

                // Register as a Consumer Button
                _buildButton(
                  text: 'Register as a Consumer',
                  onPressed: () {
                    // Handle consumer registration
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
              ],
      ),
    ),

    // Bottom links - Fixed at bottom, always visible
    Container(
    padding: const EdgeInsets.only(bottom: 20),
    color: Colors.white,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    // Already have an account
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Text(
    'Already have an account? ',
    style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 13,
    ),
    ),
    GestureDetector(
    onTap: () {
    _tabController.animateTo(0);
    },
    child: const Text(
    'Login',
    style: TextStyle(
    color: Color(0xFF7ED321),
    fontSize: 13,
    fontWeight: FontWeight.w600,
    ),
    ),
    ),
    ],
    ),
    const SizedBox(height: 8),

    // Use Phone number
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
          );
        },
        child: const Text(
          'Use Phone number?',
          style: TextStyle(
            color: Color(0xFF7ED321),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
    ),
    ),
    ],
    ),
    ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7ED321),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}