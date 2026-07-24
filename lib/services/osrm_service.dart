import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteResult {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> routePoints;
  final String? error;

  const OsrmRouteResult({
    required this.distanceKm,
    required this.durationMin,
    required this.routePoints,
    this.error,
  });

  bool get isSuccess => error == null;
}

class OsrmService {
  static const String _baseUrl = 'https://routing.openstreetmaps.de/routed-car/route/v1/driving';
  static const String _fallbackUrl = 'https://router.project-osrm.org/route/v1/driving';

  static Future<OsrmRouteResult> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
          '?geometries=geojson&overview=full&steps=false';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return _fallbackRoute(origin, destination);
      }

      return _parseResponse(response.body);
    } catch (_) {
      return _fallbackRoute(origin, destination);
    }
  }

  static Future<OsrmRouteResult> _fallbackRoute(LatLng origin, LatLng destination) async {
    final url = '$_fallbackUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?geometries=geojson&overview=full&steps=false';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      final meters = Distance().as(LengthUnit.Meter, origin, destination);
      return OsrmRouteResult(
        distanceKm: meters / 1000,
        durationMin: (meters / 1000 * 2).ceil().toDouble(),
        routePoints: [origin, destination],
        error: 'OSRM failed, using straight-line estimate',
      );
    }

    return _parseResponse(response.body);
  }

  static OsrmRouteResult _parseResponse(String body) {
    final decoded = json.decode(body);
    final routes = decoded['routes'] as List?;

    if (routes == null || routes.isEmpty) {
      return OsrmRouteResult(
        distanceKm: 0,
        durationMin: 0,
        routePoints: [],
        error: 'No route found',
      );
    }

    final route = routes.first as Map<String, dynamic>;
    final distanceMeters = (route['distance'] as num).toDouble();
    final durationSeconds = (route['duration'] as num).toDouble();
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    final points = coordinates.map((coord) {
      final lnglat = coord as List;
      return LatLng(lnglat[1].toDouble(), lnglat[0].toDouble());
    }).toList();

    return OsrmRouteResult(
      distanceKm: distanceMeters / 1000,
      durationMin: durationSeconds / 60,
      routePoints: points,
    );
  }

  static Future<Map<String, dynamic>?> getDistanceAndEta(LatLng origin, LatLng destination) async {
    final result = await getRoute(origin, destination);
    if (!result.isSuccess) return null;
    return {
      'distance_km': result.distanceKm,
      'eta_min': result.durationMin.round(),
      'route_points': result.routePoints,
    };
  }
}
