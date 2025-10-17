import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLanguage = 'English';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Language translations
  Map<String, Map<String, String>> _translations = {
    'English': {
      'welcome': 'Welcome to GeoConnect',
      'signInSubtitle': 'Sign in to continue',
      'signUpSubtitle': 'Sign up to get started',
      'createAccount': 'Create Account',
      'welcomeBack': 'Welcome Back',
      'fullName': 'Full Name',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot Password?',
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'noAccount': "Don't have an account? ",
      'hasAccount': "Already have an account? ",
      'nameRequired': 'Name is required',
      'emailRequired': 'Email is required',
      'emailInvalid': 'Enter a valid email',
      'passwordRequired': 'Password is required',
      'passwordLength': 'Password must be at least 6 characters',
      'confirmPasswordRequired': 'Please confirm your password',
      'passwordMismatch': 'Passwords do not match',
      'loginSuccess': 'Login successful!',
      'registrationSuccess': 'Registration successful!',
      'passwordResetSent': 'Password reset link sent!',
    },
    'Nepali': {
      'welcome': 'GeoConnect मा स्वागत छ',
      'signInSubtitle': 'जारी राख्न साइन इन गर्नुहोस्',
      'signUpSubtitle': 'सुरु गर्न साइन अप गर्नुहोस्',
      'createAccount': 'खाता बनाउनुहोस्',
      'welcomeBack': 'फेरि स्वागत छ',
      'fullName': 'पूरा नाम',
      'email': 'इमेल',
      'password': 'पासवर्ड',
      'confirmPassword': 'पासवर्ड पुष्टि गर्नुहोस्',
      'forgotPassword': 'पासवर्ड बिर्सनुभयो?',
      'signIn': 'साइन इन',
      'signUp': 'साइन अप',
      'noAccount': 'खाता छैन? ',
      'hasAccount': 'पहिले नै खाता छ? ',
      'nameRequired': 'नाम आवश्यक छ',
      'emailRequired': 'इमेल आवश्यक छ',
      'emailInvalid': 'मान्य इमेल प्रविष्ट गर्नुहोस्',
      'passwordRequired': 'पासवर्ड आवश्यक छ',
      'passwordLength': 'पासवर्ड कम्तिमा ६ अक्षर हुनुपर्छ',
      'confirmPasswordRequired': 'कृपया आफ्नो पासवर्ड पुष्टि गर्नुहोस्',
      'passwordMismatch': 'पासवर्डहरू मेल खाँदैनन्',
      'loginSuccess': 'लगइन सफल भयो!',
      'registrationSuccess': 'दर्ता सफल भयो!',
      'passwordResetSent': 'पासवर्ड रिसेट लिङ्क पठाइयो!',
    },
  };

  String _translate(String key) {
    return _translations[_selectedLanguage]?[key] ?? key;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? _translate('loginSuccess') : _translate('registrationSuccess')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return _translate('emailRequired');
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return _translate('emailInvalid');
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _translate('passwordRequired');
    }
    if (value.length < 6) {
      return _translate('passwordLength');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return _translate('confirmPasswordRequired');
    }
    if (value != _passwordController.text) {
      return _translate('passwordMismatch');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF059669), // green-600
              Color(0xFF10B981), // green-500
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Language selector at top right
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      icon: const Icon(Icons.language, size: 20),
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                      items: <String>['English', 'Nepali']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                                ),
                              ),
                              child: const Icon(
                                Icons.language,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Welcome to GeoConnect
                            Text(
                              _translate('welcome'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              _isLogin ? _translate('welcomeBack') : _translate('createAccount'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin ? _translate('signInSubtitle') : _translate('signUpSubtitle'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Name field (only for registration)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: _translate('fullName'),
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _translate('nameRequired');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: _translate('email'),
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                ),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: _translate('password'),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password field (only for registration)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: _translate('confirmPassword'),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                  ),
                                ),
                                validator: _validateConfirmPassword,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Forgot Password (only for login)
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_translate('passwordResetSent')),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _translate('forgotPassword'),
                                    style: const TextStyle(color: Color(0xFF059669)),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  _isLogin ? _translate('signIn') : _translate('signUp'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Toggle between Login and Register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? _translate('noAccount')
                                      : _translate('hasAccount'),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextButton(
                                  onPressed: _toggleMode,
                                  child: Text(
                                    _isLogin ? _translate('signUp') : _translate('signIn'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}