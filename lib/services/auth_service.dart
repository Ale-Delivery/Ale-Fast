import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static String _generateUserId() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }

    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10, 16).map(hex).join()}';
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOtp(String phoneNumber) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp',
        body: {
          'phone': phoneNumber,
        },
      );

      if (response.status != 200) {
        final data = response.data;

        if (data is Map && data['error'] != null) {
          throw Exception(
            data['error'].toString(),
          );
        }

        throw Exception(
          'Failed to send OTP',
        );
      }

      debugPrint(
        'OTP sent successfully to $phoneNumber',
      );
    } catch (error) {
      debugPrint(
        'OTP send error: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'auth-otp-verify',
        body: {
          'phone': phone,
          'token': otp,
        },
      );

      if (response.data is! Map) {
        throw Exception(
          'Invalid response received from server',
        );
      }

      final data = Map<String, dynamic>.from(
        response.data as Map,
      );

      if (response.status != 200) {
        if (data['error'] != null) {
          throw Exception(
            data['error'].toString(),
          );
        }

        throw Exception(
          'OTP verification failed',
        );
      }

      final sessionData = data['session'];

      if (sessionData is! Map) {
        throw Exception(
          'Session data was not returned',
        );
      }

      final refreshToken = sessionData['refresh_token']?.toString();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception(
          'Refresh token was not returned',
        );
      }

      await _supabase.auth.setSession(
        refreshToken,
      );

      debugPrint(
        'OTP verified. User ID: '
        '${_supabase.auth.currentUser?.id}',
      );

      return data;
    } catch (error) {
      debugPrint(
        'OTP verification error: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // SAVE OR UPDATE USER PROFILE
  // ============================================================

  Future<String> saveUserProfile({
    required String name,
    String? email,
    String? gender,
    String? birthday,
    String? phone,
    String? existingUserId,
  }) async {
    final currentUser = _supabase.auth.currentUser;

    final userId = existingUserId ?? currentUser?.id ?? _generateUserId();

    final payload = <String, dynamic>{
      'id': userId,
      'name': name.trim(),
    };

    final trimmedEmail = email?.trim();
    final trimmedPhone = phone?.trim();

    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      payload['email'] = trimmedEmail;
    }

    if (gender != null && gender.trim().isNotEmpty) {
      payload['gender'] = gender.trim();
    }

    if (birthday != null && birthday.trim().isNotEmpty) {
      payload['birthday'] = birthday.trim();
    }

    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      payload['phone'] = trimmedPhone;
    }

    try {
      await _supabase.from('Profiles').upsert(
            payload,
            onConflict: 'id',
          );

      debugPrint(
        'Profile saved successfully. '
        'User ID: $userId',
      );

      return userId;
    } catch (error) {
      debugPrint(
        'Profile Supabase sync error: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // CHECK USER EXISTS
  // ============================================================

  Future<bool> checkUserExists(
    String phone,
  ) async {
    try {
      final normalizedPhone = phone.trim();

      final response = await _supabase
          .from('Profiles')
          .select('id')
          .eq(
            'phone',
            normalizedPhone,
          )
          .limit(1);

      return response.isNotEmpty;
    } catch (error) {
      debugPrint(
        'Error checking user exists: $error',
      );

      return false;
    }
  }

  // ============================================================
  // GET USER PROFILE BY PHONE
  // ============================================================

  Future<Map<String, dynamic>?> getUserProfile(
    String phone,
  ) async {
    try {
      final normalizedPhone = phone.trim();

      final response = await _supabase
          .from('Profiles')
          .select()
          .eq(
            'phone',
            normalizedPhone,
          )
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(
        response.first,
      );
    } catch (error) {
      debugPrint(
        'Error fetching user profile: $error',
      );

      return null;
    }
  }

  // ============================================================
  // GET CURRENT USER PROFILE BY AUTH USER ID
  // ============================================================

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      final response = await _supabase
          .from('Profiles')
          .select()
          .eq(
            'id',
            currentUser.id,
          )
          .limit(1);

      if (response.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(
        response.first,
      );
    } catch (error) {
      debugPrint(
        'Error fetching current user profile: $error',
      );

      return null;
    }
  }
}
