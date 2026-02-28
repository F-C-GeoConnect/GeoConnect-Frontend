import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // For LatLng coordinates
import 'package:geolocator/geolocator.dart'; // For GPS
import 'package:supabase_flutter/supabase_flutter.dart'; // For Backend

class CommonMapScreen extends StatefulWidget {
  final bool isFarmer; // Pass TRUE if user is a farmer, FALSE if consumer

  const CommonMapScreen({super.key, required this.isFarmer});

  @override
  State<CommonMapScreen> createState() => _CommonMapScreenState();
}

class _CommonMapScreenState extends State<CommonMapScreen> {
  // Map Controller to move the camera programmatically
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;
  late StreamSubscription? _realtimeSubscription;

  // Default Location: Kathmandu (Used until GPS loads)
  LatLng _myLocation = const LatLng(27.7172, 85.3240);

  // List of markers to display on the map
  List<Marker> _markers = [];

  // Search settings
  final double _searchRadiusKm = 7.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _setupRealtimeListener();
  }

  // ---------------------------------------------------------------------------
  // 1. INITIALIZATION & GPS LOGIC
  // ---------------------------------------------------------------------------
  Future<void> _initializeMap() async {
    await _goToMyLocation(); // Get GPS and move map there
  }

  /// Gets current GPS location, moves the map, and fetches nearby farmers
  Future<void> _goToMyLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check permissions (Standard boilerplate)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permissions are permanently denied.');
        return;
      }

      // Get actual location
      Position pos = await Geolocator.getCurrentPosition();
      LatLng newPos = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _myLocation = newPos;
        _isLoading = false;
      });

      // Move the map camera
      _mapController.move(_myLocation, 14.0);

      // Query the database for this new location
      _fetchNearbyProduce();

    } catch (e) {
      _showSnack("Error getting location: $e");
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SUPABASE DATA LOGIC (RPC + REALTIME)
  // ---------------------------------------------------------------------------

  /// Calls the SQL function 'fetch_nearby_produce'
  Future<void> _fetchNearbyProduce() async {
    try {
      final List<dynamic> data = await supabase.rpc(
        'fetch_nearby_produce', // The SQL function name
        params: {
          'lat': _myLocation.latitude,
          'lng': _myLocation.longitude,
          'radius_km': _searchRadiusKm
        },
      );

      _updateMarkers(data);

    } catch (e) {
      print("Database Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load produce: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Listens for ANY new row inserted into 'farmer_posts'
  void _setupRealtimeListener() {
    _realtimeSubscription = supabase
        .from('farmer_posts')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> rawData) {

      // When a new post happens anywhere, we re-run our geospatial query
      // to see if it is specifically near US.
      _fetchNearbyProduce();

      // Optional: Notify the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Map updated with new produce!"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 3. MARKER LOGIC
  // ---------------------------------------------------------------------------
  void _updateMarkers(List<dynamic> farmersList) {
    List<Marker> tempMarkers = [];

    // A. Add Farmers (Green Icons)
    for (var f in farmersList) {
      tempMarkers.add(
        Marker(
          point: LatLng(f['lat'], f['lng']),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => _showFarmerDetails(f),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 2),
                      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]
                  ),
                  child: const Icon(Icons.agriculture, color: Colors.green, size: 30),
                ),
                // Tiny arrow pointing down (optional visual flair)
                const Icon(Icons.arrow_drop_down, color: Colors.green, size: 10),
              ],
            ),
          ),
        ),
      );
    }

    // B. Add "ME" (The Consumer/User) - Blue Pulsing Dot
    tempMarkers.add(
      Marker(
        point: _myLocation,
        width: 80,
        height: 80,
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.blueAccent,
          size: 50,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _markers = tempMarkers;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 4. UI BUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFarmer ? "My Farm Area" : "Find Fresh Produce"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // THE MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation,
              initialZoom: 14.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dooko.app', // Replace with your package
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // LOADING INDICATOR
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),

      // THE BUTTONS (Role Based)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Button 1: "Locate Me" (For EVERYONE)
          FloatingActionButton(
            heroTag: "locate_btn",
            onPressed: _goToMyLocation,
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            child: const Icon(Icons.my_location),
          ),

          const SizedBox(height: 16),

          // Button 2: "Post Produce" (For FARMERS ONLY)
          if (widget.isFarmer)
            FloatingActionButton.extended(
              heroTag: "post_btn",
              onPressed: () {
                // TODO: Navigate to your "Add Post" Screen
                // Navigator.push(context, MaterialPageRoute(builder: (_) => AddPostScreen()));
                _showSnack("Open 'Add Post' screen here");
              },
              label: const Text("Post Produce"),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.green[700],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. HELPER WIDGETS
  // ---------------------------------------------------------------------------

  // The Bottom Sheet Popup when you click a farmer
  void _showFarmerDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name & Distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      data['farmer_name'] ?? "Unknown Farmer",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  Chip(
                    label: Text("${(data['dist_meters'] / 1000).toStringAsFixed(1)} km"),
                    backgroundColor: Colors.green[100],
                  )
                ],
              ),
              const Divider(),

              // Produce Info
              ListTile(
                leading: const Icon(Icons.eco, color: Colors.green),
                title: Text(data['produce_type'] ?? "Produce"),
                subtitle: Text(data['price'] ?? "Price Negotiable"),
              ),

              // Status Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['status_message'] ?? "No status provided.",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),

              const Spacer(),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnack("Initiate Chat with ${data['farmer_name']}...");
                    // TODO: Navigate to Chat Screen
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text("Contact Farmer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}