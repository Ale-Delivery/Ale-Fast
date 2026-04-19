import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // දවස Format කරගන්න (pubspec.yaml එකට intl: ^0.19.0 එකතු කරන්න)

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdayController =
      TextEditingController(); // Birthday එක පෙන්වන්න controller එකක්

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Date Picker එක පෙන්වන function එක
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // මුලින්ම පෙන්වන අවුරුද්ද
      firstDate: DateTime(1950), // තෝරන්න පුළුවන් අඩුම අවුරුද්ද
      lastDate: DateTime.now(), // උපරිම අද දිනය දක්වා පමණයි
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF7A1A), // Picker එකේ පාට
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
        // දිනය "yyyy-MM-dd" format එකට controller එකට දානවා
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Tell us a bit about yourself",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),

              // --- FULL NAME ---
              _buildLabel("FULL NAME"),
              _buildTextField(_nameController, "Enter your name"),
              const SizedBox(height: 20),

              // --- EMAIL ---
              _buildLabel("EMAIL (OPTIONAL)"),
              _buildTextField(_emailController, "example@mail.com"),
              const SizedBox(height: 20),

              // --- GENDER ---
              _buildLabel("GENDER"),
              DropdownButtonFormField<String>(
                dropdownColor: fieldColor,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(),
                value: _selectedGender,
                hint: const Text("Select Gender",
                    style: TextStyle(color: Colors.grey)),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: 20),

              // --- BIRTHDAY ---
              _buildLabel("BIRTHDAY"),
              TextField(
                controller: _birthdayController,
                readOnly: true, // Keyboard එක එන්නේ නැති වෙන්න
                style: const TextStyle(color: Colors.white),
                onTap: () =>
                    _selectDate(context), // Click කරාම calendar එක එනවා
                decoration: _fieldDecoration().copyWith(
                  hintText: "Select your birthday",
                  suffixIcon: const Icon(Icons.calendar_today,
                      color: primaryColor, size: 20),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    print(
                        "Name: ${_nameController.text}, Gender: $_selectedGender, Bday: ${_birthdayController.text}");
                  },
                  child: const Text("SAVE & CONTINUE",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Widgets
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration().copyWith(hintText: hint),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2A2A3A),
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7A1A))),
    );
  }
}
