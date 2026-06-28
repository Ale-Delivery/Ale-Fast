import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../screens/delivery_address_screen.dart';

const _primaryColor = Color(0xFFFF6B35);
const _accentColor = Color(0xFFFF8A00);
const _lightBg = Color(0xFFF9FAFC);
const _cardBg = Colors.white;
const _darkInk = Color(0xFF1E1E2C);
const _textMuted = Color(0xFF7D8491);

class ProfileSetupScreen extends StatefulWidget {
  final String? existingUserId;
  final String? existingName;
  final String? existingEmail;
  final String? existingGender;
  final String? existingBirthday;

  const ProfileSetupScreen({
    super.key,
    this.existingUserId,
    this.existingName,
    this.existingEmail,
    this.existingGender,
    this.existingBirthday,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  final _authService = AuthService();
  bool _isLoading = false;

  bool get _isEditing => widget.existingUserId != null;

  final List<Map<String, dynamic>> _genderOptions = [
    {'value': 'Male', 'icon': Icons.male_rounded, 'label': 'Male'},
    {'value': 'Female', 'icon': Icons.female_rounded, 'label': 'Female'},
    {'value': 'Other', 'icon': Icons.transgender_rounded, 'label': 'Other'},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E1E2C),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your first and last name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Only require gender/birthday if they are shown (not editing, or editing with existing value)
    if ((!_isEditing || _selectedGender != null) && _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if ((!_isEditing || _selectedDate != null) && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your birthday'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = await LocalStorageService.getUserPhone();
      final fullName = "$firstName $lastName";
      
      final userId = await _authService.saveUserProfile(
        name: fullName,
        email: _emailController.text.trim(),
        gender: _selectedGender!,
        birthday: _selectedDate!.toIso8601String().split('T')[0],
        phone: phone,
        existingUserId: widget.existingUserId,
      );

      await LocalStorageService.setProfileComplete(
        userId: userId,
        name: fullName,
        phone: phone,
      );

      if (mounted) {
        if (_isEditing) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DeliveryAddressScreen(proceedToCheckout: false),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingName != null) {
      final parts = widget.existingName!.split(' ');
      _firstNameController.text = parts.first;
      _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    if (widget.existingEmail != null) {
      _emailController.text = widget.existingEmail!;
    }
    if (widget.existingGender != null) {
      _selectedGender = widget.existingGender!;
    }
    if (widget.existingBirthday != null) {
      _selectedDate = DateTime.tryParse(widget.existingBirthday!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: _darkInk, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Text(
                _isEditing ? "Edit Profile" : "Complete Profile",
                style: TextStyle(
                  color: _darkInk,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let us know you better to deliver your cravings.",
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),

              // First Name & Last Name Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("FIRST NAME"),
                        _buildTextField(
                          controller: _firstNameController,
                          hintText: "First name",
                          icon: Icons.person_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("LAST NAME"),
                        _buildTextField(
                          controller: _lastNameController,
                          hintText: "Last name",
                          icon: Icons.person_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Email Field — show if not editing, or if editing and has value
              if (!_isEditing || (widget.existingEmail != null && widget.existingEmail!.isNotEmpty)) ...[
                _buildFieldLabel("EMAIL (OPTIONAL)"),
                _buildTextField(
                  controller: _emailController,
                  hintText: "Enter your email address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
              ],

              // Gender Selector — show if not editing, or if editing and has value
              if (!_isEditing || _selectedGender != null) ...[
                _buildFieldLabel("GENDER"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _genderOptions.map((opt) {
                  final isSelected = _selectedGender == opt['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = opt['value']),
                      child: Container(
                        margin: EdgeInsets.only(
                          left: opt['value'] == 'Male' ? 0 : 8,
                          right: opt['value'] == 'Other' ? 0 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? _primaryColor.withOpacity(0.08) : _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? _primaryColor : Colors.grey.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              opt['icon'],
                              color: isSelected ? _primaryColor : _darkInk.withOpacity(0.7),
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              opt['label'],
                              style: TextStyle(
                                color: isSelected ? _primaryColor : _darkInk.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ], // close gender conditional

              // Birthday Field — show if not editing, or if editing and has value
              if (!_isEditing || _selectedDate != null) ...[
                _buildFieldLabel("BIRTHDAY"),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: _textMuted, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? "Select your birthday"
                              : _selectedDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: _selectedDate == null ? _textMuted : _darkInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_month_rounded, color: _primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ], // close birthday conditional

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accentColor, _primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "SAVE & CONTINUE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7D8491),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: _darkInk,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9EAE),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9E9EAE), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}