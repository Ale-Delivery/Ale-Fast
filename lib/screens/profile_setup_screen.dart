import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_app/theme/app_theme.dart';
import 'package:food_app/widgets/dark_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:food_app/screens/home_screen.dart'; // Meka passe hadamu

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Supabase Auth metadata ekata user ge name eka save karanawa
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': name,
            'email_address': email, // Email eka awashya nam witharak denawa
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Setup Successful! 🎉'), 
            backgroundColor: Colors.green
          ),
        );

        // TODO: Api meka anthimata Home Screen ekata yanawidiyata hadamu
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (_) => const HomeScreen()),
        //   (route) => false,
        // );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              const SizedBox(height: 40),
              Text(
                'Complete Profile',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us a bit about yourself',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.white38),
              ),
              const SizedBox(height: 40),

              DarkTextField(
                label: 'Full Name',
                hint: 'Wathila Wijesinghe',
                controller: _nameController,
              ),
              DarkTextField(
                label: 'Email (Optional)',
                hint: 'example@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.orange))
                  : OrangeButton(
                      text: 'SAVE & CONTINUE',
                      onPressed: _saveProfile,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}