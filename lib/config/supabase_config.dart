// Supabase Configuration
// DEPRECATED: Use Environment class instead
// This file is kept for backward compatibility
// Get these values from: https://app.supabase.com/project/YOUR_PROJECT/settings/api

import '../core/config/environment.dart';

class SupabaseConfig {
  // Your Supabase project credentials
  // Using Environment class for better configuration management
  static String get supabaseUrl => Environment.supabaseUrl;
  static String get supabaseAnonKey => Environment.supabaseAnonKey;
}
