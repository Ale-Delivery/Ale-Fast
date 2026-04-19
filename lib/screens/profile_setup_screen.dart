import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
// ඔයාගේ project එකේ නම 'alee_app' නම් මේක හරි. නැත්නම් ඒක වෙනස් කරගන්න.
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdayController = TextEditingController(); 
  
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  
  bool _isLoading = false; // Loading animation එක පෙන්නන්න

  // Date Picker එක පෙන්වන function එක
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1950),   
      lastDate: DateTime.now(),    
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF7A1A), // Calendar එකේ පාට
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A3A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7A1A);
    const bgColor = Color(0xFF1E1E2E);
    const fieldColor = Color(0xFF2A2A3A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Complete Profile",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tell us a bit about yourself", 
                style: TextStyle(color: Colors.grey, fontSize: 16)
              ),
              const SizedBox(height: 40),

              // --- FULL NAME ---
              _buildLabel("FULL NAME"),
              _buildTextField(_nameController, "Enter your name"),
              const SizedBox(height: 20),

              // --- EMAIL ---
              _buildLabel("EMAIL (OPTIONAL)"),
              _buildTextField(_emailController, "example@mail.com", TextInputType.emailAddress),
              const SizedBox(height: 20),

              // --- GENDER ---
              _buildLabel("GENDER"),
              DropdownButtonFormField<String>(
                dropdownColor: fieldColor,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(),
                value: _selectedGender,
                hint: const Text("Select Gender", style: TextStyle(color: Colors.grey)),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 20),

              // --- BIRTHDAY ---
              _buildLabel("BIRTHDAY"),
              TextField(
                controller: _birthdayController,
                readOnly: true, 
                style: const TextStyle(color: Colors.white),
                onTap: () => _selectDate(context), 
                decoration: _fieldDecoration().copyWith(
                  hintText: "Select your birthday",
                  suffixIcon: const Icon(Icons.calendar_today, color: primaryColor, size: 20),
                ),
              ),
              const SizedBox(height: 40),

              // --- SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : () async {
                    // නම ගහලද කියලා චෙක් කරනවා
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your full name', style: TextStyle(color: Colors.white)), 
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() { _isLoading = true; });

                    try {
                      final authService = AuthService();
                      await authService.saveUserProfile(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        gender: _selectedGender,
                        // Birthday එක තෝරලා නැත්නම් null යවනවා
                        birthday: _birthdayController.text.isEmpty ? null : _birthdayController.text,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile Saved Successfully! 🎉', style: TextStyle(color: Colors.white)), 
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // TODO: මේකෙන් පස්සේ Home Screen එකට යවන්න පුළුවන් (Home screen හැදුවම මේක uncomment කරමු)
                        // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e', style: const TextStyle(color: Colors.white)), 
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() { _isLoading = false; });
                      }
                    }
                  },
                  child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text("SAVE & CONTINUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable Widgets --- 
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration().copyWith(hintText: hint),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2A2A3A),
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF7A1A))),
    );
  }
}