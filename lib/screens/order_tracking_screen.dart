import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
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
                              color: Colors.white,
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
                                  '#${order.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                      color: AppColors.grey, fontSize: 12),
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
                  color: done ? AppColors.orange : AppColors.greyLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: done ? Colors.white : AppColors.grey,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.orange : AppColors.greyLight,
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
                          color: active ? AppColors.orange : AppColors.dark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
