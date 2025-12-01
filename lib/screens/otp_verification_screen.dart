import 'package:flutter/material.dart';

import 'location_selector.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otpCode = '';
  final int _otpLength = 4;

  void _onNumberTap(String number) {
    setState(() {
      if (_otpCode.length < _otpLength) {
        _otpCode += number;
      }
    });
  }

  void _onBackspace() {
    if (_otpCode.isNotEmpty) {
      setState(() {
        _otpCode = _otpCode.substring(0, _otpCode.length - 1);
      });
    }
  }

  void _onNext() {
    if (_otpCode.length == _otpLength) {
      // Verify OTP and navigate to location screen
      print('OTP entered: $_otpCode');
       Navigator.push(context, MaterialPageRoute(builder: (_) => LocationSelectionScreen()));
    } else {
      // Show error - OTP incomplete
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete 4-digit code')),
      );
    }
  }

  void _resendCode() {
    // Handle resend OTP logic
    print('Resending OTP to ${widget.phoneNumber}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code sent!')),
    );
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
                      'Enter your 4-digit code',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Code label
                    Text(
                      'Code',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // OTP display with dashes
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: List.generate(_otpLength, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              index < _otpCode.length ? _otpCode[index] : '-',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: index < _otpCode.length
                                    ? Colors.black
                                    : Colors.grey.shade400,
                                letterSpacing: 2,
                              ),
                            ),
                          );
                        }),
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

              // Resend Code and Next button row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Resend Code button
                    TextButton(
                      onPressed: _resendCode,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Next button
                    GestureDetector(
                      onTap: _onNext,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF66BB6A).withValues(alpha: 0.3),
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
                  ],
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
                color: Colors.black.withValues(alpha: 0.05),
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