import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void nextPage() {
    if (isLastPage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7A1A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  isLastPage = index == 2;
                });
              },
              children: const [
                OnboardPage(
                  icon: Icons.fastfood_rounded,
                  title: "All your favorites",
                  subtitle:
                      "Get all your loved foods in one place, you just place the order we do the rest.",
                ),
                OnboardPage(
                  icon: Icons.restaurant_menu_rounded,
                  title: "Order from chosen chef",
                  subtitle:
                      "Get all your loved foods in one place, you just place the order we do the rest.",
                ),
                OnboardPage(
                  icon: Icons.delivery_dining_rounded,
                  title: "Free delivery offers",
                  subtitle:
                      "Get all your loved foods in one place, you just place the order we do the rest.",
                ),
              ],
            ),

            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                      dotColor: Color(0xFFFFD3B0),
                      activeDotColor: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isLastPage ? "GET STARTED" : "NEXT",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isLastPage)
                    TextButton(
                      onPressed: () {
                        _controller.jumpToPage(2);
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
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

class OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const OnboardPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7A1A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 40 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E9),
                borderRadius: BorderRadius.circular(110),
              ),
              child: Icon(icon, size: 110, color: primaryColor),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2D),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
