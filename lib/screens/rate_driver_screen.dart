import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class RateDriverScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;
  const RateDriverScreen({super.key, required this.rideData});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _rating = 0;
  String _selectedFeedback = '';
  final _commentController = TextEditingController();
  bool _submitting = false;

  final List<String> _quickFeedback = [
    'Great driving',
    'Clean vehicle',
    'Friendly',
    'On time',
    'Good music',
    'Smooth ride',
    'Safe driving',
    'Nice conversation',
  ];

  final Map<int, String> _ratingLabels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Great',
    5: 'Excellent',
  };

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);

    final userId = await LocalStorageService.getUserId();
    final driver = widget.rideData['driver'] as Map<String, dynamic>? ?? {};

    try {
      await Supabase.instance.client.from('Ride_Ratings').insert({
        'user_id': userId,
        'driver_name': driver['name']?.toString() ?? '',
        'ride_type': widget.rideData['ride_type']?.toString() ?? '',
        'rating': _rating,
        'feedback': _selectedFeedback,
        'comment': _commentController.text.trim(),
        'fare': widget.rideData['fare'],
        'pickup': widget.rideData['pickup_name']?.toString() ?? '',
        'dropoff': widget.rideData['dropoff_name']?.toString() ?? '',
      });
    } catch (_) {}

    setState(() => _submitting = false);
    HapticFeedback.heavyImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thanks for your feedback!'),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.rideData['driver'] as Map<String, dynamic>? ?? {};
    final driverName = driver['name']?.toString() ?? 'Driver';
    final vehicle = driver['vehicle']?.toString() ?? 'ABC-1234';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Driver avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(gradient: AppGradients.avatar, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    driverName.isNotEmpty ? driverName[0] : 'D',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How was your trip with',
                style: TextStyle(fontSize: 18, color: context.textMuted),
              ),
              Text(
                driverName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              Text(
                vehicle,
                style: TextStyle(fontSize: 14, color: context.textMuted),
              ),
              const SizedBox(height: 32),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  final isActive = starIndex <= _rating;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _rating = starIndex);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isActive ? Icons.star : Icons.star_border,
                        size: 44,
                        color: isActive ? AppColors.accent : context.textHint,
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 8),
                Text(
                  _ratingLabels[_rating] ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.accent),
                ),
              ],
              const SizedBox(height: 32),

              // Quick feedback chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What did you like?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickFeedback.map((fb) {
                  final isSelected = _selectedFeedback == fb;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedFeedback = isSelected ? '' : fb);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : context.cardBorder,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        fb,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.accent : context.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Comment field
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a comment (optional)',
                    hintStyle: TextStyle(color: context.textHint),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(
                  'Skip',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
