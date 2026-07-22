import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

class GoogleMapsService {
  /// Fetches address suggestions based on a query.
  /// Uses Photon (free, no API key) with Nominatim fallback.
  static Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    if (query.trim().length < 3) return [];

    const apiKey = AppConstants.googleMapsApiKey;

    // Google Places (if key provided)
    if (apiKey.isNotEmpty) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$apiKey'
          '&components=country:lk'
        );
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          if (data['status'] == 'OK' && data['predictions'] != null) {
            final List predictions = data['predictions'];
            return predictions.map<Map<String, dynamic>>((item) {
              return {
                'display_name': item['description'].toString(),
                'place_id': item['place_id'].toString(),
                'is_google': true,
              };
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Google Places Autocomplete error, falling back: $e');
      }
    }

    // Photon (Komoot) — free, fast, no API key needed
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?'
        'q=${Uri.encodeComponent(query)}'
        '&lang=en'
        '&limit=10'
        '&lat=6.9271&lon=79.8612'
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'alefast');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          return features.map<Map<String, dynamic>>((feature) {
            final props = feature['properties'] as Map<String, dynamic>? ?? {};
            final coords = feature['geometry']?['coordinates'] as List?;
            final name = props['name']?.toString() ?? '';
            final city = props['city']?.toString() ?? '';
            final state = props['state']?.toString() ?? '';
            final country = props['country']?.toString() ?? 'Sri Lanka';
            final district = props['district']?.toString() ?? '';
            final neighbourhood = props['neighbourhood']?.toString() ?? '';

            final parts = [name, neighbourhood, district, city, state, country]
                .where((p) => p.isNotEmpty && p != 'null')
                .toList();
            final displayName = parts.join(', ');

            return {
              'display_name': displayName,
              'lat': coords != null ? coords[1] : 0.0,
              'lon': coords != null ? coords[0] : 0.0,
              'is_google': false,
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Photon search failed, trying Nominatim: $e');
    }

    // Nominatim fallback
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&countrycodes=lk'
        '&limit=8'
        '&addressdetails=1'
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'alefast');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List data = jsonDecode(body);
        if (data.isNotEmpty) {
          return data.map<Map<String, dynamic>>((item) {
            return {
              'display_name': item['display_name'].toString(),
              'lat': double.parse(item['lat'].toString()),
              'lon': double.parse(item['lon'].toString()),
              'is_google': false,
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Nominatim search failed: $e');
    }

    // Offline fallback — Sri Lanka locations
    final queryLower = query.toLowerCase();
    final mockLocations = [
      {'display_name': 'Colombo Fort, Colombo, Western Province, Sri Lanka', 'lat': 6.9344, 'lon': 79.8428},
      {'display_name': 'Galle Face, Colombo 01, Western Province, Sri Lanka', 'lat': 6.9218, 'lon': 79.8382},
      {'display_name': 'Kandy City Centre, Kandy, Central Province, Sri Lanka', 'lat': 7.2906, 'lon': 80.6337},
      {'display_name': 'Galle Fort, Galle, Southern Province, Sri Lanka', 'lat': 6.0265, 'lon': 80.2170},
      {'display_name': 'Negombo Beach, Negombo, Western Province, Sri Lanka', 'lat': 7.2133, 'lon': 79.8363},
      {'display_name': 'Nugegoda, Western Province, Sri Lanka', 'lat': 6.8741, 'lon': 79.8872},
      {'display_name': 'Dehiwala-Mount Lavinia, Western Province, Sri Lanka', 'lat': 6.8402, 'lon': 79.8654},
      {'display_name': 'Rajagiriya, Western Province, Sri Lanka', 'lat': 6.9076, 'lon': 79.8936},
      {'display_name': 'Battaramulla, Western Province, Sri Lanka', 'lat': 6.8992, 'lon': 79.9176},
      {'display_name': 'Katunayake, Western Province, Sri Lanka', 'lat': 7.1706, 'lon': 79.8297},
      {'display_name': 'Moratuwa, Western Province, Sri Lanka', 'lat': 6.7817, 'lon': 79.8833},
      {'display_name': 'Panadura, Western Province, Sri Lanka', 'lat': 6.7130, 'lon': 79.9053},
      {'display_name': 'Kelaniya, Western Province, Sri Lanka', 'lat': 6.9561, 'lon': 79.9260},
      {'display_name': 'Kiribathgoda, Western Province, Sri Lanka', 'lat': 6.9749, 'lon': 79.9286},
      {'display_name': 'Maharagama, Western Province, Sri Lanka', 'lat': 6.8507, 'lon': 79.9276},
      {'display_name': 'Homagama, Western Province, Sri Lanka', 'lat': 6.8417, 'lon': 80.0017},
      {'display_name': 'Kottawa, Western Province, Sri Lanka', 'lat': 6.8388, 'lon': 79.9676},
      {'display_name': 'Piliyandala, Western Province, Sri Lanka', 'lat': 6.8038, 'lon': 79.9090},
      {'display_name': 'Wattala, Western Province, Sri Lanka', 'lat': 6.9911, 'lon': 79.8887},
      {'display_name': 'Ja-Ela, Western Province, Sri Lanka', 'lat': 7.0790, 'lon': 79.8943},
      {'display_name': 'Malabe, Western Province, Sri Lanka', 'lat': 6.9090, 'lon': 79.9300},
      {'display_name': 'Thimbirigasyaya, Colombo 05, Sri Lanka', 'lat': 6.9034, 'lon': 79.8776},
      {'display_name': 'Wellawatte, Colombo 04, Sri Lanka', 'lat': 6.8806, 'lon': 79.8606},
      {'display_name': 'Bambalapitiya, Colombo 04, Sri Lanka', 'lat': 6.8962, 'lon': 79.8553},
      {'display_name': 'Kollupitiya, Colombo 03, Sri Lanka', 'lat': 6.9128, 'lon': 79.8507},
      {'display_name': 'Cinnamon Gardens, Colombo 07, Sri Lanka', 'lat': 6.9056, 'lon': 79.8665},
      {'display_name': 'Pettah, Colombo 11, Sri Lanka', 'lat': 6.9375, 'lon': 79.8494},
      {'display_name': 'Kompannavidiya, Colombo 02, Sri Lanka', 'lat': 6.9238, 'lon': 79.8497},
      {'display_name': 'Slave Island, Colombo 02, Sri Lanka', 'lat': 6.9206, 'lon': 79.8532},
      {'display_name': 'Union Place, Colombo 02, Sri Lanka', 'lat': 6.9186, 'lon': 79.8566},
    ];

    return mockLocations
        .where((loc) => loc['display_name'].toString().toLowerCase().contains(queryLower))
        .map<Map<String, dynamic>>((loc) => {
              'display_name': loc['display_name'].toString(),
              'lat': loc['lat'],
              'lon': loc['lon'],
              'is_google': false,
            })
        .toList();
  }

  /// Converts a placeId (from Google Autocomplete) or address to coordinates
  static Future<Map<String, double>?> getCoordinatesFromPlace(Map<String, dynamic> item) async {
    if (item['is_google'] == true && item['place_id'] != null) {
      const apiKey = AppConstants.googleMapsApiKey;
      if (apiKey.isNotEmpty) {
        try {
          final client = HttpClient();
          final uri = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=${item['place_id']}'
            '&fields=geometry'
            '&key=$apiKey'
          );
          final request = await client.getUrl(uri);
          final response = await request.close();

          if (response.statusCode == 200) {
            final body = await response.transform(utf8.decoder).join();
            final data = jsonDecode(body);
            if (data['status'] == 'OK' && data['result']?['geometry']?['location'] != null) {
              final loc = data['result']['geometry']['location'];
              return {
                'latitude': double.parse(loc['lat'].toString()),
                'longitude': double.parse(loc['lng'].toString()),
              };
            }
          }
        } catch (e) {
          debugPrint('Google Place Details error: $e');
        }
      }
    } else {
      if (item['lat'] != null && item['lon'] != null) {
        return {
          'latitude': item['lat'],
          'longitude': item['lon'],
        };
      }
    }
    return null;
  }

  /// Reverse geocodes coordinates to a human-readable address.
  static Future<String> reverseGeocode(double lat, double lng) async {
    const apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&key=$apiKey'
        );
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          if (data['status'] == 'OK' && data['results'] != null && (data['results'] as List).isNotEmpty) {
            return data['results'][0]['formatted_address'].toString();
          }
        }
      } catch (e) {
        debugPrint('Google Reverse Geocode error, falling back: $e');
      }
    }

    // Nominatim fallback first (online reverse geocoding)
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=$lat'
        '&lon=$lng'
        '&zoom=18'
        '&addressdetails=1'
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'alefast');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data['display_name'] != null) {
          return data['display_name'].toString();
        }
      }
    } catch (e) {
      debugPrint('OSM reverse geocoding error: $e');
    }

    // Geocoding Package fallback
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final parts = [
          if (pm.name != null && pm.name != pm.street) pm.name,
          if (pm.street != null) pm.street,
          if (pm.subLocality != null && pm.subLocality!.isNotEmpty) pm.subLocality,
          if (pm.locality != null && pm.locality!.isNotEmpty) pm.locality,
          if (pm.subAdministrativeArea != null && pm.subAdministrativeArea!.isNotEmpty) pm.subAdministrativeArea,
          if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) pm.administrativeArea,
        ];
        
        final resolved = parts.where((p) => p != null && p.trim().isNotEmpty).join(', ');
        // If it resolved coordinates as the street/name, do not use it
        final isCoordinatesPattern = RegExp(r'^\d+\.\d+\s*,\s*\d+\.\d+$').hasMatch(resolved);
        if (resolved.isNotEmpty && !isCoordinatesPattern) {
          return resolved;
        }
      }
    } catch (e) {
      debugPrint('Geocoding package fallback error: $e');
    }

    // Ultimate fallback: formatted coordinates
    return '$lat, $lng';
  }
}
