import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
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
  final List<String> _tabs = ['Burger', 'Sandwich', 'Pizza', 'Sandwich'];
  Set<String> _favoriteFoodIds = {};

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadFoodFavorites();
  }

  Future<void> _loadFoods() async {
    setState(() => _loading = true);
    final foods = await DatabaseService.getFoodItems(
        restaurantId: widget.restaurant.id);
    if (mounted) setState(() { _foods = foods; _loading = false; });
  }

  Future<void> _loadFoodFavorites() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('FoodFavorites')
          .select('food_id')
          .eq('user_id', userId);
      if (mounted) {
        setState(() {
          _favoriteFoodIds = Set<String>.from(
            data.map((r) => r['food_id'].toString()),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFoodFavorite(String foodId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final isFav = _favoriteFoodIds.contains(foodId);
    try {
      if (isFav) {
        await Supabase.instance.client
            .from('FoodFavorites')
            .delete()
            .eq('user_id', userId)
            .eq('food_id', foodId);
        setState(() => _favoriteFoodIds.remove(foodId));
      } else {
        await Supabase.instance.client.from('FoodFavorites').insert({
          'user_id': userId,
          'food_id': foodId,
        });
        setState(() => _favoriteFoodIds.add(foodId));
      }
    } catch (e) {
      debugPrint('Error toggling food favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);
    final cartTotal = context.select<CartProvider, double>((c) => c.total);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: context.surfaceColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: context.textPrimary),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_horiz, color: context.textPrimary),
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
              color: context.surfaceColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(r.description,
                      style: TextStyle(
                          fontSize: 12, color: context.textMuted, height: 1.6)),
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
                          key: ValueKey(_tabs[i]),
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == _tabs[i]
                                ? AppColors.orange
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_tabs[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _activeTab == _tabs[i]
                                    ? Colors.white
                                    : context.textPrimary,
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
            SliverFillRemaining(
              child: Center(
                child: Text('No items found',
                    style: TextStyle(color: context.textMuted)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final food = _foods[i];
                    final foodId = food.id.toString();
                    final isFoodFav = _favoriteFoodIds.contains(foodId);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FoodDetailScreen(food: food)),
                      ),
                      child: RepaintBoundary(
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
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
                                  Text('Rs. ${food.price.toInt()}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.orange)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleFoodFavorite(foodId),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isFoodFav
                                      ? AppColors.red.withValues(alpha: 0.08)
                                      : context.chipBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  LucideIcons.heart,
                                  size: 18,
                                  color: isFoodFav ? AppColors.red : context.textMuted,
                                  fill: isFoodFav ? 1.0 : 0.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.orange,
              onPressed: () {},
              label: Text('$cartCount items · Rs. ${cartTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white),
            )
          : null,
    );
  }
}
