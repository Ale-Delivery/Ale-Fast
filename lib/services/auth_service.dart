import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. ඇත්තටම OTP verify කරන කොටස
  Future<void> loginWithPhone(String phone, String otp) async {
    await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
  }

  // 2. Dummy OTP එක යවන Function එක 
  Future<String> sendDummyOTP(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 2));
    
    String dummyOtp = "1234"; 
    
    print("=======================================");
    print("Mock SMS: Sent to $phoneNumber | OTP Code: $dummyOtp"); 
    print("=======================================");
    
    return dummyOtp; 
  }

  // 3. යූසර්ගේ විස්තර Database එකට Save කරන Function එක
  Future<void> saveUserProfile({
    required String name,
    String? email,
    String? gender,
    String? birthday,
  }) async {
    final user = _supabase.auth.currentUser;
    
    // Dummy login එකක් කරන නිසා දැනට මේක Bypass කරනවා (පස්සේ ඇත්තම login එකක් කරද්දී මේක ඔන් කරමු)
    // if (user == null) {
    //   throw Exception("User is not logged in!");
    // }

    try {
      // 👉 වෙනස් කරපු තැන: 'profiles' වෙනුවට 'Profiles' කියලා දැම්මා
      await _supabase.from('Profiles').upsert({
        'id': user?.id ?? 'dummy_user_id_${DateTime.now().millisecondsSinceEpoch}', // Dummy ID එකක් දානවා තාවකාලිකව
        'name': name,
        'email': email,
        'gender': gender,
        'birthday': birthday,
      });
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }
}