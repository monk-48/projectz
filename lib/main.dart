import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/environment.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'config/firebase_options.dart';
import 'splashScreen/splashScreen.dart';
import 'core/utils/logger.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('Firebase initialized successfully');

    // Initialize Supabase
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
    Logger.info('Supabase initialized successfully');

    // Initialize Service Locator
    await ServiceLocator().init();
    Logger.info('Service locator initialized successfully');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    Logger.error('Initialization error', error: e, stackTrace: stackTrace);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'Seller App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MySplashScreen(),
      ),
    );
  }
}
