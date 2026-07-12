import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/buyer_navigator.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _phone;
  String? _email;
  String? _gender;
  String? _birthday;
  String? _userId;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _editGender;
  DateTime? _editBirthday;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final name = await LocalStorageService.getUserName();
    final phone = await LocalStorageService.getUserPhone();
    final savedUserId = await LocalStorageService.getUserId();

    if (phone != null) {
      final profile = await _authService.getUserProfile(phone);
      if (profile != null && mounted) {
        setState(() {
          _name = profile['name'] ?? name ?? 'Guest';
          _phone = phone;
          _email = profile['email'];
          _gender = profile['gender'];
          _birthday = profile['birthday'];
          _userId = profile['id']?.toString() ?? savedUserId;
          _isLoading = false;
        });
        _initControllers();
        return;
      }
    }

    if (mounted) {
      setState(() {
        _name = name ?? 'Guest';
        _phone = phone;
        _userId = savedUserId;
        _isLoading = false;
      });
      _initControllers();
    }
  }

  void _initControllers() {
    _nameController.text = _name ?? '';
    _emailController.text = _email ?? '';
    _editGender = _gender;
    if (_birthday != null) {
      _editBirthday = DateTime.tryParse(_birthday!);
    }
  }

  void _startEditing() {
    _initControllers();
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.saveUserProfile(
        name: fullName,
        email: _emailController.text.trim(),
        gender: _editGender ?? '',
        birthday: _editBirthday?.toIso8601String().split('T')[0] ?? '',
        phone: _phone,
        existingUserId: _userId,
      );

      await LocalStorageService.setProfileComplete(
        userId: _userId ?? '',
        name: fullName,
        phone: _phone,
      );

      if (mounted) {
        setState(() {
          _name = fullName;
          _email = _emailController.text.trim();
          _gender = _editGender;
          _birthday = _editBirthday?.toIso8601String().split('T')[0];
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editBirthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _editBirthday = picked);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await LocalStorageService.clearSession();
    if (!mounted) return;
    BuyerNavigator.onboarding(context, replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: Text('Cancel', style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  if (_isEditing) _buildEditForm() else _buildProfileDetails(),
                  const SizedBox(height: 24),
                  if (!_isEditing) ...[
                    _buildReferralSection(),
                    const SizedBox(height: 24),
                    _buildMenuSection('Preferences', [
                      _buildThemeSwitcher(),
                      _menuItem(LucideIcons.bell, 'Notifications', () => BuyerNavigator.notifications(context)),
                      _menuItem(LucideIcons.headphones, 'Help & Support', () => BuyerNavigator.helpSupport(context)),
                    ]),
                    const SizedBox(height: 24),
                  ],
                  _buildMenuSection('', [
                    _menuItem(LucideIcons.logOut, 'Log Out', _logout, isDestructive: true),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = (_name ?? 'U').substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.avatar,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name ?? 'User',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _phone ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: context.textMuted),
                ),
              ],
            ),
          ),
          if (!_isEditing)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.accent),
                onPressed: _startEditing,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return _buildMenuSection('Details', [
      _detailItem(LucideIcons.user, 'Name', _name ?? '-'),
      _detailItem(LucideIcons.phone, 'Phone', _phone ?? '-'),
      _detailItem(LucideIcons.mail, 'Email', _email ?? '-'),
      _detailItem(LucideIcons.user, 'Gender', _gender ?? '-'),
      _detailItem(LucideIcons.calendar, 'Birthday', _birthday ?? '-'),
    ]);
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EDIT PROFILE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),
          _buildField(label: 'Name', controller: _nameController, icon: LucideIcons.user),
          const SizedBox(height: 16),
          _buildField(label: 'Email', controller: _emailController, icon: LucideIcons.mail, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildGenderSelector(),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: _isSaving ? null : _saveProfile,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: _isSaving
                      ? const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)])
                      : AppGradients.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isSaving ? null : AppGradients.glow,
                ),
                alignment: Alignment.center,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: context.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    final options = ['Male', 'Female', 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((g) {
            final isSelected = _editGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _editGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : context.cardBorder,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.accent : context.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final dateStr = _editBirthday != null
        ? '${_editBirthday!.day}/${_editBirthday!.month}/${_editBirthday!.year}'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BIRTHDAY',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 18, color: context.textMuted),
                const SizedBox(width: 12),
                Text(
                  dateStr.isEmpty ? 'Select date' : dateStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: dateStr.isEmpty ? context.textHint : context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.8),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.cardBorder, width: 0.5),
            boxShadow: context.cardShadow,
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildThemeSwitcher() {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.palette, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Theme',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _themeBtn(LucideIcons.sun, 'Light', ThemeMode.light, currentMode, themeProvider),
                _themeBtn(LucideIcons.moon, 'Dark', ThemeMode.dark, currentMode, themeProvider),
                _themeBtn(LucideIcons.monitor, 'System', ThemeMode.system, currentMode, themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeBtn(IconData icon, String label, ThemeMode mode, ThemeMode current, ThemeProvider provider) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () => provider.setThemeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : context.textMuted,
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? AppColors.red : context.textPrimary;
    final iconColor = isDestructive ? AppColors.red : AppColors.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: context.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection() {
    final code = _phone ?? 'USER';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refer & Earn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Share your code, earn Rs.100 each',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Referral code copied!'),
                        backgroundColor: AppColors.green,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
