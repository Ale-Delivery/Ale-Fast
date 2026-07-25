import 'package:flutter/material.dart';
import '../../models/models.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: config.textColor,
        ),
      ),
    );
  }

  static _StatusConfig _configFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const _StatusConfig(
          label: 'Pending',
          bgColor: Color(0xFFFFF3E0),
          textColor: Color(0xFFE65100),
        );
      case OrderStatus.accepted:
        return const _StatusConfig(
          label: 'Accepted',
          bgColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
        );
      case OrderStatus.preparing:
        return const _StatusConfig(
          label: 'Preparing',
          bgColor: Color(0xFFE3F2FD),
          textColor: Color(0xFF1565C0),
        );
      case OrderStatus.ready:
        return const _StatusConfig(
          label: 'Ready for pickup',
          bgColor: Color(0xFFE3F2FD),
          textColor: Color(0xFF1565C0),
        );
      case OrderStatus.onTheWay:
        return const _StatusConfig(
          label: 'On the way',
          bgColor: Color(0xFFF3E5F5),
          textColor: Color(0xFF7B1FA2),
        );
      case OrderStatus.delivered:
        return const _StatusConfig(
          label: 'Delivered',
          bgColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
        );
      case OrderStatus.cancelled:
        return const _StatusConfig(
          label: 'Cancelled',
          bgColor: Color(0xFFFFEBEE),
          textColor: Color(0xFFC62828),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusConfig({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}
