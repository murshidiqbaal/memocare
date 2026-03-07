import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single, canonical provider for the SupabaseClient instance.
///
/// This provider ensures that the Supabase client is easily accessible across
/// the entire application through Riverpod dependency injection.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
