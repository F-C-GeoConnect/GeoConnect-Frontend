import 'package:geo_connect/models/user_profile.dart';
import 'package:geo_connect/models/produce_listing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all users
  Future<List<UserProfile>> getAllUsers() async {
    final response = await _supabase.from('profiles').select().order('name');
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }

  // Fetch all listings
  Future<List<ProduceListing>> getAllListings() async {
    final response = await _supabase.from('produce_listings').select().order('created_at', ascending: false);
    return (response as List).map((json) => ProduceListing.fromJson(json)).toList();
  }

  // Delete a user (Note: This usually requires a service role or edge function if deleting from auth.users)
  // For now, we'll just delete from the profile table if that's the intent, 
  // but usually, you'd disable/delete the auth user too.
  Future<void> deleteUser(String userId) async {
    await _supabase.from('profiles').delete().eq('id', userId);
  }

  // Delete a listing
  Future<void> deleteListing(String listingId) async {
    await _supabase.from('produce_listings').delete().eq('id', listingId);
  }

  // Update a user's role
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _supabase.from('profiles').update({'role': role.name}).eq('id', userId);
  }
}