import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final bool isEmbedded;
  const OrderHistoryScreen({super.key, this.isEmbedded = false});

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
      debugPrint('Reorder error: $e');
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancellingId = order.id);
    try {
      await OrderService.cancelOrder(order.id);
      await _load();
    } catch (e) {
      debugPrint('Cancel error: $e');
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Your Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2.5,
              labelColor: AppColors.accent,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_getOngoing(), isOngoing: true),
                _buildOrderList(_getCompleted()),
                _buildOrderList(_getCancelled()),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {bool isOngoing = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clipboardList, size: 48, color: context.textHint),
            const SizedBox(height: 16),
            Text(
              'No orders here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: orders.length,
      itemBuilder: (context, i) => _buildOrderCard(orders[i], isOngoing: isOngoing),
    );
  }

  Widget _buildOrderCard(Order order, {bool isOngoing = false}) {
    final statusText = order.status.name[0].toUpperCase() + order.status.name.substring(1);
    final statusColor = context.statusColor(order.status.name);
    final dateStr = order.createdAt != null ? DateFormat('MMM d, h:mm a').format(order.createdAt!) : '';
    final isCancelling = _cancellingId == order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: context.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.restaurantName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${order.total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.accepted) ...[
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: isCancelling ? null : () => _cancelOrder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red),
                            )
                          : const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (order.status == OrderStatus.delivered)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _reorder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reorder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
