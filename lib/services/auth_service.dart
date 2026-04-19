import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Supabase client eka hadagannawa
  final _supabase = Supabase.instance.client;

  // Danata inna user wa ganna property ekak
  User? get currentUser => _supabase.auth.currentUser;

  // Mock OTP eka yawana function eka
  Future<String> sendDummyOTP(String phoneNumber) async {
    // Testing walata dummy OTP ekak (e.g., 1234)
    String dummyOtp = "1234";

    // Terminal eke balaganna print karanawa
    print("Mock SMS: Sent to $phoneNumber | OTP Code: $dummyOtp");

    // Podi loading time ekak denawa real wada karanawa wage penna
    await Future.delayed(const Duration(seconds: 2));

    return dummyOtp;
  }

  // OTP eka hari nam User wa Supabase eke save/login karana function eka
  Future<bool> loginWithPhone(String phoneNumber) async {
    // 1. Phone number eke space thiyenawanam ewa makala (trim) gannawa
    String cleanNumber = phoneNumber.trim();

    // 2. Issarahata 'user_' kiyala kallak ekathu karanawa valid email ekak widiyata penna
    String dummyEmail = "user_$cleanNumber@foodapp.com";

    String dummyPassword = "SecurePassword123!";

    try {
      // 1. Issellama log wenna try karanawa
      await _supabase.auth.signInWithPassword(
        email: dummyEmail,
        password: dummyPassword,
      );
      return false; // 👉 Sign in success nam, meya EXISTING (parana) user kenek. (Return false)
    } on AuthException catch (e) {
      // 2. Parana user kenek nattam aluthen Register karanawa
      if (e.message.contains('Invalid login credentials')) {
        await _supabase.auth.signUp(
          email: dummyEmail,
          password: dummyPassword,
        );
        return true; // 👉 Sign up kara nam, meya NEW (aluth) user kenek. (Return true)
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }
}
