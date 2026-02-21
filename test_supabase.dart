import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'YOUR_SUPABASE_URL',
    'YOUR_SUPABASE_ANON_KEY',
  );

  // Actually we shouldn't use a random anon key if we don't have it.
}
