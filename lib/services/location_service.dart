import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String district;
  final String postalCode;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.district,
    required this.postalCode,
  });
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Please enable location services.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it from settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final placemark = placemarks.isNotEmpty ? placemarks.first : null;

    final addressParts = [
      placemark?.street,
      placemark?.subLocality,
      placemark?.locality,
      placemark?.administrativeArea,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: addressParts.join(', '),
      city: placemark?.locality ?? '',
      district: placemark?.administrativeArea ?? '',
      postalCode: placemark?.postalCode ?? '',
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
