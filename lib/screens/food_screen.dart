import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/buyer_navigator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../widgets/modern/glass_card.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  static const _primary = AppColors.orange;

  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _restaurantsFuture;
  late Future<List<Map<String, dynamic>>> _offersFuture;

  String selectedCategory = 'All';
  String _query = '';
  late final PageController _offerPageController;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Burger', 'icon': Icons.lunch_dining_rounded},
    {'name': 'Pizza', 'icon': Icons.local_pizza_rounded},
    {'name': 'Sandwich', 'icon': Icons.breakfast_dining_rounded},
    {'name': 'Coffee', 'icon': Icons.local_cafe_rounded},
  ];

  final List<Map<String, String>> _bannerOffers = const [
    {
      'title': 'Fast lunch picks',
      'subtitle': 'Fresh meals near you in 25 min',
      'image':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=900',
    },
    {
      'title': 'Weekend cravings',
      'subtitle': 'Pizza, burgers, and family combos',
      'image':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=900',
    },
  ];

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = _fetchRestaurants();
    _offersFuture = _fetchOffers();
    _offerPageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _offerPageController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchRestaurants() async {
    try {
      final data = await Supabase.instance.client
          .from('Restaurants')
          .select()
          .eq('is_open', true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e, stack) {
      debugPrint('Error fetching restaurants: $e\n$stack');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOffers() async {
    try {
      final data = await Supabase.instance.client
          .from('Offers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  void _refreshRestaurants() {
    setState(() {
      _restaurantsFuture = _fetchRestaurants();
    });
  }

  List<Map<String, dynamic>> _filterRestaurants(
    List<Map<String, dynamic>> restaurants,
  ) {
    final query = _query.trim().toLowerCase();
    return restaurants.where((restaurant) {
      final name = (restaurant['name'] ?? '').toString().toLowerCase();
      final tags = (restaurant['tags'] ?? '').toString().toLowerCase();
      final category = (restaurant['category'] ?? '').toString().toLowerCase();
      final searchable = '$name $tags $category';
      final matchesQuery = query.isEmpty || searchable.contains(query);
      final matchesCategory = selectedCategory == 'All' ||
          searchable.contains(selectedCategory.toLowerCase());
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _openRestaurant(Map<String, dynamic> restaurant) {
    BuyerNavigator.restaurantDetails(context, restaurant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 60,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Food',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              centerTitle: true,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchBar(),
                _buildOfferCarousel(),
                _buildPromotionsSection(),
                _buildSectionTitle('Categories'),
                _buildCategoryList(),
                _buildSectionTitle('Open Restaurants'),
              ]),
            ),
            _buildRestaurantSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 104)),
          ],
        ),
      ),
    );
  }

  // ── Search ──────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.cardBorder.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search dishes, restaurants',
            hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
            prefixIcon:
                Icon(Icons.search_rounded, color: context.textMuted),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 17),
          ),
        ),
      ),
    );
  }

  // ── Offer carousel ──────────────────────────────────────────────

  Widget _buildOfferCarousel() {
    return RepaintBoundary(
      child: SizedBox(
        height: 170,
        child: PageView.builder(
          controller: _offerPageController,
          itemCount: _bannerOffers.length,
          itemBuilder: (context, index) {
            final offer = _bannerOffers[index];
            return Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 20 : 8,
                right: index == _bannerOffers.length - 1 ? 20 : 8,
                top: 10,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: offer['image']!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 130,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer['subtitle']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Order now',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Promotions from Supabase ────────────────────────────────────

  Widget _buildPromotionsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _offersFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final offers = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: _primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Promotions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return Container(
                      width: 220,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primary,
                            _primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${offer['discount_percent']}% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.local_offer_rounded,
                                  color:
                                      Colors.white.withValues(alpha: 0.5),
                                  size: 18),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            offer['code'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer['description'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Section title ───────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _query = '';
                selectedCategory = 'All';
              });
            },
            child: const Text(
              'Reset',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Categories ──────────────────────────────────────────────────

  Widget _buildCategoryList() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedCategory == category['name'];
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            avatar: Icon(
              category['icon'] as IconData,
              color: isSelected ? Colors.white : _primary,
              size: 19,
            ),
            label: Text(category['name'] as String),
            selectedColor: _primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: isSelected
                  ? _primary
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            onSelected: (_) {
              setState(() =>
                  selectedCategory = category['name'] as String);
            },
          );
        },
      ),
    );
  }

  // ── Restaurant list ─────────────────────────────────────────────

  Widget _buildRestaurantSliver() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _restaurantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList.builder(
            itemCount: 3,
            itemBuilder: (_, __) => const _RestaurantSkeleton(),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _StatePanel(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load restaurants',
              subtitle: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _refreshRestaurants,
            ),
          );
        }

        final restaurants = _filterRestaurants(snapshot.data ?? []);

        if (restaurants.isEmpty) {
          return SliverToBoxAdapter(
            child: _StatePanel(
              icon: Icons.search_off_rounded,
              title: 'No matches found',
              subtitle: 'Try another food, restaurant, or category.',
              actionLabel: 'Clear filters',
              onAction: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  selectedCategory = 'All';
                });
              },
            ),
          );
        }

        return SliverList.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return _RestaurantCard(
              restaurant: restaurant,
              onTap: () => _openRestaurant(restaurant),
            );
          },
        );
      },
    );
  }
}

// ─── Private widgets ─────────────────────────────────────────────

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = restaurant['rating']?.toString() ?? 'N/A';
    final deliveryFee = (restaurant['delivery_fee'] ?? 'Free').toString();
    final deliveryTime =
        (restaurant['delivery_time'] ?? restaurant['delivery_min'] ?? '25 min')
            .toString();

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: CachedNetworkImage(
                      imageUrl: (restaurant['image_url'] ?? '').toString(),
                      height: 154,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 154,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 154,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _Pill(
                      icon: Icons.access_time_rounded,
                      label: deliveryTime,
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.8),
                      foreground:
                          Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['name'] ?? 'Unknown Restaurant',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (restaurant['tags'] ?? 'Fresh food nearby')
                          .toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          icon: Icons.star_rounded,
                          label: rating,
                          color: AppColors.orange
                              .withValues(alpha: 0.1),
                          foreground: AppColors.orange,
                        ),
                        _Pill(
                          icon: Icons.delivery_dining_rounded,
                          label: deliveryFee,
                          color:
                              AppColors.blue.withValues(alpha: 0.1),
                          foreground: AppColors.blue,
                        ),
                        _Pill(
                          icon: Icons.verified_rounded,
                          label: 'Open now',
                          color: AppColors.green
                              .withValues(alpha: 0.1),
                          foreground: AppColors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fade(duration: 400.ms)
            .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: context.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.orange, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _RestaurantSkeleton extends StatelessWidget {
  const _RestaurantSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: context.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            height: 154,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEFF3),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEFF3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  margin: const EdgeInsets.only(right: 90),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEFF3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
