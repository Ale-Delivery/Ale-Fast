import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'food_detail_screen.dart';

class RestaurantViewScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantViewScreen({super.key, required this.restaurant});

  @override
  State<RestaurantViewScreen> createState() => _RestaurantViewScreenState();
}

class _RestaurantViewScreenState extends State<RestaurantViewScreen> {
  List<FoodItem> _foods = [];
  bool _loading = true;
  String _activeTab = 'Burger';
  final List<String> _tabs = ['Burger', 'Sandwich', 'Pizza', 'Sanwi'];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    final foods = await DatabaseService.getFoodItems(
        restaurantId: widget.restaurant.id);
    if (mounted) setState(() { _foods = foods; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
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
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppColors.dark),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(
                url: r.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            title: const Text('Restaurant View',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),

          // ── Restaurant Info ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(r.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey, height: 1.6)),
                  const SizedBox(height: 10),
                  InfoRow(
                    rating: r.rating,
                    freeDelivery: r.freeDelivery,
                    deliveryMin: r.deliveryMin,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 14),

                  // Category tabs
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tabs.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() => _activeTab = _tabs[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == _tabs[i]
                                ? AppColors.orange
                                : AppColors.lightBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_tabs[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == _tabs[i]
                                    ? Colors.white
                                    : AppColors.dark,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Food Items ──────────────────────────────────────
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 4, height: 90)))
          else if (_foods.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No items found',
                    style: TextStyle(color: AppColors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final food = _foods[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FoodDetailScreen(food: food)),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                              url: food.imageUrl,
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(food.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  InfoRow(
                                    rating: food.rating,
                                    freeDelivery: food.freeDelivery,
                                    deliveryMin: food.deliveryMin,
                                    fontSize: 10,
                                  ),
                                  const SizedBox(height: 6),
                                  Text('\$${food.price.toInt()}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.orange)),
                                ],
                              ),
                            ),
                            AddButton(
                              onTap: () {
                                context.read<CartProvider>().addItem(food);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${food.name} added!'),
                                    backgroundColor: AppColors.orange,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _foods.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      // ── Floating Cart Button ───────────────────────────────
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.orange,
              onPressed: () {},
              label: Text('${cart.itemCount} items · \$${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white),
            )
          : null,
    );
  }
}
