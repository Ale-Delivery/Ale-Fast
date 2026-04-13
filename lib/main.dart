import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/phone_input_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(
    const ProviderScope(
      child: DeliveryApp(),
    ),
  );
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFE60000);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alee App - Delivery',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryRed,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryRed,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const PhoneInputScreen(),
    );
  }
}