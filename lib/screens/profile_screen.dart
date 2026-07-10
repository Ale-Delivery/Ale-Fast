import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/buyer_navigator.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _phone;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final name = await LocalStorageService.getUserName();
    final phone = await LocalStorageService.getUserPhone();

    if (phone != null) {
      final authService = AuthService();
      final profile = await authService.getUserProfile(phone);
      if (profile != null && mounted) {
        setState(() {
          _name = profile['name'] ?? name ?? 'Guest';
          _phone = phone;
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _name = name ?? 'Guest';
        _phone = phone;
        _isLoading = false;
      });
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildMenuSection('Account', [
                    _menuItem(LucideIcons.user, 'Edit Profile', () => _editProfile()),
                    _menuItem(LucideIcons.mapPin, 'Addresses', () => _manageAddresses()),
                    _menuItem(LucideIcons.heart, 'Favorites', () => BuyerNavigator.favorites(context)),
                  ]),
                  const SizedBox(height: 24),
                  _buildMenuSection('Preferences', [
                    _menuItem(LucideIcons.bell, 'Notifications', () => BuyerNavigator.notifications(context)),
                    _menuItem(LucideIcons.headphones, 'Help & Support', () => BuyerNavigator.helpSupport(context)),
                  ]),
                  const SizedBox(height: 24),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phone ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.accent),
              onPressed: _editProfile,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.cardBorder, width: 0.5),
            boxShadow: context.cardShadow,
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: context.textHint),
          ],
        ),
      ),
    );
  }

  void _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
    );
    _load();
  }

  void _manageAddresses() async {
    await BuyerNavigator.deliveryAddress(context, proceedToCheckout: false);
    _load();
  }
}
