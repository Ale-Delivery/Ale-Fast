import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded,
                color: Color(0xFFC62828), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This order has been cancelled.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final steps = _buildSteps();
    final currentStep = status.stepIndex;

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = i <= currentStep;
        final active = i == currentStep;
        final isLast = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: done ? AppColors.accent : const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle_outlined,
                      size: 18,
                      color: done ? Colors.white : AppColors.muted,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color:
                            done ? AppColors.accent : const Color(0xFFE0E0E0),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.accent : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<_TimelineStep> _buildSteps() {
    return [
      _TimelineStep('Placed', 'Order has been placed'),
      _TimelineStep('Confirmed', 'Restaurant confirmed your order'),
      _TimelineStep('Preparing', 'Your food is being prepared'),
      _TimelineStep('On the way', 'Rider is delivering to you'),
      _TimelineStep('Delivered', 'Enjoy your meal!'),
    ];
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;

  const _TimelineStep(this.title, this.subtitle);
}
