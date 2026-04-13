import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, String>> data = [
    {
      "title": "All your favorites",
      "desc": "Get all your loved foods in one place, you just place the order we do the rest",
      "image": "https://cdn-icons-png.flaticon.com/512/1046/1046784.png"
    },
    {
      "title": "Order from chosen chef",
      "desc": "Get all your loved foods in one place, you just place the order we do the rest",
      "image": "https://cdn-icons-png.flaticon.com/512/2921/2921822.png"
    },
    {
      "title": "Free delivery offers",
      "desc": "Get all your loved foods in one place, you just place the order we do the rest",
      "image": "https://cdn-icons-png.flaticon.com/512/1046/1046857.png"
    },
  ];

  void nextPage() {
    if (currentPage < data.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: currentPage == index ? 10 : 6,
      height: currentPage == index ? 10 : 6,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.orange : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemCount: data.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        data[index]["image"]!,
                        height: 220,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        data[index]["title"]!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 🔘 DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              data.length,
              (index) => buildDot(index),
            ),
          ),

          const SizedBox(height: 20),

          // 🔘 BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  currentPage == data.length - 1 ? "GET STARTED" : "NEXT",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Skip"),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}