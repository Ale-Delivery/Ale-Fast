import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  List<OrderItemLine> _items = [];
  bool _loading = true;
  bool _cancelling = false;

  static const _steps = [
    ('pending', 'Order placed', 'Waiting for restaurant to accept'),
    ('accepted', 'Accepted', 'Restaurant confirmed your order'),
    ('preparing', 'Preparing', 'Your food is being prepared'),
    ('ready', 'Ready', 'Ready for rider pickup'),
    ('on_the_way', 'On the way', 'Rider is delivering to you'),
    ('delivered', 'Delivered', 'Enjoy your meal!'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await OrderService.getOrder(widget.orderId);
    final items = await OrderService.getOrderItems(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel order?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, keep it', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await OrderService.cancelOrder(widget.orderId);
      await _load();
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Track Order',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : _order == null
              ? const Center(child: Text('Order not found'))
              : StreamBuilder<Order?>(
                  stream: OrderService.watchOrder(widget.orderId),
                  initialData: _order,
                  builder: (context, snapshot) {
                    final order = snapshot.data ?? _order!;
                    final currentStep = order.status.stepIndex;

                    return RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.orange,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.restaurantName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  '#${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                                  style: TextStyle(
                                      color: context.textMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    order.status.label,
                                    style: const TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text('Rs. ${order.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.orange)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Order progress',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (order.status == OrderStatus.cancelled)
                            const ListTile(
                              leading: Icon(Icons.cancel, color: Colors.red),
                              title: Text('This order was cancelled'),
                            )
                          else
                            ...List.generate(_steps.length, (i) {
                              final done = i <= currentStep;
                              final active = i == currentStep;
                              return _stepTile(
                                done: done,
                                active: active,
                                title: _steps[i].$2,
                                subtitle: _steps[i].$3,
                                isLast: i == _steps.length - 1,
                              );
                            }),
                          const SizedBox(height: 20),
                          const Text('Items',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 8),
                          ..._items.map((item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.name),
                                subtitle: Text(
                                    '${item.quantity}x ${item.selectedSize ?? ''}'),
                                trailing: Text(
                                    'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              )),
                        if (order.status == OrderStatus.pending || order.status == OrderStatus.accepted) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _cancelling ? null : _cancelOrder,
                              icon: _cancelling
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                    )
                                  : const Icon(Icons.cancel_outlined, color: Colors.red),
                              label: Text(
                                _cancelling ? 'Cancelling...' : 'Cancel Order',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _stepTile({
    required bool done,
    required bool active,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.orange : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: done ? Colors.white : context.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.orange : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: active ? AppColors.orange : context.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
