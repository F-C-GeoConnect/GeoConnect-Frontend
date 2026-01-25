import 'package:flutter/material.dart';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  final List<String> zones = [
    'Bagmati',
    'Gandaki',
    'Lumbini',
    'Karnali',
    'Sudurpashchim',
    'Province 1',
    'Madhesh'
  ];

  @override
  void initState() {
    super.initState();
    _zoneController.text = 'Bagmati';
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_zoneController.text.isEmpty || _areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to role selection or dashboard
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RoleSelectionScreen()));
    print('Zone: ${_zoneController.text}, Area: ${_areaController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Map Icon Illustration
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Map background illustration
                            Container(
                              height: 140,
                              width: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/map_illustration.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              child: CustomPaint(
                                painter: MapPainter(),
                              ),
                            ),

                            // Location pin
                            Positioned(
                              top: 20,
                              child: Container(
                                height: 70,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(35),
                                    topRight: Radius.circular(35),
                                    bottomLeft: Radius.circular(35),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      const Text(
                        'Select Your Location',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      const Text(
                        'Switch on your location to stay in tune with\nwhat\'s happening in your area',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Your Zone Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Zone',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _zoneController.text.isEmpty ? null : _zoneController.text,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                              items: zones.map((String zone) {
                                return DropdownMenuItem<String>(
                                  value: zone,
                                  child: Text(zone),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _zoneController.text = newValue ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Your Area Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Area',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _areaController,
                            decoration: InputDecoration(
                              hintText: 'Type in your area',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.green.shade400,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5FB574),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

// Custom painter for map illustration
class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Green area
    paint.color = const Color(0xFF81C784);
    final greenPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height)
      ..lineTo(0, size.height * 0.8)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow area
    paint.color = const Color(0xFFFDD835);
    final yellowPath = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.6, size.height * 0.2)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(0, size.height * 0.3)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Blue area
    paint.color = const Color(0xFF64B5F6);
    final bluePath = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Gray roads
    paint.color = const Color(0xFFE0E0E0);
    paint.strokeWidth = 8;
    paint.style = PaintingStyle.stroke;

    final road1 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.6, size.height);
    canvas.drawPath(road1, paint);

    final road2 = Path()
      ..moveTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(0, size.height * 0.6);
    canvas.drawPath(road2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}