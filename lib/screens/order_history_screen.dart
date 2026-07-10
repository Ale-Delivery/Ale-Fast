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

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _loading = true;
  String? _cancellingId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  List<Order> _getOngoing() => _orders.where((o) =>
      o.status == OrderStatus.pending ||
      o.status == OrderStatus.accepted ||
      o.status == OrderStatus.preparing ||
      o.status == OrderStatus.onTheWay).toList();

  List<Order> _getCompleted() => _orders
      .where((o) => o.status == OrderStatus.delivered)
      .toList();

  List<Order> _getCancelled() => _orders
      .where((o) => o.status == OrderStatus.cancelled)
      .toList();

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
        title: const Text('Cancel order?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, keep it',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  IconData _serviceIcon(String name) {
    if (name.toLowerCase().contains('ride')) return Icons.two_wheeler_rounded;
    if (name.toLowerCase().contains('parcel')) return Icons.inventory_2_rounded;
    return Icons.restaurant_rounded;
  }

  Color _serviceColor(String name) {
    if (name.toLowerCase().contains('ride')) return const Color(0xFF00C6FF);
    if (name.toLowerCase().contains('parcel')) return const Color(0xFF6C5CE7);
    return AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Activities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          indicatorWeight: 3,
          labelColor: AppColors.orange,
          unselectedLabelColor: context.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Ongoing (${_getOngoing().length})'),
            Tab(text: 'Completed (${_getCompleted().length})'),
            Tab(text: 'Cancelled (${_getCancelled().length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.orange,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(_getOngoing(), isEmpty: 'No ongoing orders', emptyIcon: Icons.local_shipping_outlined),
                  _buildOrderList(_getCompleted(), isEmpty: 'No completed orders', emptyIcon: Icons.check_circle_outline),
                  _buildOrderList(_getCancelled(), isEmpty: 'No cancelled orders', emptyIcon: Icons.cancel_outlined),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {required String isEmpty, required IconData emptyIcon}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, color: context.textMuted, size: 56),
            const SizedBox(height: 12),
            Text(isEmpty,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Your orders will appear here',
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final order = orders[i];
        final date = order.createdAt != null
            ? DateFormat('MMM d, h:mm a').format(order.createdAt!)
            : '';
        final sColor = _serviceColor(order.restaurantName);
        final sIcon = _serviceIcon(order.restaurantName);

        return GestureDetector(
          onTap: () => BuyerNavigator.orderTracking(context, order.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(sIcon, color: sColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.restaurantName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(order.deliveryAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: context.textMuted)),
                        ],
                      ),
                    ),
                    Text('Rs. ${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
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
                    if (order.status == OrderStatus.pending ||
                        order.status == OrderStatus.accepted)
                      _cancellingId == order.id
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red),
                            )
                          : GestureDetector(
                              onTap: () => _cancelOrder(order),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
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
                    if (order.status == OrderStatus.delivered)
                      GestureDetector(
                        onTap: () => _reorder(order),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                    if (date.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(date,
                          style: TextStyle(
                              fontSize: 11, color: context.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
