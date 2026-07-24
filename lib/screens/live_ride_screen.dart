import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/osrm_service.dart';
import 'trip_summary_screen.dart';

class LiveRideScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;
  const LiveRideScreen({super.key, required this.rideData});

  @override
  State<LiveRideScreen> createState() => _LiveRideScreenState();
}

class _LiveRideScreenState extends State<LiveRideScreen> {
  final MapController _mapController = MapController();
  late LatLng _pickup;
  late LatLng _dropoff;
  late LatLng _driverLocation;
  String _status = 'arriving';
  int _etaMinutes = 0;
  double _distanceRemaining = 0;
  List<LatLng> _routePoints = [];
  Timer? _driverTimer;

  @override
  void initState() {
    super.initState();
    _pickup = LatLng(widget.rideData['pickup_lat'], widget.rideData['pickup_lng']);
    _dropoff = LatLng(widget.rideData['dropoff_lat'], widget.rideData['dropoff_lng']);
    _distanceRemaining = widget.rideData['distance_km'] ?? 5.0;
    _etaMinutes = (_distanceRemaining * 2).ceil().clamp(1, 60);

    // Start driver near pickup, slightly offset
    final offsetLat = _pickup.latitude + (math.Random().nextDouble() - 0.5) * 0.005;
    final offsetLng = _pickup.longitude + (math.Random().nextDouble() - 0.5) * 0.005;
    _driverLocation = LatLng(offsetLat, offsetLng);

    _fetchOsrmRoute();
    _startDriverSimulation();
  }

  void _fetchOsrmRoute() {
    OsrmService.getRoute(_pickup, _dropoff).then((result) {
      if (!mounted) return;
      final roadDistance = result.isSuccess ? result.distanceKm : _distanceRemaining;
      final roadEta = result.isSuccess ? result.durationMin.round() : _etaMinutes;
      setState(() {
        _routePoints = result.routePoints.isNotEmpty ? result.routePoints : [_pickup, _dropoff];
        _distanceRemaining = roadDistance;
        _etaMinutes = roadEta;
      });
    });
  }

  @override
  void dispose() {
    _driverTimer?.cancel();
    super.dispose();
  }

  void _startDriverSimulation() {
    _driverTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) { timer.cancel(); return; }

      final target = _status == 'arriving' ? _pickup : _dropoff;
      final latDiff = target.latitude - _driverLocation.latitude;
      final lngDiff = target.longitude - _driverLocation.longitude;
      final dist = math.sqrt(latDiff * latDiff + lngDiff * lngDiff);

      if (dist < 0.0003) {
        if (_status == 'arriving') {
          setState(() {
            _status = 'in_progress';
            _etaMinutes = (_distanceRemaining * 2).ceil().clamp(1, 60);
          });
          HapticFeedback.heavyImpact();
        } else if (_status == 'in_progress') {
          setState(() {
            _status = 'arrived';
            _etaMinutes = 0;
          });
          timer.cancel();
          HapticFeedback.heavyImpact();
          _onRideComplete();
        }
        return;
      }

      final speed = _status == 'arriving' ? 0.0008 : 0.0005;
      setState(() {
        _driverLocation = LatLng(
          _driverLocation.latitude + latDiff * speed,
          _driverLocation.longitude + lngDiff * speed,
        );
        if (_status == 'in_progress') {
          _distanceRemaining = math.max(0, _distanceRemaining - 0.15);
          _etaMinutes = (_distanceRemaining * 2).ceil().clamp(0, 60);
        }
      });
    });
  }

  void _onRideComplete() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TripSummaryScreen(
            rideData: {
              ...widget.rideData,
              'actual_distance': (widget.rideData['distance_km'] ?? 5.0),
              'actual_time': widget.rideData['eta_min'] ?? 10,
              'completed_at': DateTime.now().toIso8601String(),
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          _buildStatusSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final bounds = LatLngBounds.fromPoints([_pickup, _dropoff, _driverLocation]);
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: bounds.center,
        initialZoom: 14,
        onMapReady: () => _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60))),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.alefast.client',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints.isNotEmpty ? _routePoints : [_pickup, _dropoff],
              color: AppColors.blue.withValues(alpha: 0.4),
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _pickup,
              width: 36, height: 36,
              child: Container(
                decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                child: const Icon(Icons.circle, color: Colors.white, size: 10),
              ),
            ),
            Marker(
              point: _dropoff,
              width: 36, height: 36,
              child: Container(
                decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                child: const Icon(Icons.location_on, color: Colors.white, size: 16),
              ),
            ),
            Marker(
              point: _driverLocation,
              width: 48, height: 48,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.4), blurRadius: 12)],
                ),
                child: const Icon(LucideIcons.bike, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: context.inputBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(LucideIcons.arrowLeft, size: 18, color: context.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status == 'arriving' ? 'Driver is arriving' : _status == 'in_progress' ? 'On the way' : 'Arrived at destination',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
                  ),
                  Text(
                    _status == 'arrived' ? 'You have reached your destination' : 'ETA: $_etaMinutes min',
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _status == 'arriving'
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : _status == 'in_progress'
                        ? AppColors.green.withValues(alpha: 0.1)
                        : AppColors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _status == 'arriving' ? 'En route' : _status == 'in_progress' ? 'Riding' : 'Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _status == 'arrived' ? Colors.white : AppColors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSheet() {
    final driver = widget.rideData['driver'] as Map<String, dynamic>? ?? {};
    final driverName = driver['name']?.toString() ?? 'Driver';
    final vehicle = driver['vehicle']?.toString() ?? 'ABC-1234';
    final rideName = widget.rideData['ride_type']?.toString() ?? 'Bike';
    final fare = widget.rideData['fare'] ?? 0;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // Driver info
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(gradient: AppGradients.avatar, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Text(driverName[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(LucideIcons.star, size: 13, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text('${driver['rating'] ?? 4.8}', style: TextStyle(fontSize: 13, color: context.textMuted)),
                          const SizedBox(width: 8),
                          Text(vehicle, style: TextStyle(fontSize: 13, color: context.textMuted)),
                          const SizedBox(width: 8),
                          Text(rideName, style: TextStyle(fontSize: 13, color: context.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.phone, color: AppColors.green, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(LucideIcons.messageCircle, color: AppColors.blue, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ETA bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _status == 'arriving'
                    ? AppColors.blue.withValues(alpha: 0.06)
                    : _status == 'in_progress'
                        ? AppColors.green.withValues(alpha: 0.06)
                        : AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _status == 'arriving' ? LucideIcons.navigation : _status == 'in_progress' ? LucideIcons.mapPin : LucideIcons.checkCircle,
                    size: 20,
                    color: _status == 'arriving' ? AppColors.blue : AppColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _status == 'arriving'
                              ? 'Driver heading to pickup'
                              : _status == 'in_progress'
                                  ? 'On the way to destination'
                                  : 'You have arrived!',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                        ),
                        if (_status != 'arrived')
                          Text(
                            'Rs.$fare · ${_distanceRemaining.toStringAsFixed(1)} km remaining',
                            style: TextStyle(fontSize: 12, color: context.textMuted),
                          ),
                      ],
                    ),
                  ),
                  if (_status != 'arrived')
                    Text(
                      '$_etaMinutes min',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _status == 'arriving' ? AppColors.blue : AppColors.green),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
