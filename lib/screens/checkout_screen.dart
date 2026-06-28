import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../navigation/buyer_navigator.dart';

class CheckoutScreen extends StatefulWidget {
  final String deliveryAddress;
  final String deliveryPhone;
  final String? deliveryNotes;
  final String addressLabel;

  const CheckoutScreen({
    super.key,
    required this.deliveryAddress,
    required this.deliveryPhone,
    this.deliveryNotes,
    this.addressLabel = 'Home',
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cash';
  bool _placing = false;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() => _placing = true);
    try {
      final order = await OrderService.placeOrder(
        cart: cart,
        deliveryAddress:
            '${widget.addressLabel}: ${widget.deliveryAddress}',
        deliveryPhone: widget.deliveryPhone,
        deliveryNotes: widget.deliveryNotes,
        paymentMethod: _paymentMethod,
      );

      cart.clearCart();

      if (!mounted) return;
      BuyerNavigator.orderPlaced(context, order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not place order. Please check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Deliver to',
                  subtitle: widget.deliveryAddress,
                  trailing: widget.addressLabel,
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  icon: Icons.phone_outlined,
                  title: 'Contact',
                  subtitle: widget.deliveryPhone,
                ),
                if (widget.deliveryNotes != null) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    icon: Icons.note_outlined,
                    title: 'Notes',
                    subtitle: widget.deliveryNotes!,
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Payment method',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                _paymentTile('cash', 'Cash on delivery', Icons.payments_outlined),
                _paymentTile('card', 'Card (coming soon)', Icons.credit_card_outlined,
                    enabled: false),
                const SizedBox(height: 20),
                const Text('Order summary',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.food.name} (${item.selectedSize})',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text('Rs. ${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).padding.bottom),
            color: Colors.white,
            child: Column(
              children: [
                _row('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _row(
                  'Delivery',
                  cart.deliveryFee == 0
                      ? 'Free'
                      : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}',
                ),
                const Divider(height: 24),
                _row('Total', 'Rs. ${cart.total.toStringAsFixed(0)}', bold: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _placing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _placing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Place Order',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(trailing,
                  style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _paymentTile(String value, String label, IconData icon,
      {bool enabled = true}) {
    final selected = _paymentMethod == value;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: ListTile(
        onTap: enabled ? () => setState(() => _paymentMethod = value) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? AppColors.orangeLight : Colors.white,
        leading: Icon(icon, color: selected ? AppColors.orange : AppColors.grey),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.orange)
            : const Icon(Icons.circle_outlined, color: AppColors.grey),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 16 : 13)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: bold ? 18 : 13,
                color: bold ? AppColors.orange : AppColors.dark)),
      ],
    );
  }
}
