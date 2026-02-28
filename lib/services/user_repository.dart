import 'package:geo_connect/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with role selection
  Future<AuthResponse> signUp({
    required String phone,
    required String password,
    required String name,
    required UserRole role,
    LatLng? location,
  }) async {
    final authResponse = await _supabase.auth.signUp(
      phone: phone,
      password: password,
    );

    if (authResponse.user != null) {
      await _supabase.from('profiles').insert({
        'id': authResponse.user!.id,
        'name': name,
        'phone': phone,
        'role': role.name,
        'location': location != null
            ? 'POINT(${location.longitude} ${location.latitude})'
            : null,
      });
    }

    return authResponse;
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(response);
  }

  // Update user role (farmer ↔ consumer ↔ both)
  Future<void> updateRole(String userId, UserRole newRole) async {
    await _supabase
        .from('profiles')
        .update({'role': newRole.name})
        .eq('id', userId);
  }

  // Update location
  Future<void> updateLocation(String userId, LatLng location) async {
    await _supabase
        .from('profiles')
        .update({
      'location': 'POINT(${location.longitude} ${location.latitude})',
    })
        .eq('id', userId);
  }

  // Find nearby farmers
  Future<List<UserProfile>> getNearbyFarmers({
    required LatLng userLocation,
    double radiusKm = 10.0,
  }) async {
    final response = await _supabase.rpc('nearby_users', params: {
      'lat': userLocation.latitude,
      'long': userLocation.longitude,
      'radius_km': radiusKm,
      'user_role': 'farmer',
    });

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }
}