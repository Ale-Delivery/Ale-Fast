import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../navigation/buyer_navigator.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E2C)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF1E1E2C)),
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
              color: const Color(0xFFFF7A1A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A1A).withOpacity(0.3),
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
                  icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFF7A1A), size: 18),
                  label: const Text(
                    'VIEW CART',
                    style: TextStyle(
                      color: Color(0xFFFF7A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurant['name'] ?? 'Unknown Restaurant',
                      style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1E2C)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.restaurant['tags'] ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 15),
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
                            const Color(0xFFFF7A1A)),
                        _infoChip(
                            Icons.access_time_rounded,
                            widget.restaurant['delivery_time'] ?? 'N/A',
                            Colors.grey),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "Popular Menu",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E2C)),
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
                                  color: Color(0xFFFF7A1A)));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red)));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No menu items available yet.",
                                  style: TextStyle(color: Colors.grey)),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF0F0F0)),
                              ),
                              child: Row(
                                children: [
                                  // Food image
                                    AppNetworkImage(
                                      url: item['image_url'] ?? '',
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  const SizedBox(width: 15),
                                  // Food details and price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Unknown Item',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E1E2C)),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500]),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Rs. ${item['price']}",
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF7A1A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Add Button
                                  GestureDetector(
                                    onTap: () {
                                      context.read<CartProvider>().addItem(food);
                                    },
                                    child: Container(
                                      height: 35,
                                      width: 35,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF7A1A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 20),
                                    ),
                                  )
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
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E2C))),
      ],
    );
  }
}
