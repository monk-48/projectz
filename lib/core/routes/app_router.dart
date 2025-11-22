import 'package:flutter/material.dart';
import 'package:projectz/authentication/authScreen.dart';
import 'package:projectz/mainScreens/homeScreen.dart';
import 'package:projectz/mainScreens/inventoryScreen.dart';
import 'package:projectz/mainScreens/addInventoryScreen.dart';
import 'package:projectz/splashScreen/splashScreen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const MySplashScreen(),
          settings: settings,
        );

      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case AppRoutes.inventory:
        return MaterialPageRoute(
          builder: (_) => const InventoryScreen(),
          settings: settings,
        );

      case AppRoutes.addInventory:
        return MaterialPageRoute(
          builder: (_) => const AddInventoryScreen(),
          settings: settings,
        );

      case AppRoutes.editInventory:
        final itemId = settings.arguments as String?;
        // TODO: Implement EditInventoryScreen
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Edit Inventory')),
            body: Center(
              child: Text('Edit Inventory Screen - Coming Soon\nItem ID: $itemId'),
            ),
          ),
          settings: settings,
        );

      case AppRoutes.orders:
        // TODO: Implement OrdersScreen
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Orders')),
            body: const Center(
              child: Text('Orders Screen - Coming Soon'),
            ),
          ),
          settings: settings,
        );

      case AppRoutes.orderDetails:
        final orderId = settings.arguments as String?;
        // TODO: Implement OrderDetailsScreen
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: Center(
              child: Text('Order Details Screen - Coming Soon\nOrder ID: $orderId'),
            ),
          ),
          settings: settings,
        );

      case AppRoutes.analytics:
        // TODO: Implement AnalyticsScreen
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Analytics')),
            body: const Center(
              child: Text('Analytics Screen - Coming Soon'),
            ),
          ),
          settings: settings,
        );

      case AppRoutes.profile:
        // TODO: Implement ProfileScreen
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(
              child: Text('Profile Screen - Coming Soon'),
            ),
          ),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
          settings: settings,
        );
    }
  }
}

