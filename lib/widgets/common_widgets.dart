import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

// ─── Network Image with shimmer ───────────────────────────────
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
            width: width, height: height, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppColors.orangeLight,
        child: const Icon(Icons.fastfood, color: AppColors.orange, size: 32),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}

// ─── Rating + Delivery Info Row ───────────────────────────────
class InfoRow extends StatelessWidget {
  final double rating;
  final bool freeDelivery;
  final int deliveryMin;
  final double fontSize;

  const InfoRow({
    super.key,
    required this.rating,
    required this.freeDelivery,
    required this.deliveryMin,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, color: AppColors.star, size: fontSize + 3),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: context.textPrimary)),
        const SizedBox(width: 10),
        Icon(Icons.delivery_dining_rounded,
            color: freeDelivery ? AppColors.green : context.textMuted,
            size: fontSize + 3),
        const SizedBox(width: 2),
        Text(freeDelivery ? 'Free' : 'Paid',
            style: TextStyle(
                fontSize: fontSize,
                color: freeDelivery ? AppColors.green : context.textMuted)),
        const SizedBox(width: 10),
        Icon(Icons.access_time_rounded,
            color: context.textMuted, size: fontSize + 3),
        const SizedBox(width: 2),
        Text('$deliveryMin min',
            style: TextStyle(fontSize: fontSize, color: context.textMuted)),
      ],
    );
  }
}

// ─── Restaurant Card ──────────────────────────────────────────
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantCard(
      {super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: restaurant.imageUrl,
              height: 160,
              width: double.infinity,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.category,
                    style: TextStyle(
                        fontSize: 12, color: context.textMuted),
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                    rating: restaurant.rating,
                    freeDelivery: restaurant.freeDelivery,
                    deliveryMin: restaurant.deliveryMin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Food Card (horizontal) ───────────────────────────────────
class FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const FoodCard(
      {super.key,
      required this.food,
      required this.onTap,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: food.imageUrl,
                  height: 110,
                  width: double.infinity,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Starting  Rs. ${food.price.toInt()}',
                      style: TextStyle(
                          fontSize: 11, color: context.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rs. ${food.price.toInt()}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange)),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Chip ────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final FoodCategory category;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: category.isSelected ? AppColors.orange : context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: category.isSelected ? Colors.white : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Orange Add Button ────────────────────────────────────────
class AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
            color: AppColors.orange, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See All',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ─── Shimmer Loading List ─────────────────────────────────────
class ShimmerList extends StatelessWidget {
  final int count;
  final double height;

  const ShimmerList({super.key, this.count = 3, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: height,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
