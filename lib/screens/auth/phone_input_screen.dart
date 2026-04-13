import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool isLoading = false;

  Future<void> _onContinue() async {
    final raw = _phoneController.text.trim();

    if (raw.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final phone = '+94$raw';

    setState(() => isLoading = true);

    try {
      await supabase.auth.signInWithOtp(
        phone: phone,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: phone,
          ),
        ),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE60000).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 50,
                    color: Color(0xFFE60000),
                  ),
                ).animate().scale(
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Enter your mobile\nnumber',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 12),

              Text(
                'We will send you a verification code.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              const SizedBox(height: 40),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇱🇰', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          '+94',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: '77 123 4567',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          letterSpacing: 2,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onContinue,
                  child: isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                      : const Text('Continue'),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}