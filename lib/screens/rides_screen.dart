import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/google_maps_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class RidesScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  const RidesScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);
  LatLng _currentLocation = _defaultCenter;

  // Pickup & dropoff
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;

  // Search
  List<Map<String, dynamic>> _pickupResults = [];
  List<Map<String, dynamic>> _dropoffResults = [];
  bool _isSearchingPickup = false;
  bool _isSearchingDropoff = false;
  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;
  List<Map<String, String>> _recentSearches = [];

  // Ride
  int _selectedRideIndex = 1;
  bool _booking = false;
  double _distanceKm = 0;
  int _etaMinutes = 0;

  // Payment
  String _paymentMethod = 'cash';

  // Driver matching
  bool _isMatching = false;
  Map<String, dynamic>? _matchedDriver;

  // Saved places
  Map<String, dynamic>? _homePlace;
  Map<String, dynamic>? _workPlace;

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _rideTypes = const [
    {'name': 'Bike', 'icon': LucideIcons.bike, 'baseFare': 60, 'perKm': 25, 'perMin': 5, 'capacity': '1 person', 'color': Color(0xFF3B82F6), 'speed': 35},
    {'name': 'Tuk', 'icon': LucideIcons.car, 'baseFare': 100, 'perKm': 50, 'perMin': 8, 'capacity': '3 persons', 'color': Color(0xFFF59E0B), 'speed': 30},
    {'name': 'Car', 'icon': LucideIcons.car, 'baseFare': 150, 'perKm': 80, 'perMin': 12, 'capacity': '4 persons', 'color': Color(0xFF8B5CF6), 'speed': 25},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _getCurrentLocation();
    _loadSavedPlaces();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlaces() async {
    try {
      final userId = await LocalStorageService.getUserId();
      if (userId == null || userId.isEmpty) return;
      final response = await Supabase.instance.client
          .from('Saved_Places')
          .select()
          .eq('user_id', userId);
      if (mounted) {
        for (final place in response) {
          if (place['label'] == 'Home') {
            _homePlace = place;
          } else if (place['label'] == 'Work') {
            _workPlace = place;
          }
        }
      }
    } catch (e) {
      debugPrint('Load saved places error: $e');
    }
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
      if (mounted) {
        setState(() => _pickupController.text = address);
      }

      // Wait for map to be ready
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _mapController.move(latLng, 15);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // ── Search with debounce ──────────────────────────────────
  void _onPickupSearch(String query) async {
    _pickupDebounce?.cancel();
    if (query.length < 3) {
      setState(() => _pickupResults = []);
      return;
    }
    _pickupDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearchingPickup = true);
      final results = await GoogleMapsService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _pickupResults = results;
          _isSearchingPickup = false;
        });
      }
    });
  }

  void _onDropoffSearch(String query) async {
    _dropoffDebounce?.cancel();
    if (query.length < 3) {
      setState(() => _dropoffResults = []);
      return;
    }
    _dropoffDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearchingDropoff = true);
      final results = await GoogleMapsService.getAutocompleteSuggestions(query);
      if (mounted) {
        setState(() {
          _dropoffResults = results;
          _isSearchingDropoff = false;
        });
      }
    });
  }

  void _selectPickup(Map<String, dynamic> item) async {
    final coords = await GoogleMapsService.getCoordinatesFromPlace(item);
    if (coords == null) return;
    final latLng = LatLng(coords['latitude']!, coords['longitude']!);
    setState(() {
      _pickupLatLng = latLng;
      _pickupController.text = item['display_name'];
      _pickupResults = [];
    });
    _saveRecent(item['display_name'], 'pickup');
    _fitMap();
    _calculateRoute();
  }

  void _selectDropoff(Map<String, dynamic> item) async {
    final coords = await GoogleMapsService.getCoordinatesFromPlace(item);
    if (coords == null) return;
    final latLng = LatLng(coords['latitude']!, coords['longitude']!);
    setState(() {
      _dropoffLatLng = latLng;
      _dropoffController.text = item['display_name'];
      _dropoffResults = [];
    });
    _saveRecent(item['display_name'], 'dropoff');
    _fitMap();
    _calculateRoute();
  }

  void _saveRecent(String? name, String type) {
    if (name == null || name.isEmpty) return;
    _recentSearches.removeWhere((r) => r['name'] == name);
    _recentSearches.insert(0, {'name': name, 'type': type});
    if (_recentSearches.length > 5) _recentSearches = _recentSearches.sublist(0, 5);
  }

  void _useCurrentLocation() async {
    setState(() {
      _pickupLatLng = _currentLocation;
      _pickupController.text = 'Current location';
      _pickupResults = [];
    });
    _fitMap();
    _calculateRoute();
  }

  void _swapLocations() {
    final tmpLat = _pickupLatLng;
    final tmpText = _pickupController.text;
    setState(() {
      _pickupLatLng = _dropoffLatLng;
      _pickupController.text = _dropoffController.text;
      _dropoffLatLng = tmpLat;
      _dropoffController.text = tmpText;
    });
    _fitMap();
    _calculateRoute();
    HapticFeedback.lightImpact();
  }

  // ── Map helpers ────────────────────────────────────────────
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
    }
  }

  void _calculateRoute() {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;

    final meters = Distance().as(LengthUnit.Meter, _pickupLatLng!, _dropoffLatLng!);
    final km = meters / 1000;

    setState(() {
      _distanceKm = km;
      _etaMinutes = (km * 2).ceil().clamp(3, 60);
    });
  }

  int _getFare(int index) {
    final ride = _rideTypes[index];
    final fare = (ride['baseFare'] + (ride['perKm'] * _distanceKm) + (ride['perMin'] * _etaMinutes)).round();
    return fare;
  }

  String _getEtaForRide(int index) {
    if (_distanceKm == 0) return '...';
    final speed = _rideTypes[index]['speed'] as int;
    final min = (_distanceKm / speed * 60).ceil().clamp(2, 90);
    return '$min min';
  }

  int _getCheapestIndex() {
    if (_distanceKm == 0) return 0;
    int cheapest = 0;
    int lowest = _getFare(0);
    for (int i = 1; i < _rideTypes.length; i++) {
      final fare = _getFare(i);
      if (fare < lowest) {
        lowest = fare;
        cheapest = i;
      }
    }
    return cheapest;
  }

  int _getFastestIndex() {
    if (_distanceKm == 0) return 0;
    int fastest = 0;
    int lowestMin = 999;
    for (int i = 0; i < _rideTypes.length; i++) {
      final speed = _rideTypes[i]['speed'] as int;
      final min = (_distanceKm / speed * 60).ceil();
      if (min < lowestMin) {
        lowestMin = min;
        fastest = i;
      }
    }
    return fastest;
  }

  // ── Book ride ──────────────────────────────────────────────
  Future<void> _bookRide() async {
    if (_pickupLatLng == null || _dropoffLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set pickup and dropoff locations'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isMatching = true;
      _booking = true;
    });

    // Simulate driver matching
    await Future.delayed(const Duration(seconds: 3));

    final names = ['Kasun P.', 'Nimal W.', 'Sunil R.', 'Dinesh M.', 'Lakmal S.'];
    final ratings = [4.8, 4.9, 4.7, 4.6, 5.0];
    final vehicles = ['ABC-1234', 'DEF-5678', 'GHI-9012', 'JKL-3456', 'MNO-7890'];
    final idx = math.Random().nextInt(names.length);

    if (mounted) {
      setState(() {
        _isMatching = false;
        _matchedDriver = {
          'name': names[idx],
          'rating': ratings[idx],
          'vehicle': vehicles[idx],
          'ride': _rideTypes[_selectedRideIndex]['name'],
        };
        _booking = false;
      });
    }

    HapticFeedback.heavyImpact();
    _showBookingConfirmed();
  }

  void _showBookingConfirmed() {
    final ride = _rideTypes[_selectedRideIndex];
    final fare = _getFare(_selectedRideIndex);
    final driver = _matchedDriver;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: context.textHint, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.green, size: 40),
          ),
          const SizedBox(height: 16),
          Text('${ride['name']} booked!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Fare: Rs. $fare · ETA: $_etaMinutes min', style: TextStyle(color: context.textMuted, fontSize: 15)),
          const SizedBox(height: 24),
          // Driver info
          if (driver != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.avatar,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        driver['name'][0],
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver['name'], style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text('${driver['rating']}', style: TextStyle(fontSize: 13, color: context.textMuted)),
                            const SizedBox(width: 8),
                            Text(driver['vehicle'], style: TextStyle(fontSize: 13, color: context.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.call, color: AppColors.accent, size: 20),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() { _matchedDriver = null; });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildMapSection(),
              _buildBottomSheet(),
            ],
          ),
          // Matching overlay
          if (_isMatching)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60, height: 60,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Finding your driver...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Matching you with the best ${_rideTypes[_selectedRideIndex]['name']} driver', textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      width: double.infinity,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.alefast.app',
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
                    // Dashed effect overlay
                    Polyline(
                      points: _buildDashedPoints(_pickupLatLng!, _dropoffLatLng!),
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  if (_pickupLatLng != null)
                    Marker(
                      point: _pickupLatLng!,
                      width: 50, height: 50,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: _buildPulseMarker(Colors.green, LucideIcons.circle, 'Pickup'),
                      ),
                    ),
                  if (_dropoffLatLng != null)
                    Marker(
                      point: _dropoffLatLng!,
                      width: 44, height: 44,
                      child: _buildMarker(Colors.red, LucideIcons.flag, 'Drop'),
                    ),
                ],
              ),
            ],
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _circleButton(LucideIcons.arrowLeft, () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            }),
          ),
          // Locate button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _circleButton(LucideIcons.crosshair, () {
              _mapController.move(_currentLocation, 15);
            }),
          ),
          // Distance/ETA badge
          if (_distanceKm > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: MediaQuery.of(context).size.width / 2 - 55,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                  boxShadow: context.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.route, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      '${_distanceKm.toStringAsFixed(1)} km · $_etaMinutes min',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPulseMarker(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        Container(
          width: 4, height: 4,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildMarker(Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          width: 4, height: 4,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: context.cardShadow,
        ),
        child: Icon(icon, size: 18, color: context.textPrimary),
      ),
    );
  }

  Widget _buildBottomSheet() {
    final cheapest = _getCheapestIndex();
    final fastest = _getFastestIndex();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.textHint, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            // Search fields with swap
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dots column
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 10),
                    child: Column(
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        Container(width: 2, height: 32, color: context.textHint),
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                  // Fields
                  Expanded(
                    child: Column(
                      children: [
                        // Saved places
                        if (_pickupController.text.isEmpty || _pickupLatLng == null)
                          Row(
                            children: [
                              if (_homePlace != null)
                                _savedPlaceChip('Home', Icons.home, _homePlace!),
                              if (_homePlace != null) const SizedBox(width: 8),
                              if (_workPlace != null)
                                _savedPlaceChip('Work', Icons.work, _workPlace!),
                              if (_homePlace != null || _workPlace != null)
                                const SizedBox(width: 8),
                              _savedPlaceChip('Current', LucideIcons.crosshair, null, isCurrent: true),
                            ],
                          ),
                        if (_pickupController.text.isEmpty || _pickupLatLng == null)
                          const SizedBox(height: 8),
                        _buildSearchField(
                          controller: _pickupController,
                          label: 'Pickup location',
                          results: _pickupResults,
                          isSearching: _isSearchingPickup,
                          onChanged: _onPickupSearch,
                          onTapResult: _selectPickup,
                        ),
                        const SizedBox(height: 8),
                        _buildSearchField(
                          controller: _dropoffController,
                          label: 'Where to?',
                          results: _dropoffResults,
                          isSearching: _isSearchingDropoff,
                          onChanged: _onDropoffSearch,
                          onTapResult: _selectDropoff,
                        ),
                      ],
                    ),
                  ),
                  // Swap button
                  if (_pickupLatLng != null || _dropoffLatLng != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 40),
                      child: GestureDetector(
                        onTap: _swapLocations,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: context.inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.cardBorder, width: 0.5),
                          ),
                          child: Icon(LucideIcons.arrowUpDown, size: 16, color: context.textPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Ride options
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _rideTypes.length,
                itemBuilder: (context, i) => _buildRideCard(i, cheapest: i == cheapest, fastest: i == fastest),
              ),
            ),
            // Payment & Book
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Payment method
                  GestureDetector(
                    onTap: () => _showPaymentSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.cardBorder, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _paymentMethod == 'cash' ? Icons.money : Icons.credit_card,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _paymentMethod == 'cash' ? 'Cash' : 'Card',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                          ),
                          const Spacer(),
                          Icon(LucideIcons.chevronRight, size: 16, color: context.textHint),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fare breakdown
                  if (_distanceKm > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _fareRow('Base fare', 'Rs. ${_rideTypes[_selectedRideIndex]['baseFare']}'),
                          _fareRow('Distance (${_distanceKm.toStringAsFixed(1)} km)', 'Rs. ${(_rideTypes[_selectedRideIndex]['perKm'] * _distanceKm).round()}'),
                          _fareRow('Time ($_etaMinutes min)', 'Rs. ${(_rideTypes[_selectedRideIndex]['perMin'] * _etaMinutes).round()}'),
                          const Divider(height: 12),
                          _fareRow('Total', 'Rs. ${_getFare(_selectedRideIndex)}', bold: true),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Book button
                  GestureDetector(
                    onTap: (_booking || _isMatching) ? null : _bookRide,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity, height: 56,
                      decoration: BoxDecoration(
                        gradient: (_booking || _isMatching) ? null : AppGradients.primary,
                        color: (_booking || _isMatching) ? context.textHint : null,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: (_booking || _isMatching) ? [] : AppGradients.glow,
                      ),
                      alignment: Alignment.center,
                      child: (_booking || _isMatching)
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _distanceKm > 0 ? 'Book Ride · Rs. ${_getFare(_selectedRideIndex)}' : 'Book Ride',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedPlaceChip(String label, IconData icon, Map<String, dynamic>? place, {bool isCurrent = false}) {
    return GestureDetector(
      onTap: isCurrent
          ? _useCurrentLocation
          : () {
              if (place != null && place['lat'] != null && place['lng'] != null) {
                final latLng = LatLng(place['lat'], place['lng']);
                setState(() {
                  _pickupLatLng = latLng;
                  _pickupController.text = place['address'] ?? label;
                  _pickupResults = [];
                });
                _fitMap();
                _calculateRoute();
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.green.withValues(alpha: 0.06) : context.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent ? AppColors.green.withValues(alpha: 0.15) : context.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isCurrent ? AppColors.green : context.textMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: context.textPrimary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.accent : context.textPrimary)),
        ],
      ),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _paymentOption('cash', Icons.money, 'Cash', 'Pay when you arrive'),
            const SizedBox(height: 8),
            _paymentOption('card', Icons.credit_card, 'Card', 'Coming soon', disabled: true),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(String value, IconData icon, String title, String subtitle, {bool disabled = false}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: disabled ? null : () {
        setState(() => _paymentMethod = value);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.06) : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: disabled ? context.textHint : AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: disabled ? context.textHint : context.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required List<Map<String, dynamic>> results,
    required bool isSearching,
    required ValueChanged<String> onChanged,
    required ValueChanged<Map<String, dynamic>> onTapResult,
  }) {
    final showRecent = results.isEmpty && !isSearching && controller.text.isEmpty && controller == _dropoffController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(color: context.inputBg, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
              suffixIcon: controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () { controller.clear(); onChanged(''); },
                      child: Icon(Icons.close, size: 18, color: context.textMuted),
                    )
                  : isSearching
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                      : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        if (showRecent && _recentSearches.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 140),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder, width: 0.5),
              boxShadow: context.cardShadow,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _recentSearches.length,
              itemBuilder: (context, i) {
                final recent = _recentSearches[i];
                return InkWell(
                  onTap: () { controller.text = recent['name']!; onChanged(recent['name']!); },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Icon(LucideIcons.clock, size: 14, color: context.textHint),
                        const SizedBox(width: 10),
                        Expanded(child: Text(recent['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.textMuted))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder, width: 0.5),
              boxShadow: context.cardShadow,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final item = results[i];
                return InkWell(
                  onTap: () => onTapResult(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 16, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item['display_name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.textPrimary))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRideCard(int index, {required bool cheapest, required bool fastest}) {
    final ride = _rideTypes[index];
    final isSelected = _selectedRideIndex == index;
    final fare = _distanceKm > 0 ? _getFare(index) : (ride['baseFare'] as int);
    final rideColor = ride['color'] as Color;
    final eta = _getEtaForRide(index);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRideIndex = index);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? rideColor.withValues(alpha: 0.06) : context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? rideColor : context.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isSelected ? rideColor.withValues(alpha: 0.12) : context.chipBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(ride['icon'] as IconData, size: 24, color: isSelected ? rideColor : context.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(ride['name'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
                      if (cheapest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Cheapest', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green)),
                        ),
                      ],
                      if (fastest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Fastest', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${ride['capacity']} · $eta', style: TextStyle(fontSize: 13, color: context.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. $fare', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isSelected ? rideColor : context.textPrimary)),
                if (_distanceKm > 0) Text('${_distanceKm.toStringAsFixed(1)} km', style: TextStyle(fontSize: 11, color: context.textMuted)),
              ],
            ),
          ],
        ),
      ),
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
      if (len == 0) {
        points.add(LatLng(lat, lng));
        continue;
      }
      final perpX = -dy / len;
      final perpY = dx / len;
      points.add(LatLng(lat + perpX * offset, lng + perpY * offset));
    }
    return points;
  }

  List<LatLng> _buildDashedPoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 60;
    for (int i = 0; i <= steps; i++) {
      // Skip every other segment for dashed effect
      if ((i ~/ 3) % 2 == 0) continue;
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final offset = math.sin(t * math.pi) * 0.002;
      final dx = end.longitude - start.longitude;
      final dy = end.latitude - start.latitude;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) {
        points.add(LatLng(lat, lng));
        continue;
      }
      final perpX = -dy / len;
      final perpY = dx / len;
      points.add(LatLng(lat + perpX * offset, lng + perpY * offset));
    }
    return points;
  }
}
