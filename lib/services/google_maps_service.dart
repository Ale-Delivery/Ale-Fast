import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

class GoogleMapsService {
  /// Fetches address suggestions based on a query.
  /// Falls back to OpenStreetMap Nominatim if Google Maps API key is not provided.
  static Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(String query) async {
    if (query.trim().length < 3) return [];

    final apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$apiKey'
          '&components=country:lk' // Limit suggestions to Sri Lanka (change country code if needed)
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
        debugPrint('Google Places Autocomplete error, falling back to OSM: $e');
      }
    }

    // OpenStreetMap Nominatim Fallback
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&countrycodes=lk' // Sri Lanka country limit
        '&limit=5'
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'aleeapp');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List data = jsonDecode(body);
        return data.map<Map<String, dynamic>>((item) {
          return {
            'display_name': item['display_name'].toString(),
            'lat': double.parse(item['lat'].toString()),
            'lon': double.parse(item['lon'].toString()),
            'is_google': false,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('OSM search request failed: $e');
    }

    // Offline / Fallback Mock suggestions
    final queryLower = query.toLowerCase();
    final mockLocations = [
      {'display_name': 'Colombo 03, Western Province, Sri Lanka', 'lat': 6.9128, 'lon': 79.8507},
      {'display_name': 'Colombo 07, Western Province, Sri Lanka', 'lat': 6.9056, 'lon': 79.8665},
      {'display_name': 'University of Moratuwa, Bandaranayake Mawatha, Moratuwa, Sri Lanka', 'lat': 6.7969, 'lon': 79.9018},
      {'display_name': 'Galle Road, Bambalapitiya, Colombo, Sri Lanka', 'lat': 6.8962, 'lon': 79.8553},
      {'display_name': 'Kandy Road, Kiribathgoda, Western Province, Sri Lanka', 'lat': 6.9749, 'lon': 79.9286},
      {'display_name': 'Majestic City, Galle Road, Colombo, Sri Lanka', 'lat': 6.8940, 'lon': 79.8547},
      {'display_name': 'One Galle Face Mall, Colombo, Sri Lanka', 'lat': 6.9275, 'lon': 79.8436},
      {'display_name': 'Nugegoda, Western Province, Sri Lanka', 'lat': 6.8741, 'lon': 79.8872},
      {'display_name': 'Kotte, Western Province, Sri Lanka', 'lat': 6.9010, 'lon': 79.9010},
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
      final apiKey = AppConstants.googleMapsApiKey;
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
    final apiKey = AppConstants.googleMapsApiKey;
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
      request.headers.set(HttpHeaders.userAgentHeader, 'aleeapp');
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
