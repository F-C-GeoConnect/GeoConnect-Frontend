import 'package:geo_connect/models/produce_listing.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProduceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Search nearby produce (main consumer feature)
  Future<List<ProduceListing>> searchNearbyProduce({
    required LatLng userLocation,
    double radiusKm = 10.0,
    String? searchQuery,
  }) async {
    final response = await _supabase.rpc('nearby_produce', params: {
      'lat': userLocation.latitude,
      'long': userLocation.longitude,
      'radius_km': radiusKm,
      'produce_name': searchQuery,
    });

    return (response as List)
        .map((json) => ProduceListing.fromJson(json))
        .toList();
  }

  // Create listing (farmer only)
  Future<ProduceListing> createListing({
    required String name,
    required double price,
    double? quantity,
    String? unit,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('produce_listings')
        .insert({
      'user_id': userId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'description': description,
    })
        .select()
        .single();

    return ProduceListing.fromJson(response);
  }

  // Get user's own listings (farmer view)
  Future<List<ProduceListing>> getMyListings() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('produce_listings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ProduceListing.fromJson(json))
        .toList();
  }

  // Update listing
  Future<void> updateListing(String listingId, Map<String, dynamic> updates) async {
    await _supabase
        .from('produce_listings')
        .update(updates)
        .eq('id', listingId);
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    await _supabase
        .from('produce_listings')
        .delete()
        .eq('id', listingId);
  }

  // Real-time subscription for new listings nearby
  RealtimeChannel subscribeToNearbyListings({
    required Function(List<ProduceListing>) onNewListings,
  }) {
    return _supabase
        .channel('produce_listings')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'produce_listings',
      callback: (payload) async {
        // Re-fetch nearby produce when new listing added
        // You'd need to pass user location here
      },
    )
        .subscribe();
  }
}