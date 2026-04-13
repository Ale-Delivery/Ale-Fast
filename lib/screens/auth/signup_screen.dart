import 'package:flutter/material.dart';
import 'package:aleeapp/widgets/auth_header.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          const AuthHeader(
            title: "Sign Up",
            subtitle: "Please sign up to get started",
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _input("NAME"),
                  const SizedBox(height: 10),
                  _input("EMAIL"),
                  const SizedBox(height: 10),
                  _input("PASSWORD", isPassword: true),
                  const SizedBox(height: 10),
                  _input("RE-TYPE PASSWORD", isPassword: true),

                  const SizedBox(height: 20),

                  _button("SIGN UP"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button(String text) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF7A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
        child: Text(text),
      ),
    );
  }
}
