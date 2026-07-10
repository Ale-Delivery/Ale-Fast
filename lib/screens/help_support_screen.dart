import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _phone = '+94771234567';
  static const String _email = 'support@alefast.com';
  static const String _whatsapp = '+94771234567';

  static const List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I track my order?',
      'answer':
          'Go to Order History and tap on any active order to see real-time tracking.',
    },
    {
      'question': 'Can I cancel my order?',
      'answer':
          "Yes, you can cancel orders that are still in 'Pending' or 'Accepted' status.",
    },
    {
      'question': 'How do I apply a promo code?',
      'answer':
          'Enter your promo code at checkout. The discount will be applied automatically.',
    },
    {
      'question': 'How do I change my delivery address?',
      'answer':
          'Go to Profile > Delivery Address to add, edit, or delete saved addresses.',
    },
    {
      'question': 'Is cash on delivery available?',
      'answer': 'Yes, we accept cash on delivery for all orders.',
    },
    {
      'question': 'How do I rate a restaurant?',
      'answer':
          "After your order is delivered, go to Order History and tap 'Rate' on the completed order.",
    },
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textPrimary;
    final mutedColor = context.textMuted;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: context.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.bg, AppColors.darkCard]
                        : [Colors.white, const Color(0xFFF8F9FA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('FAQ', textColor, mutedColor),
                const SizedBox(height: 12),
                ...List.generate(_faqItems.length, (i) {
                  final item = _faqItems[i];
                  return _buildFaqTile(
                    context,
                    question: item['question']!,
                    answer: item['answer']!,
                    isDark: isDark,
                  ).animate().fadeIn(duration: 300.ms, delay: (i * 60).ms).slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 350.ms,
                        curve: Curves.easeOutCubic,
                      );
                }),
                const SizedBox(height: 28),
                _buildSectionHeader('CONTACT US', textColor, mutedColor),
                const SizedBox(height: 12),
                _buildContactCard(
                  context,
                  isDark: isDark,
                  children: [
                    _buildContactTile(
                      context,
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.green,
                      title: 'Phone',
                      subtitle: '+94 77 123 4567',
                      onTap: () => _launchUrl('tel:$_phone'),
                    ),
                    _buildDivider(isDark),
                    _buildContactTile(
                      context,
                      icon: Icons.email_rounded,
                      iconColor: AppColors.blue,
                      title: 'Email',
                      subtitle: 'support@alefast.com',
                      onTap: () => _launchUrl('mailto:$_email'),
                    ),
                    _buildDivider(isDark),
                    _buildContactTile(
                      context,
                      icon: Icons.chat_rounded,
                      iconColor: const Color(0xFF25D366),
                      title: 'WhatsApp',
                      subtitle: '+94 77 123 4567',
                      onTap: () => _launchUrl(
                          'https://wa.me/$_whatsapp'),
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms, delay: 200.ms).slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 28),
                _buildSectionHeader('ABOUT', textColor, mutedColor),
                const SizedBox(height: 12),
                _buildAboutCard(context, isDark)
                    .animate()
                    .fadeIn(duration: 350.ms, delay: 280.ms)
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor, Color mutedColor) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: mutedColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context, {
    required String question,
    required String answer,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          iconColor: AppColors.orange,
          collapsedIconColor: context.textMuted,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.help_outline_rounded,
                color: AppColors.orange, size: 20),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: context.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: context.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 80,
      color: isDark
          ? AppColors.border.withValues(alpha: 0.4)
          : AppColors.lightBorder.withValues(alpha: 0.6),
    );
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Alee Buyer App',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 13,
              color: context.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your favourite food, delivered fast.',
            style: TextStyle(
              fontSize: 13,
              color: context.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
