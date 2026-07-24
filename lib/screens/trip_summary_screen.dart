import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'rate_driver_screen.dart';

class TripSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> rideData;
  const TripSummaryScreen({super.key, required this.rideData});

  @override
  Widget build(BuildContext context) {
    final driver = rideData['driver'] as Map<String, dynamic>? ?? {};
    final driverName = driver['name']?.toString() ?? 'Driver';
    final vehicle = driver['vehicle']?.toString() ?? 'ABC-1234';
    final rideName = rideData['ride_type']?.toString() ?? 'Bike';
    final fare = rideData['fare'] ?? 0;
    final pickupName = rideData['pickup_name']?.toString() ?? 'Pickup';
    final dropoffName = rideData['dropoff_name']?.toString() ?? 'Destination';
    final distance = rideData['actual_distance'] ?? rideData['distance_km'] ?? 0.0;
    final time = rideData['actual_time'] ?? rideData['eta_min'] ?? 0;
    final baseFare = rideData['base_fare'] ?? 0;
    final distanceFare = rideData['distance_fare'] ?? 0;
    final timeFare = rideData['time_fare'] ?? 0;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.green, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Trip Complete!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'You have reached your destination',
                style: TextStyle(fontSize: 15, color: context.textMuted),
              ),
              const SizedBox(height: 32),

              // Route summary
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                  boxShadow: context.cardShadow,
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                        Container(width: 2, height: 32, color: context.textHint),
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pickupName, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                          const SizedBox(height: 16),
                          Text(dropoffName, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Driver info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(gradient: AppGradients.avatar, borderRadius: BorderRadius.circular(14)),
                      child: Center(
                        child: Text(driverName[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverName, style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary)),
                          const SizedBox(height: 2),
                          Text('$vehicle · $rideName', style: TextStyle(fontSize: 13, color: context.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trip stats
              Row(
                children: [
                  _statCard('Distance', '${distance.toStringAsFixed(1)} km', LucideIcons.mapPin, AppColors.blue, context),
                  const SizedBox(width: 12),
                  _statCard('Duration', '$time min', LucideIcons.clock, AppColors.green, context),
                  const SizedBox(width: 12),
                  _statCard('Ride', rideName, LucideIcons.bike, AppColors.purple, context),
                ],
              ),
              const SizedBox(height: 16),

              // Fare breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                ),
                child: Column(
                  children: [
                    _fareRow('Base fare', 'Rs. $baseFare'),
                    _fareRow('Distance (${distance.toStringAsFixed(1)} km)', 'Rs. $distanceFare'),
                    _fareRow('Time ($time min)', 'Rs. $timeFare'),
                    const Divider(height: 20),
                    _fareRow('Total', 'Rs. $fare', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rate button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RateDriverScreen(rideData: rideData),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Rate Driver', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              // Skip
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Skip for now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
            Text(label, style: TextStyle(fontSize: 11, color: context.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            color: bold ? null : null,
          )),
          Text(value, style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppColors.green : null,
          )),
        ],
      ),
    );
  }
}
