class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iwwlurvyuxwokusgjull.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3d2x1cnZ5dXh3b2t1c2dqdWxsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2ODk4MDcsImV4cCI6MjA3ODI2NTgwN30.PB-EmOEhhceAAAME5fc-0-eDekKHP-CLdRcswt29vno',
  );

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
}

