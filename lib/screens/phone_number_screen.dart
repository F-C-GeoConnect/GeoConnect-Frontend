import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';

import 'package:flutter/material.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({Key? key}) : super(key: key);

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  String _phoneNumber = '';

  void _onNumberTap(String number) {
    setState(() {
      if (_phoneNumber.length < 15) { // Limit phone number length
        _phoneNumber += number;
      }
    });
  }

  void _onBackspace() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  void _onNext() {
    if (_phoneNumber.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(phoneNumber: _phoneNumber),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F5E9).withValues(alpha: 0.3),
              Colors.white,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button and header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'Enter your mobile number',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Mobile Number label
                    Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Phone number display with cursor
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          Text(
                            _phoneNumber.isEmpty ? '' : _phoneNumber,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 2,
                            ),
                          ),
                          // Blinking cursor
                          if (_phoneNumber.isNotEmpty)
                            Container(
                              width: 2,
                              height: 24,
                              margin: const EdgeInsets.only(left: 2),
                              color: Colors.black,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Underline
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Next button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF66BB6A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Number pad
              _buildNumberPad(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            children: [
              _buildNumberKey('1', ''),
              const SizedBox(width: 12),
              _buildNumberKey('2', 'ABC'),
              const SizedBox(width: 12),
              _buildNumberKey('3', 'DEF'),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: 4, 5, 6
          Row(
            children: [
              _buildNumberKey('4', 'GHI'),
              const SizedBox(width: 12),
              _buildNumberKey('5', 'JKL'),
              const SizedBox(width: 12),
              _buildNumberKey('6', 'MNO'),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: 7, 8, 9
          Row(
            children: [
              _buildNumberKey('7', 'PQRS'),
              const SizedBox(width: 12),
              _buildNumberKey('8', 'TUV'),
              const SizedBox(width: 12),
              _buildNumberKey('9', 'WXYZ'),
            ],
          ),
          const SizedBox(height: 12),

          // Row 4: +*#, 0, backspace
          Row(
            children: [
              _buildSpecialKey('+*#'),
              const SizedBox(width: 12),
              _buildNumberKey('0', ''),
              const SizedBox(width: 12),
              _buildBackspaceKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberKey(String number, String letters) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNumberTap(number),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (letters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    letters,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Handle special characters if needed
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Expanded(
      child: GestureDetector(
        onTap: _onBackspace,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
