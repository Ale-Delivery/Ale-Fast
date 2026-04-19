import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'search_screen.dart';
import 'food_detail_screen.dart';
import 'restaurant_view_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FoodCategory> _categories = const [
    FoodCategory(id: 'all', name: 'All', emoji: '🔥', isSelected: true),
    FoodCategory(id: 'hotdog', name: 'Hot Dog', emoji: '🌭'),
    FoodCategory(id: 'burger', name: 'Burger', emoji: '🍔'),
    FoodCategory(id: 'pizza', name: 'Pizza', emoji: '🍕'),
    FoodCategory(id: 'coffee', name: 'Coffee', emoji: '☕'),
  ];

  String _selectedCategory = 'All';
  List<Restaurant> _restaurants = [];
  List<FoodItem> _foodItems = [];
  bool _loading = true;
  bool _offerShown = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    Future.delayed(const Duration(seconds: 2), _showOfferPopup);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final restaurants = await DatabaseService.getRestaurants();
    final foods = await DatabaseService.getFoodItems();
    if (mounted) {
      setState(() {
        _restaurants = restaurants;
        _foodItems = foods;
        _loading = false;
      });
    }
  }

  Future<void> _loadByCategory(String category) async {
    setState(() => _loading = true);
    final restaurants = await DatabaseService.getRestaurants(
        category: category == 'All' ? null : category);
    final foods = await DatabaseService.getFoodItems(
        category: category == 'All' ? null : category);
    if (mounted) {
      setState(() {
        _restaurants = restaurants;
        _foodItems = foods;
        _loading = false;
      });
    }
  }

  void _selectCategory(int idx) {
    final selected = _categories[idx];
    setState(() {
      _categories = _categories
          .asMap()
          .entries
          .map((e) => e.value.copyWith(isSelected: e.key == idx))
          .toList();
      _selectedCategory = selected.name;
    });
    _loadByCategory(selected.name);
  }

  void _showOfferPopup() async {
    if (_offerShown || !mounted) return;
    _offerShown = true;
    final offers = await DatabaseService.getActiveOffers();
    if (offers.isEmpty || !mounted) return;
    final offer = offers.first;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _OfferDialog(offer: offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.menu, color: AppColors.dark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DELIVER TO',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('Halal Lab office',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CartScreen())),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${cart.itemCount}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ──────────────────────────────
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: AppColors.dark),
                        children: [
                          TextSpan(text: 'Hey Halal, '),
                          TextSpan(
                            text: 'Good Afternoon!',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Search Bar ────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SearchScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.grey, size: 20),
                            SizedBox(width: 10),
                            Text('Search dishes, restaurants',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Categories ────────────────────────────
                    SectionHeader(title: 'All Categories', onSeeAll: () {}),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (_, i) => CategoryChip(
                          category: _categories[i],
                          onTap: () => _selectCategory(i),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Food Horizontal Scroll ─────────────────
                    if (_foodItems.isNotEmpty) ...[
                      SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _foodItems.length,
                          itemBuilder: (_, i) => FoodCard(
                            food: _foodItems[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      FoodDetailScreen(food: _foodItems[i])),
                            ),
                            onAdd: () {
                              context.read<CartProvider>().addItem(_foodItems[i]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${_foodItems[i].name} added!'),
                                  backgroundColor: AppColors.orange,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Open Restaurants ──────────────────────
                    SectionHeader(
                        title: 'Open Restaurants', onSeeAll: () {}),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Restaurant List ───────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ShimmerList()))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RestaurantCard(
                      restaurant: _restaurants[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RestaurantViewScreen(
                                restaurant: _restaurants[i])),
                      ),
                    ),
                  ),
                  childCount: _restaurants.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

// ─── Offer Popup Dialog ────────────────────────────────────────
class _OfferDialog extends StatelessWidget {
  final Offer offer;
  const _OfferDialog({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Hurry Offers! 🎉',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(offer.code,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2)),
                ),
                const SizedBox(height: 12),
                Text(offer.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('GOT IT',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
