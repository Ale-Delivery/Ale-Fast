import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class GroceryCartScreen extends StatefulWidget {
  const GroceryCartScreen({super.key});

  @override
  State<GroceryCartScreen> createState() => _GroceryCartScreenState();
}

class _GroceryCartScreenState extends State<GroceryCartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _loading = true;
  bool _isScheduled = false;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduleTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('Grocery_Cart')
          .select('id, quantity, product_id, Grocery_Products(id, name, price, unit, image_url, stock)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateQuantity(String cartId, int newQty) async {
    if (newQty < 1) {
      await _removeItem(cartId);
      return;
    }
    try {
      await Supabase.instance.client
          .from('Grocery_Cart')
          .update({'quantity': newQty})
          .eq('id', cartId);
      _loadCart();
    } catch (_) {}
  }

  Future<void> _removeItem(String cartId) async {
    try {
      await Supabase.instance.client.from('Grocery_Cart').delete().eq('id', cartId);
      _loadCart();
    } catch (_) {}
  }

  Future<void> _clearCart() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('Grocery_Cart').delete().eq('user_id', userId);
      _loadCart();
    } catch (_) {}
  }

  double get _subtotal {
    double total = 0;
    for (final item in _cartItems) {
      final product = item['Grocery_Products'];
      if (product == null) continue;
      final price = (product['price'] as num?)?.toDouble() ?? 0.0;
      final qty = item['quantity'] as int? ?? 1;
      total += price * qty;
    }
    return total;
  }

  double get _deliveryFee => _subtotal > 500 ? 0 : 150;
  double get _total => _subtotal + _deliveryFee;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _scheduleTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _cartItems.isEmpty
                      ? _buildEmptyState()
                      : _buildCartContent(),
            ),
            if (_cartItems.isNotEmpty) _buildCheckoutBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.cardBorder, width: 0.5),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 18, color: context.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'My Cart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimary),
            ),
          ),
          if (_cartItems.isNotEmpty)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Remove all items from cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
                      TextButton(
                        onPressed: () { _clearCart(); Navigator.pop(ctx); },
                        child: const Text('Clear', style: TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Clear', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(LucideIcons.shoppingCart, size: 36, color: AppColors.green.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text('Add some fresh items to get started', style: TextStyle(fontSize: 14, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        ..._cartItems.map((item) => _buildCartItem(item)),
        const SizedBox(height: 16),
        _buildScheduleToggle(),
        const SizedBox(height: 16),
        _buildSummaryRow('Subtotal', 'Rs.${_subtotal.toStringAsFixed(0)}'),
        _buildSummaryRow('Delivery', _deliveryFee == 0 ? 'FREE' : 'Rs.${_deliveryFee.toStringAsFixed(0)}', isFree: _deliveryFee == 0),
        if (_deliveryFee > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Free delivery on orders above Rs.500',
              style: TextStyle(fontSize: 11, color: context.textMuted),
            ),
          ),
        const Divider(height: 28),
        _buildSummaryRow('Total', 'Rs.${_total.toStringAsFixed(0)}', isBold: true),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['Grocery_Products'];
    if (product == null) return const SizedBox.shrink();
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final qty = item['quantity'] as int? ?? 1;
    final imageUrl = product['image_url']?.toString();
    final name = product['name']?.toString() ?? '';
    final unit = product['unit']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.green.withValues(alpha: 0.05),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                : Icon(LucideIcons.package, size: 24, color: AppColors.green.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                const SizedBox(height: 4),
                Text('Rs.${price.toStringAsFixed(0)} · $unit',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.cardBorder, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _updateQuantity(item['id'], qty - 1),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.minus, size: 14, color: AppColors.green),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('$qty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                ),
                GestureDetector(
                  onTap: () => _updateQuantity(item['id'], qty + 1),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.plus, size: 14, color: AppColors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendarClock, size: 20, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    Text('Choose a time slot', style: TextStyle(fontSize: 12, color: context.textMuted)),
                  ],
                ),
              ),
              Switch(
                value: _isScheduled,
                onChanged: (v) => setState(() => _isScheduled = v),
                activeColor: AppColors.green,
              ),
            ],
          ),
          if (_isScheduled) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 16, color: AppColors.green),
                          const SizedBox(width: 8),
                          Text(
                            '${_scheduleDate.day}/${_scheduleDate.month}/${_scheduleDate.year}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.clock, size: 16, color: AppColors.green),
                          const SizedBox(width: 8),
                          Text(
                            _scheduleTime.format(context),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: context.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isFree ? AppColors.green : (isBold ? context.textPrimary : context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.cardBorder, width: 0.5)),
      ),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proceeding to checkout...'),
              backgroundColor: AppColors.green,
            ),
          );
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.green, AppColors.green.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              'Checkout · Rs.${_total.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
