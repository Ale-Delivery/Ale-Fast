import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'food_detail_screen.dart';
import 'restaurant_view_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _searching = false;
  List<Restaurant> _restaurants = [];
  List<FoodItem> _foods = [];
  bool _hasSearched = false;

  final List<String> _recentKeywords = [
    'Burger', 'Sandwich', 'Pizza', 'Sandwich'
  ];

  final List<Restaurant> _suggestedRestaurants = const [
    Restaurant(
        id: '1',
        name: 'Pansi Restaurant',
        imageUrl:
            'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=100',
        rating: 4.7,
        freeDelivery: true,
        deliveryMin: 15,
        category: 'Pizza',
        description: '',
        address: ''),
    Restaurant(
        id: '2',
        name: 'American Spicy Burger Shop',
        imageUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=100',
        rating: 4.3,
        freeDelivery: false,
        deliveryMin: 25,
        category: 'Burger',
        description: '',
        address: ''),
    Restaurant(
        id: '3',
        name: 'Caferio Coffee Club',
        imageUrl:
            'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=100',
        rating: 4.0,
        freeDelivery: true,
        deliveryMin: 10,
        category: 'Coffee',
        description: '',
        address: ''),
  ];

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _hasSearched = false; _restaurants = []; _foods = []; });
      return;
    }
    setState(() => _searching = true);
    final result = await DatabaseService.search(q);
    if (mounted) {
      setState(() {
        _restaurants = result['restaurants'] as List<Restaurant>;
        _foods = result['foods'] as List<FoodItem>;
        _searching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Pizza',
            hintStyle: const TextStyle(color: AppColors.grey),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    })
                : null,
          ),
          onChanged: (v) {
            setState(() {});
            _search(v);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _hasSearched
              ? _buildResults()
              : _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Recent Keywords',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentKeywords
              .map((k) => GestureDetector(
                    onTap: () {
                      _controller.text = k;
                      _search(k);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lightBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(k,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text('Suggested Restaurants',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._suggestedRestaurants.map(
          (r) => GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => RestaurantViewScreen(restaurant: r))),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  AppNetworkImage(
                    url: r.imageUrl,
                    width: 50,
                    height: 50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        InfoRow(
                          rating: r.rating,
                          freeDelivery: r.freeDelivery,
                          deliveryMin: r.deliveryMin,
                          fontSize: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Popular Fast Food',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            _popularTag('🍕 European Pizza'),
            const SizedBox(width: 10),
            _popularTag('🍔 Buffalo Pizza'),
          ],
        ),
      ],
    );
  }

  Widget _popularTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.orange)),
    );
  }

  Widget _buildResults() {
    if (_restaurants.isEmpty && _foods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😕', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('No results found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_restaurants.isNotEmpty) ...[
          const Text('Restaurants',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._restaurants.map((r) => RestaurantCard(
                restaurant: r,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RestaurantViewScreen(restaurant: r))),
              )),
        ],
        if (_foods.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Foods',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._foods.map((f) => GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(food: f))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      AppNetworkImage(
                        url: f.imageUrl,
                        width: 60,
                        height: 60,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(f.restaurantName,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.grey)),
                            const SizedBox(height: 4),
                            InfoRow(
                                rating: f.rating,
                                freeDelivery: f.freeDelivery,
                                deliveryMin: f.deliveryMin,
                                fontSize: 10),
                          ],
                        ),
                      ),
                      Text('\$${f.price.toInt()}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange)),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
