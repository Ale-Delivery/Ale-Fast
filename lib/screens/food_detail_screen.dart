import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../navigation/buyer_navigator.dart';
import '../widgets/common_widgets.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem food;
  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  String _selectedSize = '';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedSize =
        widget.food.sizes.isNotEmpty ? widget.food.sizes[0] : '10"';
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Image ────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.orangeLight,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.dark),
                  ),
                ),
                actions: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => BuyerNavigator.cart(context),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: AppColors.dark, size: 20),
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text('$cartCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: AppNetworkImage(
                    url: food.imageUrl,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant tag
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(food.restaurantName,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.orange,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Name
                      Text(food.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),

                      // Description
                      Text(food.description,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                              height: 1.6)),
                      const SizedBox(height: 12),

                      // Rating row
                      InfoRow(
                        rating: food.rating,
                        freeDelivery: food.freeDelivery,
                        deliveryMin: food.deliveryMin,
                        fontSize: 12,
                      ),
                      const SizedBox(height: 24),

                      // Size selector
                      const Text('SIZE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey,
                              letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Row(
                        children: food.sizes
                            .map((s) => GestureDetector(
                                  onTap: () => setState(() => _selectedSize = s),
                                  child: AnimatedContainer(
                                    key: ValueKey(s),
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedSize == s
                                          ? AppColors.orange
                                          : AppColors.lightBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(s,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _selectedSize == s
                                              ? Colors.white
                                              : AppColors.dark,
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Ingredients
                      if (food.ingredients.isNotEmpty) ...[
                        const Text('INGREDIENTS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey,
                                letterSpacing: 1)),
                        const SizedBox(height: 10),
                        Row(
                          children: food.ingredients
                              .map((ing) => Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                        child: Text(ing,
                                            style: const TextStyle(
                                                fontSize: 22))),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Bar ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -5))
                  ],
              ),
              child: Row(
                children: [
                  // Price
                  Text('Rs. ${(food.price * _quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark)),
                  const Spacer(),

                  // Qty selector
                  Row(
                    children: [
                      _qtyBtn(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      const SizedBox(width: 12),
                      Text('$_quantity',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      _qtyBtn(Icons.add,
                          () => setState(() => _quantity++)),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Add to cart button
                  ElevatedButton(
                    onPressed: () {
                      for (int i = 0; i < _quantity; i++) {
                        context
                            .read<CartProvider>()
                            .addItem(food, size: _selectedSize);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to cart!'),
                          backgroundColor: AppColors.orange,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(
                            bottom: 96 + MediaQuery.of(context).padding.bottom,
                            left: 16,
                            right: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          action: SnackBarAction(
                            label: 'View Cart',
                            textColor: Colors.white,
                            onPressed: () => BuyerNavigator.cart(context),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.lightBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.dark),
      ),
    );
  }
}
