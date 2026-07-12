import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Map<String, dynamic>>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _fetchFavorites();
  }

  Future<List<Map<String, dynamic>>> _fetchFavorites() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return [];

    final data = await Supabase.instance.client
        .from('Favorites')
        .select('restaurant_id, Restaurants(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _removeFavorite(String restaurantId) async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    await Supabase.instance.client
        .from('Favorites')
        .delete()
        .eq('user_id', userId)
        .eq('restaurant_id', restaurantId);

    setState(() {
      _favoritesFuture = _fetchFavorites();
    });
  }

  void _onRestaurantTap(Map<String, dynamic> favorite) {
    final restaurant = favorite['Restaurants'] as Map<String, dynamic>?;
    if (restaurant != null) {
      Navigator.pop(context, restaurant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, size: 48, color: context.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading favorites',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.heart, size: 56, color: context.textHint),
                  const SizedBox(height: 20),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save your favorite restaurants',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: favorites.length,
            itemBuilder: (context, i) {
              final fav = favorites[i];
              final restaurant = fav['Restaurants'] as Map<String, dynamic>?;
              if (restaurant == null) return const SizedBox.shrink();

              final name = restaurant['name'] ?? 'Restaurant';
              final cuisine = restaurant['cuisine'] ?? '';
              final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0.0;
              final imageUrl = restaurant['image_url'] ?? '';

              return Dismissible(
                key: Key(restaurant['id'].toString()),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeFavorite(restaurant['id'].toString()),
                background: Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
                ),
                child: GestureDetector(
                  onTap: () => _onRestaurantTap(fav),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.cardBorder, width: 0.5),
                      boxShadow: context.cardShadow,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 60,
                                    height: 60,
                                    color: context.chipBg,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: context.chipBg,
                                    child: Icon(LucideIcons.store, color: context.textHint, size: 24),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: context.chipBg,
                                  child: Icon(LucideIcons.store, color: context.textHint, size: 24),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              if (cuisine.toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  cuisine.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.star, size: 12, color: AppColors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
