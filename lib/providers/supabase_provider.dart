import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Canonical provider for SupabaseClient.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (e) {
    throw Exception('Supabase accessed before initialization: $e');
  }
});

// Alias for compatibility
final supabaseProvider = supabaseClientProvider;
