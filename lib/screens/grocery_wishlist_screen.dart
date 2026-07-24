import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';
import 'grocery_product_detail_screen.dart';

class GroceryWishlistScreen extends StatefulWidget {
  const GroceryWishlistScreen({super.key});

  @override
  State<GroceryWishlistScreen> createState() => _GroceryWishlistScreenState();
}

class _GroceryWishlistScreenState extends State<GroceryWishlistScreen> {
  List<Map<String, dynamic>> _wishlist = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('Grocery_Wishlist')
          .select('id, product_id, Grocery_Products(id, name, price, unit, image_url, stock, category_id)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _wishlist = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFromWishlist(String wishlistId) async {
    try {
      await Supabase.instance.client.from('Grocery_Wishlist').delete().eq('id', wishlistId);
      _loadWishlist();
    } catch (_) {}
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
                  : _wishlist.isEmpty
                      ? _buildEmptyState()
                      : _buildWishlistContent(),
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
            'My Wishlist',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_wishlist.length} items',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(LucideIcons.heart, size: 36, color: AppColors.red.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text('No saved items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text('Items you save will appear here', style: TextStyle(fontSize: 14, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _buildWishlistContent() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: _wishlist.length,
      itemBuilder: (context, i) {
        final item = _wishlist[i];
        final product = item['Grocery_Products'];
        if (product == null) return const SizedBox.shrink();
        return _buildWishlistItem(item, product);
      },
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> item, Map<String, dynamic> product) {
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final unit = product['unit']?.toString() ?? '1pc';
    final imageUrl = product['image_url']?.toString();
    final name = product['name']?.toString() ?? '';
    final outOfStock = product['stock'] == false;

    return GestureDetector(
      onTap: outOfStock ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroceryProductDetailScreen(
              product: product,
              accentColor: AppColors.green,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.green.withValues(alpha: 0.05),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    )
                  : Icon(LucideIcons.package, size: 24, color: AppColors.green.withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Rs.${price.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
                      const SizedBox(width: 6),
                      Text(unit, style: TextStyle(fontSize: 12, color: context.textMuted)),
                    ],
                  ),
                  if (outOfStock) ...[
                    const SizedBox(height: 4),
                    Text('Out of stock', style: TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _removeFromWishlist(item['id']),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.heart, size: 18, color: AppColors.red, fill: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
