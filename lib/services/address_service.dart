import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/saved_address.dart';
import 'local_storage_service.dart';

class AddressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _requireUserId() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }

    return user.id;
  }

  Future<List<SavedAddress>> getSavedAddresses() async {
    final userId = _requireUserId();

    try {
      final response = await _supabase
          .from('Saved_Addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('updated_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (item) => SavedAddress.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      debugPrint(
        '[AddressService.getSavedAddresses] $error',
      );

      rethrow;
    }
  }

  Future<SavedAddress?> getDefaultAddress() async {
    final userId = _requireUserId();

    try {
      final response = await _supabase
          .from('Saved_Addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return SavedAddress.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (error) {
      debugPrint(
        '[AddressService.getDefaultAddress] $error',
      );

      rethrow;
    }
  }

  Future<SavedAddress> createAddress({
    required String label,
    required String address,
    required String phone,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    return _saveAddress(
      id: null,
      label: label,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }

  Future<SavedAddress> updateAddress({
    required String id,
    required String label,
    required String address,
    required String phone,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    return _saveAddress(
      id: id,
      label: label,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }

  Future<SavedAddress> _saveAddress({
    required String? id,
    required String label,
    required String address,
    required String phone,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    _requireUserId();

    final cleanLabel = label.trim().isEmpty ? 'Home' : label.trim();

    final cleanAddress = address.trim();
    final cleanPhone = phone.trim();

    if (cleanAddress.isEmpty) {
      throw Exception('Delivery address is required.');
    }

    if (cleanPhone.isEmpty) {
      throw Exception(
        'Recipient phone number is required.',
      );
    }

    if (!_isValidCoordinate(latitude, longitude)) {
      throw Exception(
        'Invalid location coordinates. Please select the location again.',
      );
    }

    try {
      final response = await _supabase.rpc(
        'save_saved_address',
        params: {
          'p_address_id': id,
          'p_label': cleanLabel,
          'p_address': cleanAddress,
          'p_phone': cleanPhone,
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_is_default': isDefault,
        },
      );

      if (response == null) {
        throw Exception(
          'The address could not be saved.',
        );
      }

      Map<String, dynamic> data;

      if (response is List && response.isNotEmpty) {
        data = Map<String, dynamic>.from(
          response.first as Map,
        );
      } else if (response is Map) {
        data = Map<String, dynamic>.from(response);
      } else {
        throw Exception(
          'Invalid address response received.',
        );
      }

      final savedAddress = SavedAddress.fromMap(data);

      if (savedAddress.isDefault) {
        await _cacheAddress(savedAddress);
      }

      debugPrint(
        '[AddressService] Address saved: '
        '${savedAddress.id}',
      );

      return savedAddress;
    } on PostgrestException catch (error) {
      debugPrint(
        '[AddressService._saveAddress] '
        '${error.message}',
      );

      if (error.message.toLowerCase().contains('duplicate')) {
        throw Exception(
          'This location is already saved.',
        );
      }

      rethrow;
    } catch (error) {
      debugPrint(
        '[AddressService._saveAddress] $error',
      );

      rethrow;
    }
  }

  Future<void> setDefaultAddress(
    String addressId,
  ) async {
    _requireUserId();

    try {
      final response = await _supabase.rpc(
        'set_default_saved_address',
        params: {
          'p_address_id': addressId,
        },
      );

      if (response == null) {
        throw Exception(
          'The default address could not be updated.',
        );
      }

      Map<String, dynamic> data;

      if (response is List && response.isNotEmpty) {
        data = Map<String, dynamic>.from(
          response.first as Map,
        );
      } else if (response is Map) {
        data = Map<String, dynamic>.from(response);
      } else {
        throw Exception(
          'Invalid default address response.',
        );
      }

      final address = SavedAddress.fromMap(data);

      await _cacheAddress(address);
    } catch (error) {
      debugPrint(
        '[AddressService.setDefaultAddress] $error',
      );

      rethrow;
    }
  }

  Future<void> deleteAddress(
    String addressId,
  ) async {
    _requireUserId();

    try {
      await _supabase.rpc(
        'delete_saved_address',
        params: {
          'p_address_id': addressId,
        },
      );

      final defaultAddress = await getDefaultAddress();

      if (defaultAddress == null) {
        await LocalStorageService.removeDeliveryAddress();
      } else {
        await _cacheAddress(defaultAddress);
      }

      debugPrint(
        '[AddressService] Address deleted: '
        '$addressId',
      );
    } catch (error) {
      debugPrint(
        '[AddressService.deleteAddress] $error',
      );

      rethrow;
    }
  }

  Future<SavedAddress?> findDuplicateAddress({
    required double latitude,
    required double longitude,
    String? excludeId,
  }) async {
    final userId = _requireUserId();

    try {
      var query = _supabase
          .from('Saved_Addresses')
          .select()
          .eq('user_id', userId)
          .gte('latitude', latitude - 0.001)
          .lte('latitude', latitude + 0.001)
          .gte('longitude', longitude - 0.001)
          .lte('longitude', longitude + 0.001);

      if (excludeId != null && excludeId.isNotEmpty) {
        query = query.neq('id', excludeId);
      }

      final response = await query.limit(1);

      if (response.isEmpty) {
        return null;
      }

      return SavedAddress.fromMap(
        Map<String, dynamic>.from(
          response.first,
        ),
      );
    } catch (error) {
      debugPrint(
        '[AddressService.findDuplicateAddress] '
        '$error',
      );

      rethrow;
    }
  }

  Future<bool> isAddressServiceable({
    required double latitude,
    required double longitude,
  }) async {
    if (!_isValidCoordinate(
      latitude,
      longitude,
    )) {
      return false;
    }

    // Temporary Sri Lanka boundary validation.
    // Replace later with merchant delivery-zone or
    // radius/polygon validation.
    final isInsideSriLanka = latitude >= 5.5 &&
        latitude <= 10.0 &&
        longitude >= 79.5 &&
        longitude <= 82.5;

    return isInsideSriLanka;
  }

  bool _isValidCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  Future<void> _cacheAddress(
    SavedAddress address,
  ) async {
    await LocalStorageService.saveDeliveryAddress(
      label: address.label,
      address: address.address,
      phone: address.phone,
    );
  }
}
