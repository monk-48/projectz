import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projectz/global/global.dart';
import 'package:projectz/splashScreen/splashScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectz/config/supabase_config.dart';
import 'package:projectz/config/firebase_options.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'seller app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MySplashScreen(),
    );
  }
}


  