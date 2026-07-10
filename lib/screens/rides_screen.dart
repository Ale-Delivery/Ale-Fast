import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  int _selectedRideIndex = 1;

  final List<Map<String, dynamic>> _rideTypes = const [
    {
      'name': 'Bike',
      'icon': LucideIcons.bike,
      'fare': 'Rs. 150',
      'time': '5 min',
      'capacity': '1 person',
    },
    {
      'name': 'Tuk',
      'icon': LucideIcons.car,
      'fare': 'Rs. 300',
      'time': '8 min',
      'capacity': '3 persons',
    },
    {
      'name': 'Car',
      'icon': LucideIcons.car,
      'fare': 'Rs. 500',
      'time': '10 min',
      'capacity': '4 persons',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          _buildMapSection(),
          _buildRideOptions(),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.chipBg,
      ),
      child: Stack(
        children: [
          // Minimalist map placeholder
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.map,
                color: AppColors.accent.withValues(alpha: 0.3),
                size: 48,
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _circleButton(LucideIcons.arrowLeft, () => Navigator.pop(context)),
          ),
          // Locate button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _circleButton(LucideIcons.crosshair, () {}),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: context.cardShadow,
        ),
        child: Icon(icon, size: 20, color: context.textPrimary),
      ),
    );
  }

  Widget _buildRideOptions() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Choose ride',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Ride type cards
            ...List.generate(_rideTypes.length, (i) {
              final ride = _rideTypes[i];
              final isSelected = _selectedRideIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedRideIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.06)
                        : context.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : context.cardBorder,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : context.chipBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          ride['icon'] as IconData,
                          size: 22,
                          color: isSelected ? AppColors.accent : context.textMuted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride['name'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ride['time']} · ${ride['capacity']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ride['fare'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.accent : context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            // Book button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Book Ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
