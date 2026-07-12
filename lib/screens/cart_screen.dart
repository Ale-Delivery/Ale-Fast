import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../widgets/common_widgets.dart';
import '../navigation/buyer_navigator.dart';

class CartScreen extends StatelessWidget {
  final bool isEmbedded;
  const CartScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: isEmbedded
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: cart.clearCart,
              child: const Text('Clear', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shoppingBag, size: 56, color: context.textHint),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some delicious food!',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.cardBorder, width: 0.5),
                          boxShadow: context.cardShadow,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AppNetworkImage(
                                url: item.food.imageUrl,
                                width: 60,
                                height: 60,
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.food.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.selectedSize,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rs. ${item.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _qtyControl(context, cart, i),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomBar(context, cart),
              ],
            ),
    );
  }

  Widget _qtyControl(BuildContext context, CartProvider cart, int index) {
    final item = cart.items[index];
    return Container(
      decoration: BoxDecoration(
        color: context.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(
            context,
            icon: LucideIcons.minus,
            onTap: () {
              if (item.quantity > 1) {
                cart.updateQuantity(index, item.quantity - 1);
              } else {
                cart.removeItemAt(index);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
          ),
          _qtyBtn(
            context,
            icon: LucideIcons.plus,
            onTap: () => cart.updateQuantity(index, item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: context.textPrimary),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: context.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.textMuted,
                ),
              ),
              Text(
                'Rs. ${cart.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: GestureDetector(
              onTap: () {
                BuyerNavigator.deliveryAddress(context, proceedToCheckout: true);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppGradients.glow,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
