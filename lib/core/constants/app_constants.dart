/// Central place for all Supabase configuration constants.
///
/// The anon key is intentionally public — it is safe to ship in the client
/// because Supabase RLS policies are the actual security layer.
/// The service role key is NEVER placed here; it lives only in edge functions.
class AppConstants {
  AppConstants._();

  // ── Supabase ───────────────────────────────────────────────────────────────
  static const supabaseUrl = 'https://bcewqlfuqmrcbgfbyjwo.supabase.co';

  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjZXdxbGZ1cW1yY2JnZmJ5andvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4NTI2MTEsImV4cCI6MjA4NDQyODYxMX0'
      '.42as-LufMRQDbOXk5qHpskjm4hyTRYDDSEu8Qz4CygY';

  static const functionsBaseUrl = '$supabaseUrl/functions/v1';
}
