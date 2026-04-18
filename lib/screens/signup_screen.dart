import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_app/theme/app_theme.dart';
import 'package:food_app/widgets/dark_widgets.dart';
import 'package:food_app/screens/verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Sign Up',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please sign up to get started',
                style:
                    GoogleFonts.nunito(fontSize: 13, color: Colors.white38),
              ),
              const SizedBox(height: 28),

              DarkTextField(
                  label: 'Name',
                  hint: 'john doe',
                  controller: _nameController),
              DarkTextField(
                label: 'Email',
                hint: 'example@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              DarkTextField(
                label: 'Password',
                hint: '••••••••••',
                isPassword: true,
                controller: _passwordController,
              ),
              DarkTextField(
                label: 'Re-type Password',
                hint: '••••••••••',
                isPassword: true,
                controller: _confirmController,
              ),

              const SizedBox(height: 8),

              OrangeButton(
                text: 'SIGN UP',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VerificationScreen()),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: Colors.white38),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        const TextSpan(
                          text: 'LOG IN',
                          style: TextStyle(
                              color: AppTheme.orange,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
