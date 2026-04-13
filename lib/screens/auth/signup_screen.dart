import 'package:flutter/material.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: "Sign Up",
            subtitle: "Please sign up to get started",
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CustomInput(hint: "NAME"),
                  const SizedBox(height: 14),

                  const CustomInput(hint: "EMAIL"),
                  const SizedBox(height: 14),

                  const CustomInput(hint: "PASSWORD", isPassword: true),
                  const SizedBox(height: 14),

                  const CustomInput(hint: "RE-TYPE PASSWORD", isPassword: true),

                  const SizedBox(height: 20),

                  CustomButton(
                    text: "SIGN UP",
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}