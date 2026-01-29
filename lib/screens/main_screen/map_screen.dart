import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FarmerMapScreen extends StatefulWidget {
  const FarmerMapScreen({super.key});

  @override
  State<FarmerMapScreen> createState() => _FarmerMapScreenState();
}

class _FarmerMapScreenState extends State<FarmerMapScreen> {
  // Controller to move the map programmatically
  final MapController _mapController = MapController();

  // Default location (Kathmandu) until GPS is fetched
  LatLng _currentLocation = const LatLng(27.7172, 85.3240);
  bool _isLoading = true;
  List<Marker> _farmerMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // 1. Get User Permission and Location
  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get actual coordinates
    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    // Move map to user
    _mapController.move(_currentLocation, 14.0);

    // Fetch farmers near this location
    _fetchNearbyFarmers();
  }

  // 2. Fetch Data (Simulating connection to your Node.js/MongoDB Backend)
  Future<void> _fetchNearbyFarmers() async {
    // In a real scenario, you call your Node.js API:
    // final response = await http.get(Uri.parse('http://YOUR_IP:3000/api/farmers/nearby?lat=${_currentLocation.latitude}&lng=${_currentLocation.longitude}'));

    // MOCK DATA: Simulating the JSON response described in your PDF structure
    // This represents the data coming from MongoDB $near query
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final List<Map<String, dynamic>> mockData = [
      {
        "farmerName": "Ram Bahadur",
        "produce": "Fresh Tomatoes",
        "price": "Rs 50/kg",
        "status": "Harvested this morning, available until 5 PM.",
        "location": {"lat": _currentLocation.latitude + 0.002, "lng": _currentLocation.longitude + 0.002}
      },
      {
        "farmerName": "Sita Devi",
        "produce": "Organic Spinach",
        "price": "Rs 80/bunch",
        "status": "Limited stock left!",
        "location": {"lat": _currentLocation.latitude - 0.003, "lng": _currentLocation.longitude + 0.001}
      },
      {
        "farmerName": "Hari Krishna",
        "produce": "Local Potatoes",
        "price": "Rs 45/kg",
        "status": "Bulk orders available.",
        "location": {"lat": _currentLocation.latitude + 0.001, "lng": _currentLocation.longitude - 0.004}
      },
    ];

    // Convert JSON data to Flutter Map Markers
    List<Marker> newMarkers = mockData.map((data) {
      return Marker(
        point: LatLng(data['location']['lat'], data['location']['lng']),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showFarmerDetails(data),
          child: const Icon(
            Icons.location_on,
            color: Colors.green, // Green for Agriculture
            size: 45,
          ),
        ),
      );
    }).toList();

    // Add a marker for the "You are here" user
    newMarkers.add(
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: const Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );

    setState(() {
      _farmerMarkers = newMarkers;
    });
  }

  // 3. Show Details (The "Status" Popup)
  void _showFarmerDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['farmerName'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.shopping_basket, color: Colors.green),
                  const SizedBox(width: 10),
                  Text("${data['produce']} - ${data['price']}", style: const TextStyle(fontSize: 18)),
                ],
              ),
              const Divider(),
              const Text("Status Update:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(data['status'], style: const TextStyle(fontSize: 16)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic to Chat or Order (as per PDF requirements)
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting to farmer...")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Contact Farmer", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Farmers"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation, // Center map on user
          initialZoom: 14.0,
        ),
        children: [
          // Layer 1: OpenStreetMap Tiles (Free)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.farmerapp', // Replace with your package name
          ),
          // Layer 2: The Markers (User + Farmers)
          MarkerLayer(
            markers: _farmerMarkers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _initializeLocation,
        backgroundColor: Colors.green,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}