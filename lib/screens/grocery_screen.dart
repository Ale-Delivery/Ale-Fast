import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'grocery_categories_screen.dart';
import 'grocery_product_list_screen.dart';
import 'grocery_product_detail_screen.dart';
import 'grocery_cart_screen.dart';
import 'grocery_wishlist_screen.dart';

class GroceryScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  const GroceryScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  String _query = '';
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  bool _loadingCategories = true;
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFeaturedProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await Supabase.instance.client
          .from('Grocery_Categories')
          .select('id, name, icon, color')
          .order('sort_order');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final data = await Supabase.instance.client
          .from('Grocery_Products')
          .select('id, name, price, unit, image_url, stock, category_id')
          .eq('is_featured', true)
          .eq('stock', true)
          .limit(10);
      if (mounted) {
        setState(() {
          _featuredProducts = List<Map<String, dynamic>>.from(data);
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildActionBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadCategories();
                  await _loadFeaturedProducts();
                },
                color: AppColors.green,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  children: [
                    _buildSectionTitle('Categories', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryCategoriesScreen()));
                    }),
                    const SizedBox(height: 14),
                    _buildCategoryGrid(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Featured Items', onTap: () {
                      if (_categories.isNotEmpty) {
                        final cat = _categories.first;
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => GroceryProductListScreen(
                            categoryId: cat['id'].toString(),
                            categoryName: cat['name'] ?? '',
                            categoryColor: AppColors.green,
                          ),
                        ));
                      }
                    }),
                    const SizedBox(height: 14),
                    _buildFeaturedProducts(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.cardBorder, width: 0.5),
              ),
              child: Icon(LucideIcons.arrowLeft, size: 18, color: context.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grocery',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fresh items delivered',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryCartScreen())),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.shoppingCart, size: 20, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: context.cardShadow,
        ),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search grocery items...',
            hintStyle: TextStyle(color: context.textHint, fontWeight: FontWeight.w400),
            prefixIcon: Icon(LucideIcons.search, size: 20, color: context.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _actionChip(LucideIcons.layoutGrid, 'Categories', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryCategoriesScreen()));
          }),
          const SizedBox(width: 8),
          _actionChip(LucideIcons.heart, 'Wishlist', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryWishlistScreen()));
          }),
          const SizedBox(width: 8),
          _actionChip(LucideIcons.calendarClock, 'Schedule', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryCartScreen()));
          }),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.green),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              'See all',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    if (_loadingCategories) {
      return SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)),
      );
    }

    if (_categories.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('No categories yet', style: TextStyle(color: context.textMuted)),
        ),
      );
    }

    final displayCats = _categories.length > 8 ? _categories.sublist(0, 8) : _categories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: displayCats.length,
      itemBuilder: (context, i) {
        final cat = displayCats[i];
        final catColor = Color(
          int.parse((cat['color'] as String? ?? '#22C55E').replaceFirst('#', '0xFF')),
        );
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => GroceryProductListScreen(
                categoryId: cat['id'].toString(),
                categoryName: cat['name'] ?? '',
                categoryColor: catColor,
              ),
            ));
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_getCategoryIcon(cat['icon']?.toString()), size: 22, color: catColor),
              ),
              const SizedBox(height: 8),
              Text(
                cat['name'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProducts() {
    if (_loadingProducts) {
      return SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)),
      );
    }

    if (_featuredProducts.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text('No featured items', style: TextStyle(color: context.textMuted)),
        ),
      );
    }

    return Column(
      children: _featuredProducts.map((product) {
        final price = (product['price'] as num?)?.toDouble() ?? 0.0;
        final unit = product['unit']?.toString() ?? '1pc';
        final imageUrl = product['image_url']?.toString();
        final name = product['name']?.toString() ?? '';
        final outOfStock = product['stock'] == false;

        return GestureDetector(
          onTap: outOfStock ? null : () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => GroceryProductDetailScreen(
                product: product,
                accentColor: AppColors.green,
              ),
            ));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder, width: 0.5),
              boxShadow: context.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.green.withValues(alpha: 0.05),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(imageUrl, fit: BoxFit.cover, width: 52, height: 52),
                        )
                      : Icon(LucideIcons.package, size: 22, color: AppColors.green.withValues(alpha: 0.4)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                      const SizedBox(height: 2),
                      Text(unit, style: TextStyle(fontSize: 12, color: context.textMuted)),
                    ],
                  ),
                ),
                Text('Rs.${price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String? icon) {
    switch (icon) {
      case 'apple': return LucideIcons.apple;
      case 'leaf': return LucideIcons.leaf;
      case 'milk': return LucideIcons.milk;
      case 'croissant': return LucideIcons.croissant;
      case 'cookie': return LucideIcons.cookie;
      case 'coffee': return LucideIcons.coffee;
      case 'beef': return LucideIcons.beef;
      case 'snowflake': return LucideIcons.snowflake;
      case 'egg': return LucideIcons.egg;
      case 'carrot': return LucideIcons.carrot;
      case 'fish': return LucideIcons.fish;
      case 'wine': return LucideIcons.wine;
      default: return LucideIcons.package;
    }
  }
}
