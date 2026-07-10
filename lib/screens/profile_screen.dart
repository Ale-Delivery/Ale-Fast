import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../navigation/buyer_navigator.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _phone;
  String? _email;
  String? _gender;
  String? _birthday;
  String? _addressLabel;
  String? _userId;
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
    final address = await LocalStorageService.getDeliveryAddress();
    
    final savedUserId = await LocalStorageService.getUserId();

    if (phone != null) {
      final authService = AuthService();
      final profile = await authService.getUserProfile(phone);
      if (profile != null && mounted) {
        setState(() {
          _name = profile['name'] ?? name ?? 'Guest';
          _phone = phone;
          _email = profile['email'];
          _gender = profile['gender'];
          _birthday = profile['birthday'];
          _addressLabel = address?['label'];
          _userId = profile['id']?.toString() ?? savedUserId;
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _name = name ?? 'Guest';
        _phone = phone;
        _userId = savedUserId;
        _addressLabel = address?['label'];
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out? You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = context.textPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
          title: Text(
          'My Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
          leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.orange,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // --- User Profile Header Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.darkCard, AppColors.darkEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkCard.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.avatar,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 3),
                          ),
                          child: Center(
                            child: Text(
                              (_name ?? 'G').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name ?? 'Guest User',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_phone != null)
                                Row(
                                  children: [
                                    Icon(Icons.phone_rounded, color: Colors.white.withValues(alpha: 0.6), size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _phone!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Account Details Section (Email, Gender, Birthday) ---
                  if (_email != null || _gender != null || _birthday != null) ...[
                    _buildSectionHeader('Account Info'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_email != null && _email!.isNotEmpty)
                            _buildInfoRow(Icons.email_outlined, 'Email Address', _email!),
                          if (_gender != null && _gender!.isNotEmpty)
                            _buildInfoRow(Icons.face_outlined, 'Gender', _gender!),
                          if (_birthday != null && _birthday!.isNotEmpty)
                            _buildInfoRow(Icons.cake_outlined, 'Birthday', _birthday!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // --- Menu / Actions Section ---
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal info',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileSetupScreen(
                            existingUserId: _userId,
                            existingName: _name,
                            existingEmail: _email,
                            existingGender: _gender,
                            existingBirthday: _birthday,
                          ),
                        ),
                      ).then((_) => _load());
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Order History',
                    subtitle: 'View your previous orders',
                    onTap: () => BuyerNavigator.orderHistory(context),
                  ),
                  _buildMenuTile(
                    icon: Icons.location_on_rounded,
                    title: 'Delivery Address',
                    subtitle: _addressLabel ?? 'Manage locations',
                    onTap: () async {
                      await BuyerNavigator.deliveryAddress(
                        context,
                        proceedToCheckout: false,
                      );
                      _load();
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Help & Support',
                    subtitle: '24/7 customer care service',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Support coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // --- Appearance Section ---
                  _buildSectionHeader('Appearance'),
                  const SizedBox(height: 12),
                  _buildThemeSelector(),
                  const SizedBox(height: 32),

                  // --- Logout Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                      label: const Text(
                        'Log out',
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.red.withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.hint,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final textColor = context.textPrimary;
    final mutedColor = context.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: mutedColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = context.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.orange, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: context.textMuted,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
        color: context.textHint,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeProvider = context.watch<ThemeProvider>();
    final current = themeProvider.themeMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _themeOption(
            icon: Icons.light_mode_rounded,
            title: 'Light',
            selected: current == ThemeMode.light,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          _themeOption(
            icon: Icons.dark_mode_rounded,
            title: 'Dark',
            selected: current == ThemeMode.dark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
          _themeOption(
            icon: Icons.phone_android_rounded,
            title: 'System',
            selected: current == ThemeMode.system,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.orange : context.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.orange : context.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 22),
          ],
        ),
      ),
    );
  }
}
