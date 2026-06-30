import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../widgets/common_widgets.dart';
import '../navigation/buyer_navigator.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        leading: const BackButton(),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: cart.clearCart,
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.orange)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Add some delicious food!',
                      style: TextStyle(color: context.textMuted)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            AppNetworkImage(
                              url: item.food.imageUrl,
                              width: 65,
                              height: 65,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.food.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  Text(item.selectedSize,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: context.textMuted)),
                                  const SizedBox(height: 4),
                                  Text('Rs. ${item.total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.orange)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _qtyBtn(context,
                                  Icons.remove,
                                  () => context.read<CartProvider>().removeItem(
                                      item.food.id, item.selectedSize),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text('${item.quantity}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                ),
                                _qtyBtn(context,
                                  Icons.add,
                                  () => context
                                      .read<CartProvider>()
                                      .addItem(item.food,
                                          size: item.selectedSize),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ── Order Summary ──────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 36 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    children: [
                      _summaryRow(context, 'Subtotal',
                          'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _summaryRow(context,
                          'Delivery',
                          cart.deliveryFee == 0
                              ? 'Free'
                              : 'Rs. ${cart.deliveryFee.toStringAsFixed(0)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      _summaryRow(context,
                        'Total',
                        'Rs. ${cart.total.toStringAsFixed(0)}',
                        bold: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            BuyerNavigator.deliveryAddress(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Proceed to Checkout',
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

  Widget _summaryRow(BuildContext context, String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? context.textPrimary : context.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 18 : 13,
                fontWeight: FontWeight.w800,
                color: bold ? AppColors.orange : context.textPrimary)),
      ],
    );
  }

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}
