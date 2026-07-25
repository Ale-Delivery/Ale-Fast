import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_constants.dart';
import 'models/models.dart';
import 'navigation/app_routes.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/phone_auth_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/details_screen.dart';
import 'screens/food_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/delivery_address_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_placed_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/location_picker_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const AleClientApp(),
    ),
  );
}

class AleClientApp extends StatelessWidget {
  const AleClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'ALE FAST',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: AppRoutes.splash,
          routes: {
            // ── Parameterless screens ──────────────────────────────
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.onboarding: (_) => const OnboardingScreen(),
            AppRoutes.phoneAuth: (_) => const PhoneAuthScreen(),
            AppRoutes.profileSetup: (_) => const ProfileSetupScreen(),
            AppRoutes.home: (_) => const HomeScreen(),
            AppRoutes.search: (_) => const SearchScreen(),
            AppRoutes.cart: (_) => const CartScreen(),
            AppRoutes.orderHistory: (_) => const OrderHistoryScreen(),
            AppRoutes.profile: (_) => const ProfileScreen(),
            AppRoutes.locationPicker: (_) => const LocationPickerScreen(),
          },
          onGenerateRoute: _generateRoute,
          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          ),
        );
      },
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.verification:
        final args = settings.arguments as Map<String, String>;

        return MaterialPageRoute(
          builder: (_) => VerificationScreen(
            phoneNumber: args['phone']!,
          ),
        );

      case AppRoutes.restaurantDetails:
        final restaurant = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DetailsScreen(restaurant: restaurant),
        );

      case AppRoutes.foodDetail:
        final food = settings.arguments as FoodItem;
        return MaterialPageRoute(
          builder: (_) => FoodDetailScreen(food: food),
        );

      case AppRoutes.deliveryAddress:
        final proceedToCheckout = settings.arguments as bool? ?? true;
        return MaterialPageRoute(
          builder: (_) =>
              DeliveryAddressScreen(proceedToCheckout: proceedToCheckout),
        );

      case AppRoutes.checkout:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            deliveryAddress: args['deliveryAddress'] as String,
            deliveryPhone: args['deliveryPhone'] as String,
            deliveryNotes: args['deliveryNotes'] as String?,
            addressLabel: args['addressLabel'] as String? ?? 'Home',
            deliveryLatitude: args['deliveryLatitude'] as double?,
            deliveryLongitude: args['deliveryLongitude'] as double?,
            savedAddressId: args['savedAddressId'] as String?,
          ),
        );

      case AppRoutes.orderPlaced:
        final order = settings.arguments as Order;
        return MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(order: order),
        );

      case AppRoutes.orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
        );

      default:
        return null;
    }
  }
}
