import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/google_maps_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class RideMapScreen extends StatefulWidget {
  const RideMapScreen({super.key});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  LatLng _currentLocation = _defaultCenter;

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String? _pickupName;
  String? _dropoffName;

  bool _selectingPickup = true; // true = pickup, false = dropoff

  // Search
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
        _pickupLatLng = latLng;
      });

      final address = await GoogleMapsService.reverseGeocode(
        latLng.latitude,
        latLng.longitude,
      );
      setState(() {
        _pickupName = address;
        _searchController.text = address;
      });

      _mapController.move(latLng, 15);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final results = await GoogleMapsService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectResult(Map<String, dynamic> item) async {
    final coords = await GoogleMapsService.getCoordinatesFromPlace(item);
    if (coords == null) return;
    final latLng = LatLng(coords['latitude']!, coords['longitude']!);

    setState(() {
      if (_selectingPickup) {
        _pickupLatLng = latLng;
        _pickupName = item['display_name'];
      } else {
        _dropoffLatLng = latLng;
        _dropoffName = item['display_name'];
      }
      _searchController.text = item['display_name'];
      _searchResults = [];
    });

    _fitMap();
  }

  void _confirmLocation() {
    final latLng = _selectingPickup ? _pickupLatLng : _dropoffLatLng;
    final name = _selectingPickup ? _pickupName : _dropoffName;

    if (latLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap on map or search to set location'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectingPickup) {
      setState(() {
        _selectingPickup = false;
        _searchController.clear();
        _searchResults = [];
        _searchController.text = _dropoffName ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup set: ${_shorten(name)}'),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Both selected — return result
      Navigator.pop(context, {
        'pickup_lat': _pickupLatLng!.latitude,
        'pickup_lng': _pickupLatLng!.longitude,
        'pickup_name': _pickupName,
        'dropoff_lat': _dropoffLatLng!.latitude,
        'dropoff_lng': _dropoffLatLng!.longitude,
        'dropoff_name': _dropoffName,
      });
    }
  }

  void _fitMap() {
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      final center = LatLng(
        (_pickupLatLng!.latitude + _dropoffLatLng!.latitude) / 2,
        (_pickupLatLng!.longitude + _dropoffLatLng!.longitude) / 2,
      );
      final dist = Distance().as(LengthUnit.Meter, _pickupLatLng!, _dropoffLatLng!);
      final zoom = dist > 20000 ? 10.0 : dist > 5000 ? 12.0 : dist > 1000 ? 14.0 : 15.0;
      _mapController.move(center, zoom);
    } else if (_pickupLatLng != null) {
      _mapController.move(_pickupLatLng!, 15);
    } else if (_dropoffLatLng != null) {
      _mapController.move(_dropoffLatLng!, 15);
    }
  }

  String _shorten(String? s) {
    if (s == null) return '';
    return s.length > 40 ? '${s.substring(0, 40)}...' : s;
  }

  void _onMapTap(TapPosition tapPos, LatLng latLng) async {
    final address = await GoogleMapsService.reverseGeocode(
      latLng.latitude,
      latLng.longitude,
    );

    setState(() {
      if (_selectingPickup) {
        _pickupLatLng = latLng;
        _pickupName = address;
        _searchController.text = address;
      } else {
        _dropoffLatLng = latLng;
        _dropoffName = address;
        _searchController.text = address;
      }
      _searchResults = [];
    });

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = _selectingPickup;
    final activeColor = isPickup ? Colors.green : Colors.red;
    final label = isPickup ? 'Set Pickup' : 'Set Drop-off';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.alefast.client',
              ),
              // Route line
              if (_pickupLatLng != null && _dropoffLatLng != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _buildRoutePoints(_pickupLatLng!, _dropoffLatLng!),
                      color: AppColors.accent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  if (_pickupLatLng != null)
                    Marker(
                      point: _pickupLatLng!,
                      width: 44, height: 44,
                      child: _buildMarker(Colors.green, Icons.circle),
                    ),
                  if (_dropoffLatLng != null)
                    Marker(
                      point: _dropoffLatLng!,
                      width: 44, height: 44,
                      child: _buildMarker(Colors.red, Icons.flag),
                    ),
                ],
              ),
            ],
          ),

          // Top bar — search + back
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.arrowLeft, size: 18, color: context.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: isPickup ? 'Search pickup location...' : 'Search drop-off location...',
                              hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                              prefixIcon: Icon(isPickup ? Icons.circle : Icons.flag, color: activeColor, size: 14),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () { _searchController.clear(); _onSearch(''); },
                                      child: Icon(Icons.close, size: 18, color: context.textMuted),
                                    )
                                  : _isSearching
                                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                                      : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Search results dropdown
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: context.cardShadow,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, i) {
                          final item = _searchResults[i];
                          return InkWell(
                            onTap: () => _selectResult(item),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.mapPin, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['display_name'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: context.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Center crosshair indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPickup ? Icons.circle : Icons.flag,
                    color: activeColor,
                    size: 36,
                  ),
                  Container(
                    width: 4, height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ),

          // Step indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 68,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPickup ? 'Step 1: Pickup' : 'Step 2: Drop-off',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Bottom confirm button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location summary
                  if (_pickupLatLng != null || _dropoffLatLng != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              Container(width: 2, height: 20, color: context.textHint),
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickupName ?? 'Tap map to set pickup',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: _pickupLatLng != null ? context.textPrimary : context.textHint),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _dropoffName ?? 'Tap map to set drop-off',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: _dropoffLatLng != null ? context.textPrimary : context.textHint),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Confirm button
                  GestureDetector(
                    onTap: _confirmLocation,
                    child: Container(
                      width: double.infinity, height: 52,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppGradients.glow,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }

  List<LatLng> _buildRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 30;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final offset = math.sin(t * math.pi) * 0.002;
      final dx = end.longitude - start.longitude;
      final dy = end.latitude - start.latitude;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) { points.add(LatLng(lat, lng)); continue; }
      final perpX = -dy / len;
      final perpY = dx / len;
      points.add(LatLng(lat + perpX * offset, lng + perpY * offset));
    }
    return points;
  }
}
