import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String restaurantId;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.restaurantId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();
  final List<double> _starScales = [1, 1, 1, 1, 1];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onStarTap(int index) {
    setState(() {
      _rating = index + 1;
    });
    // Animate the tapped star then settle
    for (int i = 0; i < 5; i++) {
      if (i <= index) {
        _starScales[i] = 1.3;
      } else {
        _starScales[i] = 0.9;
      }
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      for (int i = 0; i < 5; i++) {
        _starScales[i] = 1.0;
      }
      setState(() {});
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('Reviews').insert({
        'order_id': widget.orderId,
        'user_id': userId!,
        'restaurant_id': widget.restaurantId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Review submitted successfully!'),
            ],
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _ratingLabel() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: context.appBarBg,
            surfaceTintColor: Colors.transparent,
            title: const Text('Rate Your Order'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'How was your order?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _rating > 0 ? AppColors.orange : context.textMuted,
                    ),
                  ).animate(key: ValueKey(_rating)).fadeIn(duration: 200.ms),
                  const SizedBox(height: 36),
                  // Star row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isSelected = index < _rating;
                      return GestureDetector(
                        onTap: () => _onStarTap(index),
                        child: AnimatedScale(
                          scale: _starScales[index],
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutBack,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              key: ValueKey('$index-$isSelected'),
                              size: 52,
                              color: isSelected ? AppColors.star : context.textMuted,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 100 + index * 60),
                          ).scale(begin: const Offset(0.5, 0.5));
                    }),
                  ),
                  const SizedBox(height: 48),
                  // Comment field
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: context.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Write your review (optional)',
                        hintStyle: TextStyle(color: context.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        counterStyle: TextStyle(color: context.textMuted, fontSize: 12),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 36),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _rating > 0 ? AppGradients.primary : null,
                        color: _rating == 0 ? context.cardBorder : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 500.ms).slideY(begin: 0.15),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
