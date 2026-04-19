import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase Import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All";

  // Design එකේ තියෙන විදියට Categories ලැයිස්තුව
  final List<Map<String, dynamic>> categories = [
    {"name": "All", "icon": Icons.local_fire_department_rounded},
    {"name": "Burger", "icon": Icons.lunch_dining_rounded},
    {"name": "Pizza", "icon": Icons.local_pizza_rounded},
    {"name": "Sandwich", "icon": Icons.lunch_dining_outlined},
  ];

  // Banners සඳහා තාවකාලික පින්තූර ලැයිස්තුව
  final List<String> imgList = [
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
  ];

  // Supabase එකෙන් Data ගන්න Function එක
  Future<List<Map<String, dynamic>>> _fetchRestaurants() async {
    final response =
        await Supabase.instance.client.from('Restaurants').select();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildOrderStatus(),
                _buildGreeting(),
                _buildSearchBar(),
                _buildBannerSlider(), // Native Slider (No Errors)
                _buildSectionTitle("All Categories"),
                _buildCategoryList(),
                _buildSectionTitle("Open Restaurants"),
                _buildRestaurantList(), // Supabase FutureBuilder Data
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  // 1. Header (Location & Cart with Badge)
  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.menu,
                      color: Color(0xFF1E1E2C), size: 20),
                ),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("DELIVER TO",
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFFF7A1A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                  const Text("Halal Lab office ▾",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E2C))),
                ]),
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: Color(0xFF1E1E2C), shape: BoxShape.circle),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Colors.white, size: 22),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF7A1A), shape: BoxShape.circle),
                    child: const Text("2",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ],
        ),
      );

  // 2. Order Tracking Status Bar
  Widget _buildOrderStatus() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Color(0xFFFF7A1A)),
            const SizedBox(width: 10),
            Text("Your order is being prepared...",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900)),
          ],
        ),
      );

  // 3. Greeting Text
  Widget _buildGreeting() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text("Hey Halal, Good Afternoon!",
            style: TextStyle(fontSize: 18, color: Color(0xFF1E1E2C))),
      );

  // 4. Modern Search Bar
  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search dishes, restaurants",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      );

  // 5. Native Banner Slider (No Packages Needed!)
  Widget _buildBannerSlider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 160.0,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: imgList.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                      image: NetworkImage(imgList[index]), fit: BoxFit.cover),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5)),
                  ],
                ),
              );
            },
          ),
        ),
      );

  // Section Title Utility
  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E2C))),
            const Text("See All >",
                style: TextStyle(
                    color: Color(0xFFFF7A1A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  // 6. Modern Category List
  Widget _buildCategoryList() => SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            bool isSelected = selectedCategory == category["name"];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () =>
                    setState(() => selectedCategory = category["name"]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF7A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(category["icon"],
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFFF7A1A),
                          size: 20),
                      const SizedBox(width: 8),
                      Text(category["name"],
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1E1E2C),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

  // 7. Supabase Database එකෙන් ගෙනෙන Restaurant List එක
  Widget _buildRestaurantList() => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Color(0xFFFF7A1A)),
            ));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No restaurants found."),
            ));
          }

          final restaurants = snapshot.data!;

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Image.network(
                        restaurant['image_url'] ?? '',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant,
                              size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant['name'] ?? 'Unknown Restaurant',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E1E2C))),
                          const SizedBox(height: 5),
                          Text(restaurant['tags'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoTag(
                                  Icons.star_rounded,
                                  restaurant['rating']?.toString() ?? "N/A",
                                  Colors.amber),
                              _infoTag(
                                  Icons.directions_run_rounded,
                                  restaurant['delivery_fee'] ?? "Free",
                                  const Color(0xFFFF7A1A)),
                              _infoTag(
                                  Icons.access_time_rounded,
                                  restaurant['delivery_time'] ?? "N/A",
                                  Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

  // Info Tag Utility for Card
  Widget _infoTag(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E1E2C))),
        ],
      );

  // 8. Modern Bottom Navigation Bar
  Widget _buildBottomNavBar() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFFFF7A1A),
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border_rounded), label: "Favorites"),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_rounded),
                label: "Notifications"),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: "Profile"),
          ],
        ),
      );
}
