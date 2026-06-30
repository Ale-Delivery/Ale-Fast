import 'package:flutter/material.dart';
import 'package:food_app/theme/app_theme.dart';
import 'package:food_app/theme/theme_colors.dart';
import 'package:food_app/navigation/buyer_navigator.dart';
import 'package:food_app/services/local_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        final hasProfile = await LocalStorageService.isProfileComplete();
        if (!mounted) return;
        if (hasProfile) {
          BuyerNavigator.home(context, clearStack: true);
        } else {
          BuyerNavigator.onboarding(context, replace: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Bottom wave decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.orangeLight, Color(0xFFFFE0CC)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(200),
                  topRight: Radius.circular(200),
                ),
              ),
            ),
          ),

          // Center logo
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Text
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -1,
                        ),
                        children: const [
                          TextSpan(text: 'F'),
                          TextSpan(
                            text: 'oo',
                            style: TextStyle(color: AppColors.orange),
                          ),
                          TextSpan(text: 'd'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FOOD DELIVERY',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 50,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
