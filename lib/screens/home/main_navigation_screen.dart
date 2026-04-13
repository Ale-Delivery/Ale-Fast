import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Search & Categories')),
    const Center(child: Text('Your Cart')),
    const Center(child: Text('Profile Settings')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.saved_search)),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.shopping_cart_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.shopping_cart)),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy Home Screen Widget to showcase the UI direction
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFFF8F9FA),
              title: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFE60000)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivering to',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Text(
                        'Colombo 03, Sri Lanka',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for food, groceries...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE60000),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE60000), Color(0xFFFF4D4D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE60000).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PROMO CODE: RED20',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Get 20% Off\nYour First Order!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                    const SizedBox(height: 24),
                    
                    // Categories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('See All', style: TextStyle(color: Color(0xFFE60000), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryItem(Icons.fastfood, 'Food', true),
                          _buildCategoryItem(Icons.local_grocery_store, 'Grocery', false),
                          _buildCategoryItem(Icons.local_pharmacy, 'Pharmacy', false),
                          _buildCategoryItem(Icons.card_giftcard, 'Parcels', false),
                        ],
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 24),
                    const Text('Top Restaurants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRestaurantCard('Burger King', 'Burgers, American', '4.5', '15-25 min', 'Free Delivery'),
                    const SizedBox(height: 16),
                    _buildRestaurantCard('Pizza Hut', 'Pizza, Italian', '4.2', '30-45 min', 'Rs. 150'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE60000) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFE60000).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(String name, String tags, String rating, String time, String fee) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder Image
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tags, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(time, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Icon(Icons.delivery_dining, size: 16, color: Color(0xFFE60000)),
                    const SizedBox(width: 4),
                    Text(fee, style: const TextStyle(color: Color(0xFFE60000), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
