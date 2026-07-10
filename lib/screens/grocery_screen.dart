import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class GroceryScreen extends StatefulWidget {
  final bool isEmbedded;
  const GroceryScreen({super.key, this.isEmbedded = false});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  String _query = '';

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Fruits', 'icon': LucideIcons.apple},
    {'name': 'Vegetables', 'icon': LucideIcons.leaf},
    {'name': 'Dairy', 'icon': LucideIcons.milk},
    {'name': 'Bakery', 'icon': LucideIcons.croissant},
    {'name': 'Snacks', 'icon': LucideIcons.cookie},
    {'name': 'Drinks', 'icon': LucideIcons.coffee},
    {'name': 'Meat', 'icon': LucideIcons.beef},
    {'name': 'Frozen', 'icon': LucideIcons.snowflake},
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
          if (!widget.isEmbedded) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
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
          ],
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
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  cat['icon'] as IconData,
                  size: 22,
                  color: AppColors.accent,
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
      {'name': 'Fresh Apples', 'price': 'Rs. 350', 'unit': '1kg'},
      {'name': 'Milk Pack', 'price': 'Rs. 220', 'unit': '1L'},
      {'name': 'Bread Loaf', 'price': 'Rs. 180', 'unit': '1pc'},
      {'name': 'Eggs', 'price': 'Rs. 280', 'unit': '12pc'},
    ];

    return Column(
      children: items.map((item) {
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
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.package, size: 22, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['unit']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item['price']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
