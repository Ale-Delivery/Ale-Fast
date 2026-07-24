import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../services/google_maps_service.dart';
import '../services/osrm_service.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'ride_map_screen.dart';
import 'live_ride_screen.dart';

class RidesScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  const RidesScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
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

  final List<Map<String, dynamic>> _rideTypes = const [
    {'name': 'Bike', 'icon': LucideIcons.bike, 'baseFare': 60, 'perKm': 25, 'perMin': 5, 'capacity': '1 person', 'color': Color(0xFF3B82F6), 'speed': 35},
    {'name': 'Tuk', 'icon': LucideIcons.car, 'baseFare': 100, 'perKm': 50, 'perMin': 8, 'capacity': '3 persons', 'color': Color(0xFFF59E0B), 'speed': 30},
    {'name': 'Car', 'icon': LucideIcons.car, 'baseFare': 150, 'perKm': 80, 'perMin': 12, 'capacity': '4 persons', 'color': Color(0xFF8B5CF6), 'speed': 25},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
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
    _calculateRoute();
  }

  void _saveRecent(String? name, String type) {
    if (name == null || name.isEmpty) return;
    _recentSearches.removeWhere((r) => r['name'] == name);
    _recentSearches.insert(0, {'name': name, 'type': type});
    if (_recentSearches.length > 5) _recentSearches = _recentSearches.sublist(0, 5);
  }

  void _useCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);
      final address = await GoogleMapsService.reverseGeocode(latLng.latitude, latLng.longitude);
      setState(() {
        _pickupLatLng = latLng;
        _pickupController.text = address;
        _pickupResults = [];
      });
      _calculateRoute();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  // ── Map screen ───────────────────────────────────────────
  Future<void> _openMapScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const RideMapScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _pickupLatLng = LatLng(result['pickup_lat'], result['pickup_lng']);
        _pickupController.text = result['pickup_name'] ?? '';
        _dropoffLatLng = LatLng(result['dropoff_lat'], result['dropoff_lng']);
        _dropoffController.text = result['dropoff_name'] ?? '';
      });
      _calculateRoute();
    }
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
    _calculateRoute();
    HapticFeedback.lightImpact();
  }

  // ── Calculations ─────────────────────────────────────────
  void _calculateRoute() {
    if (_pickupLatLng == null || _dropoffLatLng == null) {
      setState(() { _distanceKm = 0; _etaMinutes = 0; });
      return;
    }

    OsrmService.getDistanceAndEta(_pickupLatLng!, _dropoffLatLng!).then((result) {
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _distanceKm = (result['distance_km'] as num).toDouble();
          _etaMinutes = (result['eta_min'] as num).toInt();
        });
      } else {
        final meters = Distance().as(LengthUnit.Meter, _pickupLatLng!, _dropoffLatLng!);
        final km = meters / 1000;
        setState(() {
          _distanceKm = km;
          _etaMinutes = (km * 2).ceil().clamp(3, 60);
        });
      }
    });
  }

  int _getFare(int index) {
    final ride = _rideTypes[index];
    return (ride['baseFare'] + (ride['perKm'] * _distanceKm) + (ride['perMin'] * _etaMinutes)).round();
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
      if (fare < lowest) { lowest = fare; cheapest = i; }
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
      if (min < lowestMin) { lowestMin = min; fastest = i; }
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

    setState(() { _isMatching = true; _booking = true; });
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

    // Save ride order
    _saveRideOrder(fare);

    // Navigate to live ride
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRideScreen(
          rideData: {
            'pickup_lat': _pickupLatLng!.latitude,
            'pickup_lng': _pickupLatLng!.longitude,
            'dropoff_lat': _dropoffLatLng!.latitude,
            'dropoff_lng': _dropoffLatLng!.longitude,
            'pickup_name': _pickupController.text,
            'dropoff_name': _dropoffController.text,
            'ride_type': ride['name'],
            'fare': fare,
            'distance_km': _distanceKm,
            'eta_min': _etaMinutes,
            'base_fare': ride['baseFare'],
            'distance_fare': (ride['perKm'] * _distanceKm).round(),
            'time_fare': (ride['perMin'] * _etaMinutes).round(),
            'driver': driver,
            'payment': _paymentMethod,
          },
        ),
      ),
    ).then((_) {
      setState(() { _matchedDriver = null; });
    });
  }

  Future<void> _saveRideOrder(int fare) async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('Ride_Orders').insert({
        'user_id': userId,
        'pickup_name': _pickupController.text,
        'dropoff_name': _dropoffController.text,
        'pickup_lat': _pickupLatLng!.latitude,
        'pickup_lng': _pickupLatLng!.longitude,
        'dropoff_lat': _dropoffLatLng!.latitude,
        'dropoff_lng': _dropoffLatLng!.longitude,
        'ride_type': _rideTypes[_selectedRideIndex]['name'],
        'fare': fare,
        'distance_km': _distanceKm,
        'eta_min': _etaMinutes,
        'driver_name': _matchedDriver?['name'] ?? '',
        'driver_vehicle': _matchedDriver?['vehicle'] ?? '',
        'payment_method': _paymentMethod,
        'status': 'completed',
      });
    } catch (_) {}
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
              // Back header
              Container(
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: context.inputBg, borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.arrowLeft, size: 18, color: context.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Book a Ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select on Map button
                      GestureDetector(
                        onTap: _openMapScreen,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppGradients.glow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(LucideIcons.map, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Select on Map', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _pickupLatLng != null && _dropoffLatLng != null
                                          ? 'Tap to change locations'
                                          : 'Pick pickup & drop-off points',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.8), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Selected locations summary
                      if (_pickupLatLng != null || _dropoffLatLng != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.cardBorder, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  Container(width: 2, height: 24, color: context.textHint),
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickupController.text.isNotEmpty ? _pickupController.text : 'Pickup not set',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _pickupLatLng != null ? context.textPrimary : context.textHint),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _dropoffController.text.isNotEmpty ? _dropoffController.text : 'Drop-off not set',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dropoffLatLng != null ? context.textPrimary : context.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              if (_pickupLatLng != null && _dropoffLatLng != null)
                                GestureDetector(
                                  onTap: _swapLocations,
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: context.inputBg, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(LucideIcons.arrowUpDown, size: 16, color: context.textPrimary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Search fields
                      _buildSearchField(
                        controller: _pickupController,
                        label: 'Search pickup...',
                        results: _pickupResults,
                        isSearching: _isSearchingPickup,
                        onChanged: _onPickupSearch,
                        onTapResult: _selectPickup,
                      ),
                      const SizedBox(height: 10),
                      _buildSearchField(
                        controller: _dropoffController,
                        label: 'Search drop-off...',
                        results: _dropoffResults,
                        isSearching: _isSearchingDropoff,
                        onChanged: _onDropoffSearch,
                        onTapResult: _selectDropoff,
                      ),
                      const SizedBox(height: 20),
                      // Ride options
                      Text('Choose ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
                      const SizedBox(height: 12),
                      ...List.generate(_rideTypes.length, (i) => _buildRideCard(i, cheapest: i == _getCheapestIndex(), fastest: i == _getFastestIndex())),
                      const SizedBox(height: 16),
                      // Payment
                      GestureDetector(
                        onTap: _showPaymentSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.cardBorder, width: 0.5)),
                          child: Row(
                            children: [
                              Icon(_paymentMethod == 'cash' ? Icons.money : Icons.credit_card, size: 18, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Text(_paymentMethod == 'cash' ? 'Cash' : 'Card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                              const Spacer(),
                              Icon(LucideIcons.chevronRight, size: 16, color: context.textHint),
                            ],
                          ),
                        ),
                      ),
                      // Fare breakdown
                      if (_distanceKm > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(12)),
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
                      ],
                    ],
                  ),
                ),
              ),
              // Book button
              Container(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(color: context.cardBg, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
                child: GestureDetector(
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
              ),
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
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 3)),
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required List<Map<String, dynamic>> results,
    required bool isSearching,
    required ValueChanged<String> onChanged,
    required ValueChanged<Map<String, dynamic>> onTapResult,
  }) {
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
          border: Border.all(color: isSelected ? rideColor : context.cardBorder, width: isSelected ? 1.5 : 0.5),
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
        decoration: BoxDecoration(color: context.cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
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
      onTap: disabled ? null : () { setState(() => _paymentMethod = value); Navigator.pop(context); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.06) : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accent : context.cardBorder, width: isSelected ? 1.5 : 0.5),
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
}
