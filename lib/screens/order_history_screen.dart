import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../navigation/buyer_navigator.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await OrderService.getUserOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _loading = false;
      });
    }
  }

  Future<void> _reorder(Order order) async {
    try {
      final items = await OrderService.getOrderItems(order.id);
      if (items.isEmpty || !mounted) return;

      final cart = context.read<CartProvider>();
      cart.clearCart();

      for (final item in items) {
        if (item.foodItemId == null) continue;
        final response = await Supabase.instance.client
            .from('Menu_Items')
            .select()
            .eq('id', item.foodItemId!)
            .maybeSingle();
        if (response == null) continue;

        final food = FoodItem.fromJson(Map<String, dynamic>.from(response));
        cart.addItem(food, size: item.selectedSize ?? 'Regular');
        if (cart.items.length > 1) {
          final lastItem = cart.items.last;
          while (lastItem.quantity < item.quantity) {
            cart.addItem(food, size: item.selectedSize ?? 'Regular');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${items.length} item(s) added to cart'),
            backgroundColor: AppColors.green,
          ),
        );
        BuyerNavigator.cart(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reorder. Items may be unavailable.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(Order order) async {
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

    setState(() => _cancellingId = order.id);
    try {
      await OrderService.cancelOrder(order.id);
      await _load();
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.pending:
        return Colors.amber;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Order History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      const Text('No orders yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Your orders will appear here',
                          style: TextStyle(color: context.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final order = _orders[i];
                      final date = order.createdAt != null
                          ? DateFormat('MMM d, h:mm a')
                              .format(order.createdAt!)
                          : '';

                      return GestureDetector(
                        onTap: () =>
                            BuyerNavigator.orderTracking(context, order.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(order.restaurantName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15)),
                                  ),
                                  Text('Rs. ${order.total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.orange)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(order.status)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.status.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(order.status),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (order.status == OrderStatus.pending || order.status == OrderStatus.accepted)
                                    _cancellingId == order.id
                                        ? const SizedBox(
                                            width: 16, height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                          )
                                        : GestureDetector(
                                            onTap: () => _cancelOrder(order),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                  if (order.status == OrderStatus.pending || order.status == OrderStatus.accepted)
                                    const SizedBox(width: 8),
                                  if (order.status == OrderStatus.delivered)
                                    GestureDetector(
                                      onTap: () => _reorder(order),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Reorder',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (order.status == OrderStatus.delivered)
                                    const SizedBox(width: 8),
                                  if (date.isNotEmpty)
                                    Text(date,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: context.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
