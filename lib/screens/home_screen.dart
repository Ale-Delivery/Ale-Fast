import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const _primary = AppColors.orange;

  int _selectedTab = 0;
  String _deliveryLabel = 'Set delivery address';
  String _userName = 'User';
  StreamSubscription? _orderSub;

  ThemeData? _appTheme;

  @override
  void initState() {
    super.initState();
    _loadDeliveryLabel();
    _subscribeToOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appTheme ??= Theme.of(context).copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
    );
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: status == 'ready'
              ? AppColors.green
              : status == 'preparing'
                  ? AppColors.orange
                  : const Color(0xFF3B82F6),
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
    return Theme(
      data: _appTheme ?? Theme.of(context),
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  _buildHeroSearch(),
                  _buildServicesRow(),
                ]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 104)),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHeader() {
    final cartCount = context.select<CartProvider, int>((c) => c.itemCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          _roundButton(LucideIcons.clipboardList,
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
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: context.textPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => BuyerNavigator.notifications(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
              ),
              child: Icon(LucideIcons.bell,
                  color: context.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => BuyerNavigator.cart(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.shoppingBag,
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
            style: TextStyle(fontSize: 16, color: context.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            'What would you like?',
            style: TextStyle(
              fontSize: 25,
              height: 1.14,
              color: context.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesRow() {
    final services = [
      {
        'key': 'Rides',
        'icon': LucideIcons.bike,
        'title': 'Rides',
        'color': const Color(0xFF00C6FF),
      },
      {
        'key': 'Food',
        'icon': LucideIcons.utensils,
        'title': 'Food',
        'color': const Color(0xFFFF6B35),
      },
      {
        'key': 'Parcel',
        'icon': LucideIcons.package,
        'title': 'Parcel',
        'color': const Color(0xFF6C5CE7),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: List.generate(services.length, (i) {
          final s = services[i];
          final color = s['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                final key = s['key'] as String;
                if (key == 'Rides') {
                  BuyerNavigator.rides(context);
                } else if (key == 'Parcel') {
                  BuyerNavigator.parcel(context);
                } else if (key == 'Food') {
                  BuyerNavigator.food(context);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _roundButton(IconData icon, {VoidCallback? onTap, Color? color, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color ?? context.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.onSurface, size: 21),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: isDark ? AppColors.orange.withValues(alpha: 0.2) : AppColors.orangeLight,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected) ? _primary : context.textMuted,
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
            destinations: [
              NavigationDestination(
                icon: Icon(LucideIcons.home),
                selectedIcon: Icon(LucideIcons.home, color: _primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.clipboardList),
                selectedIcon: Icon(LucideIcons.clipboardList, color: _primary),
                label: 'Activities',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.shoppingBag),
                selectedIcon: Icon(LucideIcons.shoppingBag, color: _primary),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.user),
                selectedIcon: Icon(LucideIcons.user, color: _primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
