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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _deliveryLabel = 'Set delivery address';
  String _userName = 'User';
  StreamSubscription? _orderSub;

  @override
  void initState() {
    super.initState();
    _loadDeliveryLabel();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  void _subscribeToOrders() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
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

  void _handleTabTap(int index) {
    setState(() => _selectedTab = index);
    switch (index) {
      case 1:
        BuyerNavigator.orderHistory(context).then((_) => _loadDeliveryLabel());
        break;
      case 2:
        BuyerNavigator.cart(context).then((_) => _loadDeliveryLabel());
        break;
      case 3:
        BuyerNavigator.profile(context).then((_) => _loadDeliveryLabel());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                _buildGreeting(),
                _buildServicePills(),
                const SizedBox(height: 32),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildRecentSection(),
              ]),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Delivery address
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
          // Notification bell
          _iconButton(
            icon: LucideIcons.bell,
            onTap: () => BuyerNavigator.notifications(context),
          ),
          const SizedBox(width: 12),
          // Cart
          _iconButton(
            icon: LucideIcons.shoppingBag,
            onTap: () => BuyerNavigator.cart(context),
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
          Text(
            'What do you need?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePills() {
    final services = [
      {'key': 'Rides', 'icon': LucideIcons.bike, 'label': 'Rides'},
      {'key': 'Food', 'icon': LucideIcons.utensils, 'label': 'Food'},
      {'key': 'Parcel', 'icon': LucideIcons.package, 'label': 'Parcel'},
      {'key': 'Grocery', 'icon': LucideIcons.shoppingCart, 'label': 'Grocery'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 28),
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final s = services[i];
            return GestureDetector(
              onTap: () {
                final key = s['key'] as String;
                if (key == 'Rides') BuyerNavigator.rides(context);
                if (key == 'Food') BuyerNavigator.food(context);
                if (key == 'Parcel') BuyerNavigator.parcel(context);
                if (key == 'Grocery') BuyerNavigator.grocery(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                  boxShadow: context.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s['icon'] as IconData, size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Text(
                      s['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': LucideIcons.clock, 'label': 'Orders', 'onTap': () => BuyerNavigator.orderHistory(context)},
      {'icon': LucideIcons.heart, 'label': 'Favorites', 'onTap': () => BuyerNavigator.favorites(context)},
      {'icon': LucideIcons.percent, 'label': 'Offers', 'onTap': () => BuyerNavigator.food(context)},
      {'icon': LucideIcons.headphones, 'label': 'Support', 'onTap': () => BuyerNavigator.helpSupport(context)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          return GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    a['icon'] as IconData,
                    size: 22,
                    color: AppColors.accent,
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

  Widget _buildRecentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular near you',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildPromoCard(),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return GestureDetector(
      onTap: () => BuyerNavigator.food(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE63946), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PROMO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Free delivery\non your first order',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Order now',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: context.scaffoldBg.withValues(alpha: 0.85),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBg.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
    final isActive = _selectedTab == index;
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
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : context.textMuted,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
