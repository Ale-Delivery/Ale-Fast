import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class OrderSummaryCard extends StatelessWidget {
  final Order order;

  const OrderSummaryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _row('Subtotal', 'Rs. ${order.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          if (order.deliveryFee > 0) ...[
            _row(
              'Delivery Fee',
              order.deliveryFee == 0
                  ? 'Free'
                  : 'Rs. ${order.deliveryFee.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
          ],
          if (order.serviceFee > 0) ...[
            _row('Service Fee', 'Rs. ${order.serviceFee.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
          ],
          if (order.tip > 0) ...[
            _row('Tip', 'Rs. ${order.tip.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
          ],
          if (order.discount > 0) ...[
            _row('Discount', '- Rs. ${order.discount.toStringAsFixed(0)}',
                valueColor: AppColors.green),
            const SizedBox(height: 8),
          ],
          const Divider(height: 1),
          const SizedBox(height: 12),
          _row(
            'Total',
            'Rs. ${order.total.toStringAsFixed(0)}',
            isTotal: true,
            valueColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? Colors.black87 : AppColors.muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
