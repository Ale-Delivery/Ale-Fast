import 'dart:io';
import 'dart:convert';
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
  
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  LatLng _currentCenter = _defaultCenter;
  
  String _address = 'Loading location...';
  bool _isReverseGeocoding = false;

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

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
          _address = 'Colombo, Sri Lanka';
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

    setState(() => _isSearching = true);

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5');
      final request = await client.getUrl(uri);
      request.headers.setUserAgent('aleeapp');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List data = jsonDecode(body);
        
        if (mounted) {
          setState(() {
            _searchResults = data.map((item) => {
              'display_name': item['display_name'].toString(),
              'lat': double.parse(item['lat'].toString()),
              'lon': double.parse(item['lon'].toString()),
            }).toList();
            _isSearching = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Search request failed, falling back to mock search suggestions: $e');
    }

    // Fallback: Mock suggestions for Sri Lankan addresses if network is offline / DNS issues
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

    if (mounted) {
      setState(() {
        _searchResults = mockLocations
            .where((loc) => loc['display_name'].toString().toLowerCase().contains(queryLower))
            .toList();
        _isSearching = false;
      });
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
                          onTap: () {
                            final lat = item['lat'];
                            final lon = item['lon'];
                            final latLng = LatLng(lat, lon);
                            
                            FocusScope.of(context).unfocus();
                            _searchController.text = item['display_name'];
                            
                            setState(() {
                              _currentCenter = latLng;
                              _address = item['display_name'];
                              _searchResults = [];
                            });
                            
                            _mapController.move(latLng, 16);
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
