import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_constants.dart';
import 'navigation/app_routes.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';
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
      ],
      child: const FoodApp(),
    ),
  );
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const SplashScreen(),
      ),
    );
  }
}
