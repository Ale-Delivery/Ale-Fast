import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/buyer_navigator.dart';
import '../providers/cart_provider.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'food_screen.dart';
import 'rides_screen.dart';
import 'parcel_screen.dart';
import 'grocery_screen.dart';
import 'order_history_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../models/models.dart';
import 'restaurant_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _serviceView = -1;
  String _deliveryLabel = 'Set delivery address';
  String _userName = 'User';
  StreamSubscription? _orderSub;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loadingRestaurants = true;
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryLabel();
    _subscribeToOrders();
    _loadCategories();
    _loadRestaurants();
    _loadRecentOrders();
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  void _subscribeToOrders() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    _orderSub?.cancel();
    _orderSub = Supabase.instance.client
        .from('Orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(5)
        .listen((rows) {
      if (!mounted || rows.isEmpty) return;
      final latest = rows.first;
      final status = latest['status']?.toString() ?? '';
      if (status == 'delivered' || status == 'cancelled' || status == 'pending') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'preparing' || status == 'ready'
                    ? Icons.check_circle
                    : Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Order ${latest['restaurant_name'] ?? ''}: ${status[0].toUpperCase()}${status.substring(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: status == 'ready'
              ? AppColors.green
              : status == 'preparing'
                  ? AppColors.accent
                  : AppColors.purple,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    });
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

  Future<void> _loadCategories() async {
    try {
      final data = await Supabase.instance.client
          .from('Food_Categories')
          .select('id, name, icon, color')
          .order('sort_order');
      if (mounted) setState(() => _categories = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  Future<void> _loadRestaurants() async {
    try {
      final data = await Supabase.instance.client
          .from('Restaurants')
          .select('id, name, image_url, rating, delivery_time, cuisine, is_featured')
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _restaurants = List<Map<String, dynamic>>.from(data);
          _loadingRestaurants = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRestaurants = false);
    }
  }

  Future<void> _loadRecentOrders() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loadingRecent = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('Orders')
          .select('id, restaurant_name, items, total, status, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() {
          _recentOrders = List<Map<String, dynamic>>.from(data);
          _loadingRecent = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  void _handleTabTap(int index) {
    setState(() {
      _selectedTab = index;
      _serviceView = -1;
    });
  }

  void _openService(int serviceIndex) {
    setState(() {
      _serviceView = serviceIndex;
      _selectedTab = 0;
    });
  }

  Widget _buildBody() {
    if (_serviceView >= 0) {
      switch (_serviceView) {
        case 0: return FoodScreen(isEmbedded: true, onBack: () => setState(() => _serviceView = -1));
        case 1: return RidesScreen(isEmbedded: true, onBack: () => setState(() => _serviceView = -1));
        case 2: return ParcelScreen(isEmbedded: true, onBack: () => setState(() => _serviceView = -1));
        case 3: return GroceryScreen(isEmbedded: true, onBack: () => setState(() => _serviceView = -1));
      }
    }

    switch (_selectedTab) {
      case 0: return _buildHomeContent();
      case 1: return const OrderHistoryScreen(isEmbedded: true);
      case 2: return const CartScreen(isEmbedded: true);
      case 3: return const ProfileScreen(isEmbedded: true);
      default: return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            _buildHeader(),
            _buildGreeting(),
            _buildSearchBar(),
            _buildServiceGrid(),
            const SizedBox(height: 28),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _buildCategoriesSection(),
            const SizedBox(height: 28),
            _buildOffersSection(),
            const SizedBox(height: 28),
            _buildNearbySection(),
            const SizedBox(height: 28),
            _buildRecentOrdersSection(),
          ]),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader() {
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await BuyerNavigator.deliveryAddress(context, proceedToCheckout: false);
                _loadDeliveryLabel();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'DELIVER TO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _deliveryLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _iconButton(
            icon: LucideIcons.bell,
            onTap: () => BuyerNavigator.notifications(context),
          ),
          const SizedBox(width: 12),
          _iconButton(
            icon: LucideIcons.shoppingBag,
            onTap: () => _handleTabTap(2),
            badge: cartCount,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, VoidCallback? onTap, int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: context.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: context.textPrimary, size: 20),
            if (badge > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $_userName',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => AppGradients.hero.createShader(bounds),
            child: const Text(
              'What do you need?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder, width: 0.5),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search, size: 20, color: context.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search food, restaurants, items...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.textMuted,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.slidersHorizontal, size: 16, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    final services = [
      {
        'key': 'Rides',
        'icon': LucideIcons.bike,
        'label': 'Rides',
        'desc': 'Book a ride',
        'idx': 1,
        'color': const Color(0xFF3B82F6),
      },
      {
        'key': 'Food',
        'icon': LucideIcons.utensils,
        'label': 'Food',
        'desc': 'Order food',
        'idx': 0,
        'color': const Color(0xFFF59E0B),
      },
      {
        'key': 'Parcel',
        'icon': LucideIcons.package,
        'label': 'Parcel',
        'desc': 'Send parcels',
        'idx': 2,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'key': 'Grocery',
        'icon': LucideIcons.shoppingCart,
        'label': 'Grocery',
        'desc': 'Fresh items',
        'idx': 3,
        'color': const Color(0xFF22C55E),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
        ),
        itemCount: services.length,
        itemBuilder: (context, i) {
          final s = services[i];
          final svcColor = s['color'] as Color;
          return GestureDetector(
            onTap: () => _openService(s['idx'] as int),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.cardBorder, width: 0.5),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: svcColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      size: 22,
                      color: svcColor,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['label'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': LucideIcons.clock, 'label': 'Orders', 'onTap': () => _handleTabTap(1), 'color': const Color(0xFF3B82F6)},
      {'icon': LucideIcons.heart, 'label': 'Favorites', 'onTap': () => BuyerNavigator.favorites(context), 'color': const Color(0xFFEF4444)},
      {'icon': LucideIcons.percent, 'label': 'Offers', 'onTap': () => _openService(0), 'color': const Color(0xFFF59E0B)},
      {'icon': LucideIcons.headphones, 'label': 'Support', 'onTap': () => BuyerNavigator.helpSupport(context), 'color': const Color(0xFF8B5CF6)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          final itemColor = a['color'] as Color;
          return GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    a['icon'] as IconData,
                    size: 22,
                    color: itemColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    final fallbackCategories = [
      {'name': 'Burgers', 'icon': '🍔', 'color': '#F59E0B'},
      {'name': 'Pizza', 'icon': '🍕', 'color': '#EF4444'},
      {'name': 'Rice', 'icon': '🍚', 'color': '#22C55E'},
      {'name': 'Noodles', 'icon': '🍜', 'color': '#F97316'},
      {'name': 'Grill', 'icon': '🍖', 'color': '#8B5CF6'},
      {'name': 'Desserts', 'icon': '🍰', 'color': '#EC4899'},
      {'name': 'Drinks', 'icon': '🥤', 'color': '#3B82F6'},
      {'name': 'Kottu', 'icon': '🫓', 'color': '#14B8A6'},
    ];

    final cats = _categories.isNotEmpty
        ? _categories
        : fallbackCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => _openService(0),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final cat = cats[i];
              final catColor = Color(
                int.parse((cat['color'] as String? ?? '#6B7280').replaceFirst('#', '0xFF')),
              );
              return GestureDetector(
                onTap: () => _openService(0),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          cat['icon'] as String? ?? '🍽️',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection() {
    final offers = [
      {'title': '50% OFF', 'subtitle': 'Up to Rs.500', 'code': 'ALE50', 'color': const Color(0xFFDC143C)},
      {'title': 'Free Delivery', 'subtitle': 'On first order', 'code': 'FREE', 'color': const Color(0xFF22C55E)},
      {'title': '20% OFF', 'subtitle': 'Orders above Rs.1000', 'code': 'SAVE20', 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Offers & Promos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => _openService(0),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final offer = offers[i];
              final offerColor = offer['color'] as Color;
              return GestureDetector(
                onTap: () => _openService(0),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [offerColor, offerColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: offerColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          offer['code'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            offer['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Restaurants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => _openService(0),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loadingRestaurants)
          SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
            ),
          )
        else if (_restaurants.isEmpty)
          SizedBox(
            height: 140,
            child: Center(
              child: Text(
                'No restaurants available',
                style: TextStyle(color: context.textMuted, fontSize: 14),
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _restaurants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final r = _restaurants[i];
                final rating = (r['rating'] as num?)?.toDouble() ?? 0.0;
                final deliveryTime = r['delivery_time']?.toString() ?? '25-35';
                return GestureDetector(
                  onTap: () {
                    final restaurant = Restaurant.fromJson(r);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantViewScreen(restaurant: restaurant),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.cardBorder, width: 0.5),
                      boxShadow: context.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            image: r['image_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(r['image_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: r['image_url'] == null
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : null,
                          ),
                          child: r['image_url'] == null
                              ? Center(
                                  child: Icon(LucideIcons.utensils, size: 28, color: AppColors.accent.withValues(alpha: 0.4)),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r['name']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(LucideIcons.star, size: 12, color: AppColors.accent),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(LucideIcons.clock, size: 11, color: context.textMuted),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$deliveryTime min',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    if (_loadingRecent) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    if (_recentOrders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => _handleTabTap(1),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._recentOrders.map((order) => _buildRecentOrderCard(order)),
      ],
    );
  }

  Widget _buildRecentOrderCard(Map<String, dynamic> order) {
    final restaurantName = order['restaurant_name']?.toString() ?? 'Restaurant';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final status = order['status']?.toString() ?? '';
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'delivered':
        statusColor = AppColors.green;
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'cancelled':
        statusColor = AppColors.red;
        statusIcon = LucideIcons.xCircle;
        break;
      case 'preparing':
        statusColor = AppColors.accent;
        statusIcon = LucideIcons.chefHat;
        break;
      case 'on_the_way':
        statusColor = AppColors.blue;
        statusIcon = LucideIcons.bike;
        break;
      default:
        statusColor = AppColors.purple;
        statusIcon = LucideIcons.clock;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: GestureDetector(
        onTap: () => _handleTabTap(1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder, width: 0.5),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rs.${total.toStringAsFixed(0)} • ${status[0].toUpperCase()}${status.substring(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: context.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, LucideIcons.home, 'Home'),
            _navItem(1, LucideIcons.clipboardList, 'Activities'),
            _navItem(2, LucideIcons.shoppingBag, 'Cart'),
            _navItem(3, LucideIcons.user, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedTab == index && _serviceView == -1;
    return GestureDetector(
      onTap: () => _handleTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.accent : context.textMuted,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
