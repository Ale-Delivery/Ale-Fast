import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool isLoading = false;

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();

    if (token.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.verifyOTP(
        phone: widget.phoneNumber,
        token: token,
        type: OtpType.sms,
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('users').upsert({
          'id': user.id,
          'phone': widget.phoneNumber,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful'),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: go to home screen
        Navigator.popUntil(context, (route) => route.isFirst);
      }
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
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await supabase.auth.signInWithOtp(
        phone: widget.phoneNumber,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              'Enter the code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendOtp,
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}