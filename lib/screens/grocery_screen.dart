import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class GroceryScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  const GroceryScreen({super.key, this.isEmbedded = false, this.onBack});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  String _query = '';

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Fruits', 'icon': LucideIcons.apple, 'color': Color(0xFF22C55E)},
    {'name': 'Vegetables', 'icon': LucideIcons.leaf, 'color': Color(0xFF16A34A)},
    {'name': 'Dairy', 'icon': LucideIcons.milk, 'color': Color(0xFF3B82F6)},
    {'name': 'Bakery', 'icon': LucideIcons.croissant, 'color': Color(0xFFF59E0B)},
    {'name': 'Snacks', 'icon': LucideIcons.cookie, 'color': Color(0xFFEA580C)},
    {'name': 'Drinks', 'icon': LucideIcons.coffee, 'color': Color(0xFF8B5CF6)},
    {'name': 'Meat', 'icon': LucideIcons.beef, 'color': Color(0xFFEF4444)},
    {'name': 'Frozen', 'icon': LucideIcons.snowflake, 'color': Color(0xFF06B6D4)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                children: [
                  _buildSectionTitle('Categories'),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Popular Items'),
                  const SizedBox(height: 14),
                  _buildPopularItems(),
                ],
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
          ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat = _categories[i];
        return GestureDetector(
          onTap: () {},
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (cat['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  cat['icon'] as IconData,
                  size: 22,
                  color: cat['color'] as Color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat['name'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularItems() {
    final items = [
      {'name': 'Fresh Apples', 'price': 'Rs. 350', 'unit': '1kg', 'icon': LucideIcons.apple, 'color': const Color(0xFF22C55E)},
      {'name': 'Milk Pack', 'price': 'Rs. 220', 'unit': '1L', 'icon': LucideIcons.milk, 'color': const Color(0xFF3B82F6)},
      {'name': 'Bread Loaf', 'price': 'Rs. 180', 'unit': '1pc', 'icon': LucideIcons.croissant, 'color': const Color(0xFFF59E0B)},
      {'name': 'Eggs', 'price': 'Rs. 280', 'unit': '12pc', 'icon': LucideIcons.egg, 'color': const Color(0xFFEA580C)},
    ];

    return Column(
      children: items.map((item) {
        final itemColor = item['color'] as Color;
        return Container(
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
                  color: itemColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item['icon'] as IconData, size: 22, color: itemColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item['name'] as String),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (item['unit'] as String),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                (item['price'] as String),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: itemColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
