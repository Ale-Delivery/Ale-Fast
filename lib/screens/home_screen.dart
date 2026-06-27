import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/buyer_navigator.dart';
import '../providers/cart_provider.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _primary = Color(0xFFFF6B35);
  static const _ink = Color(0xFF1E1E2C);
  static const _muted = Color(0xFF7D8491);
  static const _surface = Color(0xFFF7F8FA);

  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _restaurantsFuture;

  String selectedCategory = 'All';
  String _query = '';
  int _selectedTab = 0;
  String _deliveryLabel = 'Set delivery address';
  String _userName = 'User';

  final List<Map<String, dynamic>> categories = const [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Burger', 'icon': Icons.lunch_dining_rounded},
    {'name': 'Pizza', 'icon': Icons.local_pizza_rounded},
    {'name': 'Sandwich', 'icon': Icons.breakfast_dining_rounded},
    {'name': 'Coffee', 'icon': Icons.local_cafe_rounded},
  ];

  final List<Map<String, String>> offers = const [
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
    _loadDeliveryLabel();
  }

  Future<void> _loadDeliveryLabel() async {
    final saved = await LocalStorageService.getDeliveryAddress();
    final name = await LocalStorageService.getUserName();
    if (!mounted) return;
    setState(() {
      if (name != null && name.trim().isNotEmpty) {
        _userName = name.trim().split(' ').first;
      }
      _deliveryLabel = saved != null
          ? '${saved['label']}: ${saved['address']}'
          : 'Set delivery address';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchRestaurants() async {
    try {
      final response =
          await Supabase.instance.client.from('Restaurants').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      debugPrint('Error fetching restaurants: $e\n$stack');
      rethrow;
    }
  }

  void _refreshRestaurants() {
    final future = _fetchRestaurants();
    setState(() {
      _restaurantsFuture = future;
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

  void _handleTabTap(int index) {
    setState(() => _selectedTab = index);
    switch (index) {
      case 1:
        BuyerNavigator.search(context).then((_) => _loadDeliveryLabel());
        break;
      case 2:
        BuyerNavigator.cart(context).then((_) => _loadDeliveryLabel());
        break;
      case 3:
        BuyerNavigator.orderHistory(context).then((_) => _loadDeliveryLabel());
        break;
      case 4:
        BuyerNavigator.profile(context).then((_) => _loadDeliveryLabel());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: _surface,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildHeroSearch()),
              SliverToBoxAdapter(child: _buildOfferCarousel()),
              SliverToBoxAdapter(child: _buildSectionTitle('Categories')),
              SliverToBoxAdapter(child: _buildCategoryList()),
              SliverToBoxAdapter(child: _buildSectionTitle('Open Restaurants')),
              _buildRestaurantSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 104)),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHeader() {
    final cartCount = context.watch<CartProvider>().itemCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          _roundButton(Icons.receipt_long_rounded,
              onTap: () => BuyerNavigator.orderHistory(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DELIVER TO',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await BuyerNavigator.deliveryAddress(
                      context,
                      proceedToCheckout: false,
                    );
                    _loadDeliveryLabel();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _deliveryLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: _ink),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => BuyerNavigator.cart(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: _ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Colors.white, size: 21),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: -3,
                    top: -4,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 19, minHeight: 19),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hey $_userName,',
            style: const TextStyle(fontSize: 16, color: _muted),
          ),
          const SizedBox(height: 3),
          const Text(
            'What would you like to eat?',
            style: TextStyle(
              fontSize: 25,
              height: 1.14,
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDEFF3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                    decoration: InputDecoration(
                      hintText: 'Search dishes, restaurants',
                      hintStyle: const TextStyle(color: _muted, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: _muted),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _roundButton(
                Icons.tune_rounded,
                color: _primary,
                iconColor: Colors.white,
                onTap: () => BuyerNavigator.search(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCarousel() {
    return SizedBox(
      height: 170,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];

          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 20 : 8,
              right: index == offers.length - 1 ? 20 : 8,
              top: 10,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
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
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.12),
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
                          color: Colors.white.withOpacity(0.86),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Order now',
                      style: TextStyle(
                        color: _ink,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
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

  Widget _buildCategoryList() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
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
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? _primary : const Color(0xFFEDEFF3),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : _ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            onSelected: (_) {
              setState(() => selectedCategory = category['name'] as String);
            },
          );
        },
      ),
    );
  }

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

  Widget _roundButton(
    IconData icon, {
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = _ink,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: iconColor, size: 21),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.orangeLight,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected) ? _primary : _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: NavigationBar(
          height: 62,
          elevation: 0,
          selectedIndex: _selectedTab,
          backgroundColor: Colors.transparent,
          onDestinationSelected: _handleTabTap,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: _primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search, color: _primary),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded, color: _primary),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: _primary),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: _primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEDEFF3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: (restaurant['image_url'] ?? '').toString(),
                      height: 154,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 154,
                        color: const Color(0xFFEDEFF3),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 154,
                        color: const Color(0xFFEDEFF3),
                        child: const Icon(Icons.restaurant_rounded,
                            size: 44, color: Color(0xFF9AA0AA)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _Pill(
                        icon: Icons.access_time_rounded,
                        label: deliveryTime,
                        color: Colors.white,
                        foreground: const Color(0xFF1E1E2C),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            color: Color(0xFFFF6B35), size: 20),
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
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E1E2C),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF7D8491)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        (restaurant['tags'] ?? 'Fresh food nearby').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7D8491),
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
                            color: const Color(0xFFFFF8E1),
                            foreground: const Color(0xFFB77900),
                          ),
                          _Pill(
                            icon: Icons.delivery_dining_rounded,
                            label: deliveryFee,
                            color: const Color(0xFFFFF3EE),
                            foreground: const Color(0xFFFF6B35),
                          ),
                          const _Pill(
                            icon: Icons.verified_rounded,
                            label: 'Open now',
                            color: Color(0xFFEAF8EF),
                            foreground: Color(0xFF299653),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1E1E2C),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7D8491), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        children: [
          Container(
            height: 154,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEFF3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
