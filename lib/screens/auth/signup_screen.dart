import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../home/main_navigation_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  void _onSignUp() {
    if (_formKey.currentState!.validate()) {
      // Proceed to home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Complete your\nprofile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 12),
                Text(
                  'Just a few more details to get you started.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 40),
                
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Kamal Perera',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => 
                    value == null || value.isEmpty ? 'Please enter your name' : null,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 20),
                
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'kamal@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSignUp,
                    child: const Text('Create Account', style: TextStyle(fontSize: 16)),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
