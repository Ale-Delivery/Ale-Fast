import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';
import 'grocery_cart_screen.dart';

class GroceryProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Color accentColor;

  const GroceryProductDetailScreen({
    super.key,
    required this.product,
    required this.accentColor,
  });

  @override
  State<GroceryProductDetailScreen> createState() => _GroceryProductDetailScreenState();
}

class _GroceryProductDetailScreenState extends State<GroceryProductDetailScreen> {
  int _quantity = 1;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('Grocery_Wishlist')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', widget.product['id'])
          .maybeSingle();
      if (mounted) setState(() => _isWishlisted = data != null);
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      if (_isWishlisted) {
        await Supabase.instance.client
            .from('Grocery_Wishlist')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', widget.product['id']);
      } else {
        await Supabase.instance.client.from('Grocery_Wishlist').insert({
          'user_id': userId,
          'product_id': widget.product['id'],
        });
      }
      if (mounted) setState(() => _isWishlisted = !_isWishlisted);
    } catch (_) {}
  }

  Future<void> _addToCart() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;
    try {
      final existing = await Supabase.instance.client
          .from('Grocery_Cart')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('Grocery_Cart')
            .update({'quantity': existing['quantity'] + _quantity})
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('Grocery_Cart').insert({
          'user_id': userId,
          'product_id': widget.product['id'],
          'quantity': _quantity,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} added to cart!'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryCartScreen()));
              },
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final price = (p['price'] as num?)?.toDouble() ?? 0.0;
    final unit = p['unit']?.toString() ?? '1pc';
    final imageUrl = p['image_url']?.toString();
    final name = p['name']?.toString() ?? '';
    final description = p['description']?.toString() ?? 'No description available';
    final outOfStock = p['stock'] == false;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.surfaceColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: context.textPrimary),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _toggleWishlist,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isWishlisted ? LucideIcons.heart : LucideIcons.heart,
                    size: 20,
                    color: _isWishlisted ? AppColors.red : context.textMuted,
                    fill: _isWishlisted ? 1.0 : 0.0,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: widget.accentColor.withValues(alpha: 0.05),
                      child: Center(
                        child: Icon(LucideIcons.package, size: 64, color: widget.accentColor.withValues(alpha: 0.3)),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              unit,
                              style: TextStyle(fontSize: 14, color: context.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Rs.${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'About this product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildNutritionInfo(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(outOfStock, price),
    );
  }

  Widget _buildNutritionInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _nutritionItem('Calories', '250', LucideIcons.flame, const Color(0xFFEF4444)),
          _nutritionItem('Protein', '12g', LucideIcons.dumbbell, const Color(0xFF3B82F6)),
          _nutritionItem('Carbs', '30g', LucideIcons.wheat, const Color(0xFFF59E0B)),
          _nutritionItem('Fat', '8g', LucideIcons.droplets, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _nutritionItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary)),
        Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
      ],
    );
  }

  Widget _buildBottomBar(bool outOfStock, double price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.cardBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                _qtyButton(
                  icon: LucideIcons.minus,
                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                _qtyButton(
                  icon: LucideIcons.plus,
                  onTap: outOfStock ? null : () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: outOfStock ? null : _addToCart,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: outOfStock ? null : LinearGradient(colors: [AppColors.green, AppColors.green.withValues(alpha: 0.8)]),
                  color: outOfStock ? context.textMuted.withValues(alpha: 0.3) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    outOfStock ? 'Out of Stock' : 'Add to Cart · Rs.${(price * _quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.green.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? AppColors.green : context.textMuted),
      ),
    );
  }
}
