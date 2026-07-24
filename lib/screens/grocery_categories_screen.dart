import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'grocery_product_list_screen.dart';

class GroceryCategoriesScreen extends StatefulWidget {
  const GroceryCategoriesScreen({super.key});

  @override
  State<GroceryCategoriesScreen> createState() => _GroceryCategoriesScreenState();
}

class _GroceryCategoriesScreenState extends State<GroceryCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await Supabase.instance.client
          .from('Grocery_Categories')
          .select('id, name, icon, color, description')
          .order('sort_order');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.green))
                  : _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.layoutGrid, size: 48, color: context.textMuted),
                              const SizedBox(height: 12),
                              Text('No categories yet', style: TextStyle(color: context.textMuted, fontSize: 14)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          color: AppColors.green,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.4,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, i) {
                              final cat = _categories[i];
                              final catColor = Color(
                                int.parse((cat['color'] as String? ?? '#22C55E').replaceFirst('#', '0xFF')),
                              );
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GroceryProductListScreen(
                                        categoryId: cat['id'].toString(),
                                        categoryName: cat['name'] ?? '',
                                        categoryColor: catColor,
                                      ),
                                    ),
                                  );
                                },
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
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(cat['icon']?.toString()),
                                          size: 22,
                                          color: catColor,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          if (cat['description'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              cat['description'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, color: context.textMuted),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
          Text(
            'All Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
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
