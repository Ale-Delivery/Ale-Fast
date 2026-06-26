import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/google_maps_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  LatLng _currentCenter = _defaultCenter;
  
  String _address = 'Loading location...';
  bool _isReverseGeocoding = false;

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final resolvedAddress = await GoogleMapsService.reverseGeocode(
        target.latitude,
        target.longitude,
      );
      if (mounted) {
        setState(() {
          _address = resolvedAddress;
          _isReverseGeocoding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Colombo, Sri Lanka';
          _isReverseGeocoding = false;
        });
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final suggestions = await GoogleMapsService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _searchResults = suggestions;
        });
      }
    } catch (e) {
      debugPrint('Search request failed: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B35);
    const darkInk = Color(0xFF1E1E2C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: darkInk,
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
                    color: primaryColor,
                    size: 44,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
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
              foregroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── Floating Search Bar Overlay ────────────────────────
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: darkInk),
                    decoration: InputDecoration(
                      hintText: 'Search address or location...',
                      hintStyle: const TextStyle(color: Color(0xFFC0C0D0), fontWeight: FontWeight.w500),
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                
                // Search Results List Overlay
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
                          title: Text(
                            item['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkInk),
                          ),
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            final coords = await GoogleMapsService.getCoordinatesFromPlace(item);
                            if (coords != null && mounted) {
                              final lat = coords['latitude']!;
                              final lon = coords['longitude']!;
                              final latLng = LatLng(lat, lon);
                              
                              _searchController.text = item['display_name'];
                              
                              setState(() {
                                _currentCenter = latLng;
                                _address = item['display_name'];
                                _searchResults = [];
                              });
                              
                              _mapController.move(latLng, 16);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
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
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isReverseGeocoding ? 'Locating...' : 'Selected Address',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
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
                        color: darkInk,
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
                        backgroundColor: primaryColor,
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
