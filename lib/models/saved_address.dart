class SavedAddress {
  final String id;
  final String userId;
  final String label;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SavedAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedAddress.fromMap(
    Map<String, dynamic> map,
  ) {
    return SavedAddress(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      label: map['label']?.toString() ?? 'Home',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      isDefault: map['is_default'] == true,
      createdAt: _toDateTime(
        map['created_at'],
      ),
      updatedAt: _toDateTime(
        map['updated_at'],
      ),
    );
  }

  Map<String, dynamic> toMap({
    bool includeId = true,
  }) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'user_id': userId,
      'label': label,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SavedAddress copyWith({
    String? id,
    String? userId,
    String? label,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasValidCoordinates {
    final lat = latitude;
    final lng = longitude;

    if (lat == null || lng == null) {
      return false;
    }

    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
