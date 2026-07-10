import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../navigation/buyer_navigator.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../widgets/common_widgets.dart';

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const DetailsScreen({super.key, required this.restaurant});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Future<List<Map<String, dynamic>>> _menuItemsFuture;

  Future<List<Map<String, dynamic>>> _fetchMenuItems() async {
    final response = await Supabase.instance.client
        .from('Menu_Items')
        .select()
        .eq('restaurant_id', widget.restaurant['id']);
    return response;
  }

  @override
  void initState() {
    super.initState();
    _menuItemsFuture = _fetchMenuItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: context.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) return const SizedBox.shrink();

          return Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom > 0 ? 12 : 20,
              left: 16,
              right: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.itemCount} Item${cart.itemCount > 1 ? 's' : ''} added',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rs. ${cart.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => BuyerNavigator.cart(context),
                  icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.orange, size: 18),
                  label: const Text(
                    'VIEW CART',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: context.surfaceColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant image
              AppNetworkImage(
              url: widget.restaurant['image_url'] ?? '',
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            // Restaurant details
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: context.scaffoldBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurant['name'] ?? 'Unknown Restaurant',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.restaurant['tags'] ?? '',
                      style: TextStyle(color: context.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoChip(
                            Icons.star_rounded,
                            widget.restaurant['rating']?.toString() ?? 'N/A',
                            Colors.amber),
                        _infoChip(
                            Icons.directions_run_rounded,
                            widget.restaurant['delivery_fee'] ?? 'Free',
                            AppColors.orange),
                        _infoChip(
                            Icons.access_time_rounded,
                            widget.restaurant['delivery_time'] ?? 'N/A',
                            context.textMuted),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Text(
                      "Popular Menu",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary),
                    ),
                    const SizedBox(height: 15),

                    // Menu items from Supabase
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _menuItemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.orange));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red)));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text("No menu items available yet.",
                                  style: TextStyle(color: context.textMuted)),
                            ),
                          );
                        }

                        final menuItems = snapshot.data!;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            final food = DatabaseService.foodItemFromMenuAndRestaurant(
                              item,
                              widget.restaurant,
                            );
                            return GestureDetector(
                              onTap: () => BuyerNavigator.foodDetail(context, food),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.surfaceColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: context.cardBorder.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    AppNetworkImage(
                                      url: item['image_url'] ?? '',
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] ?? 'Unknown Item',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: context.textPrimary),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item['description'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: context.textMuted),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Rs. ${item['price']}",
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.orange),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.read<CartProvider>().addItem(food);
                                      },
                                      child: Container(
                                        height: 35,
                                        width: 35,
                                        decoration: const BoxDecoration(
                                          color: AppColors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimary)),
      ],
    );
  }
}
