import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  
  // Default to Colombo, Sri Lanka
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  LatLng _currentCenter = _defaultCenter;
  
  String _address = 'Loading location...';
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _address = 'Location services are disabled.');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _address = 'Location permissions are denied.');
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _address = 'Location permissions are permanently denied.');
      }
      return;
    } 

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      _currentCenter = latLng;
      
      _mapController.move(latLng, 16);
      _reverseGeocode(latLng);
    } catch (e) {
      if (mounted) {
        setState(() => _address = 'Error fetching current location.');
      }
    }
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() {
      _isReverseGeocoding = true;
      _address = 'Locating...';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final pm = placemarks.first;
        final parts = [
          if (pm.name != null && pm.name != pm.street) pm.name,
          if (pm.street != null) pm.street,
          if (pm.subLocality != null && pm.subLocality!.isNotEmpty) pm.subLocality,
          if (pm.locality != null && pm.locality!.isNotEmpty) pm.locality,
          if (pm.subAdministrativeArea != null && pm.subAdministrativeArea!.isNotEmpty) pm.subAdministrativeArea,
          if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) pm.administrativeArea,
        ];
        
        setState(() {
          _address = parts.where((p) => p != null && p.trim().isNotEmpty).join(', ');
          _isReverseGeocoding = false;
        });
      } else if (mounted) {
        setState(() {
          _address = '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
          _isReverseGeocoding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
          _isReverseGeocoding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── Map View ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _reverseGeocode(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aleeapp',
              ),
            ],
          ),

          // ── Center Pin Marker ─────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.orange,
                    size: 44,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                       color: Colors.black.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My Location Floating Button ────────────────────────
          Positioned(
            right: 20,
            bottom: 220,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── Bottom Info Panel ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pin_drop_rounded,
                        color: AppColors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isReverseGeocoding ? 'Locating...' : 'Selected Address',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: Text(
                      _address,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isReverseGeocoding
                          ? null
                          : () {
                              Navigator.pop(context, {
                                'address': _address,
                                'latitude': _currentCenter.latitude,
                                'longitude': _currentCenter.longitude,
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
}
