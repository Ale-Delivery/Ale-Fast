import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../navigation/buyer_navigator.dart';
import '../widgets/orders/order_status_badge.dart';

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
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final orders = await OrderService.getUserOrders(limit: 100);
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel order?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Order',
                style: TextStyle(
                    color: context.textMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancellingId = order.id);
    try {
      await OrderService.cancelOrder(order.id);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully.'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  List<Order> _getOngoing() => _orders
      .where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.accepted ||
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.ready ||
          o.status == OrderStatus.onTheWay)
      .toList();

  List<Order> _getCompleted() =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<Order> _getCancelled() =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft,
                    size: 20, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'Your Activities',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.listFilter,
                  size: 18, color: context.textPrimary),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.muted,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2.5))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTab(
                  title: 'Ongoing Orders',
                  orders: _getOngoing(),
                  emptyIcon: LucideIcons.clock,
                  emptyTitle: 'No ongoing orders',
                  emptySubtitle: 'Your active orders will appear here.',
                ),
                _buildTab(
                  title: 'Completed Orders',
                  orders: _getCompleted(),
                  emptyIcon: LucideIcons.checkCircle,
                  emptyTitle: 'No completed orders',
                  emptySubtitle: 'Completed deliveries will appear here.',
                ),
                _buildTab(
                  title: 'Cancelled Orders',
                  orders: _getCancelled(),
                  emptyIcon: LucideIcons.xCircle,
                  emptyTitle: 'No cancelled orders',
                  emptySubtitle:
                      'Cancelled or rejected orders will appear here.',
                ),
              ],
            ),
    );
  }

  Widget _buildTab({
    required String title,
    required List<Order> orders,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (orders.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyTitle, emptySubtitle);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: orders.length,
        itemBuilder: (context, i) => _buildOrderCard(orders[i]),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon,
                  size: 32, color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateStr = order.createdAt != null
        ? DateFormat('MMM d, h:mm a').format(order.createdAt!)
        : '';
    final isCancelling = _cancellingId == order.id;
    final canCancel = order.status == OrderStatus.pending ||
        order.status == OrderStatus.accepted;

    return GestureDetector(
      onTap: () => _openOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Row(
              children: [
                _buildItemImage(order),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrderStatusBadge(status: order.status),
                      const SizedBox(height: 8),
                      Text(
                        order.restaurantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${_formatPrice(order.total)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock,
                              size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight,
                    size: 20, color: AppColors.muted),
              ],
            ),
            if (canCancel) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
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
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.red),
                        )
                      : const Text('Cancel',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(Order order) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        LucideIcons.store,
        size: 32,
        color: AppColors.orange,
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(0);
  }

  void _openOrderDetails(Order order) {
    BuyerNavigator.orderTracking(context, order.id);
  }
}
