import 'package:flutter/material.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: "Log In",
            subtitle: "Please sign in to your existing account",
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CustomInput(hint: "EMAIL"),
                  const SizedBox(height: 14),
                  const CustomInput(hint: "PASSWORD", isPassword: true),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Remember me"),
                      Text("Forgot Password", style: TextStyle(color: Colors.orange)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  CustomButton(
                    text: "LOG IN",
                    onPressed: () {},
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? SIGN UP",
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}