import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  /// A method to determine the current position of the device.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Near You'),
        elevation: 0,
      ),
      body: FutureBuilder<Position>(
        future: _determinePosition(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Could not fetch location.'));
          }

          final userLocation = LatLng(snapshot.data!.latitude, snapshot.data!.longitude);

          return ProductMap(userLocation: userLocation);
        },
      ),
    );
  }
}

// Extracted the map into its own widget for better organization
class ProductMap extends StatefulWidget {
  final LatLng userLocation;
  const ProductMap({super.key, required this.userLocation});

  @override
  State<ProductMap> createState() => _ProductMapState();
}

class _ProductMapState extends State<ProductMap> {
  late final Stream<List<Map<String, dynamic>>> _productsStream;

  @override
  void initState() {
    super.initState();
    // The correct way to filter a stream on the client-side.
    _productsStream = Supabase.instance.client
        .from('products')
        .stream(primaryKey: ['id'])
    // Use a .map transform to filter the list of results from the stream
        .map((listOfMaps) {
      return listOfMaps
          .where((map) => map['location'] != null)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];

        // Create markers for the products with conditional styling
        final productMarkers = products.map((product) {
          final pointString = product['location'] as String?;
          if (pointString == null) return null;

          final coords = pointString.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
          if (coords.length != 2) return null;

          final longitude = double.tryParse(coords[0]);
          final latitude = double.tryParse(coords[1]);

          if (latitude == null || longitude == null) return null;

          final sellerId = product['sellerID'] as String?;
          final isOwnProduct = sellerId == currentUserId;

          return Marker(
            width: 40.0,
            height: 40.0,
            alignment: Alignment.topCenter,
            point: LatLng(latitude, longitude),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(product['productName'] ?? 'No name')),
                );
              },
              // --- Updated Marker Logic ---
              child: isOwnProduct
                  ? Image.asset('assets/map_pointer.png') // User's own products
                  : const Icon( // Other users' products
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
          );
        }).whereType<Marker>().toList();

        // Create a separate marker for the user's current location with a blue pointer
        final userLocationMarker = Marker(
          point: widget.userLocation,
          child: const Icon(
            Icons.location_on, // Standard pointer
            color: Colors.blue,   // Blue color for the user
            size: 40,
          ),
        );

        return FlutterMap(
          options: MapOptions(
            initialCenter: widget.userLocation, // Center on user's location
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.untitled1', // Replace with your actual package name if different
            ),
            MarkerLayer(
              // Combine the user's location marker with the product markers
              markers: [userLocationMarker, ...productMarkers],
            ),
          ],
        );
      },
    );
  }
}