import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:food_app/theme/app_theme.dart';
import 'package:food_app/navigation/buyer_navigator.dart';

class OnboardingItem {
  final String emoji;
  final String title;
  final String description;
  final Color bgColor;

  const OnboardingItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.bgColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      emoji: '🍔',
      title: 'All your favorites',
      description:
          'Get all your loved foods in one place, you just place the order we do the rest',
      bgColor: Color(0xFFFFF3EE),
    ),
    OnboardingItem(
      emoji: '👨‍🍳',
      title: 'Order from chosen chef',
      description:
          'Pick from the best local chefs and restaurants near you, quality guaranteed',
      bgColor: Color(0xFFFFEEE0),
    ),
    OnboardingItem(
      emoji: '🛵',
      title: 'Free delivery offers',
      description:
          'Enjoy free delivery on your first 3 orders. Fast, fresh and right to your door',
      bgColor: Color(0xFFFFF8EE),
    ),
  ];

  void _goToNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  // 👇 Login wenuwata PhoneAuthScreen ekata yanna wenas kara
  void _goToAuth() => BuyerNavigator.phoneAuth(context, replace: true);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Column(
        children: [
          // Page View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Column(
                  children: [
                    // Image area
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 300,
                      width: double.infinity,
                      color: item.bgColor,
                      child: Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkBg,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.description,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppTheme.greyText,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
            child: Column(
              children: [
                // Dots
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _items.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppTheme.orange,
                    dotColor: Colors.grey[300]!,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                  ),
                ),
                const SizedBox(height: 24),

                // Next / Get Started button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _items.length - 1
                          ? 'GET STARTED'
                          : 'NEXT',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Skip button
                TextButton(
                  onPressed: _goToAuth, // 👇 Methanath wenas kara
                  child: Text(
                    'Skip',
                    style: GoogleFonts.nunito(
                      color: AppTheme.greyText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
