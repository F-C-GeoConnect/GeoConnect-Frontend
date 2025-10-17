import 'package:flutter/material.dart';

class LoginScreen2 extends StatefulWidget {
  final bool isNepali;
  const LoginScreen2({super.key, this.isNepali = false});

  @override
  State<LoginScreen2> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen2>
    with SingleTickerProviderStateMixin {
  late bool _isNepali;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isNepali = widget.isNepali;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  void _toggleLanguage() {
    setState(() {
      _isNepali = !_isNepali;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _isNepali
        ? {
      "title": "GeoConnect मा स्वागत छ",
      "subtitle": "फेरि स्वागत छ",
      "hintEmail": "इमेल",
      "hintPassword": "पासवर्ड",
      "forgot": "पासवर्ड बिर्सिनुभयो?",
      "signin": "साइन इन",
      "noAccount": "खाता छैन?",
      "signup": "साइन अप",
      "lang": "Nepali"
    }
        : {
      "title": "Welcome to GeoConnect",
      "subtitle": "Welcome Back",
      "hintEmail": "Email",
      "hintPassword": "Password",
      "forgot": "Forgot Password?",
      "signin": "Sign In",
      "noAccount": "Don’t have an account?",
      "signup": "Sign Up",
      "lang": "English"
    };

    return Scaffold(
      backgroundColor: const Color(0xFF00A86B), // main green background
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🌐 Language toggle
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _toggleLanguage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t["lang"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.language, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Card container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.public, size: 60, color: Color(0xFF00A86B)),
                        const SizedBox(height: 12),
                        Text(
                          t["title"]!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A86B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t["subtitle"]!,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),

                        // Email field
                        TextField(
                          decoration: InputDecoration(
                            labelText: t["hintEmail"],
                            prefixIcon: const Icon(Icons.email_outlined),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF00A86B), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: t["hintPassword"],
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: const Icon(Icons.visibility_off),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF00A86B), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: const Color(0xFF00A86B),
                            ),
                            child: Text(t["forgot"]!),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Sign In Button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A86B),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            t["signin"]!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sign up text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t["noAccount"]!),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00A86B),
                              ),
                              child: Text(t["signup"]!),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
