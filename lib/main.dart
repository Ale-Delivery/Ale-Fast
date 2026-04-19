import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';

// ── Import previous auth screens ──────────────────────────────
// The auth screens (splash, onboarding, login, signup, verify,
// forgot_password) from Part 1 are still used here.
// Copy them from food_app_v1 into this project's lib/screens/.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase Init ─────────────────────────────────────────
  // 1. Go to https://supabase.com and create a free project
  // 2. Go to Project Settings → API
  // 3. Copy your URL and anon key below
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
      home: const SplashScreen(),
    );
  }
}
