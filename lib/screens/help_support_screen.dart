import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _phone = '+94771234567';
  static const String _email = 'support@alefast.com';

  static const List<Map<String, String>> _faqItems = [
    {
      'question': 'How do I track my order?',
      'answer': 'Go to Order History and tap on any active order to see real-time tracking.',
    },
    {
      'question': 'Can I cancel my order?',
      'answer': "Yes, you can cancel orders that are still in 'Pending' or 'Accepted' status.",
    },
    {
      'question': 'How do I apply a promo code?',
      'answer': 'Enter your promo code at checkout. The discount will be applied automatically.',
    },
    {
      'question': 'How do I change my delivery address?',
      'answer': 'Go to Profile > Addresses to add, edit, or delete saved addresses.',
    },
    {
      'question': 'Is cash on delivery available?',
      'answer': 'Yes, we accept cash on delivery for all orders.',
    },
    {
      'question': 'How do I rate a restaurant?',
      'answer': "After your order is delivered, go to Order History and tap 'Rate' on the completed order.",
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
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ
            _sectionHeader('FAQ'),
            const SizedBox(height: 12),
            ...List.generate(_faqItems.length, (i) {
              final item = _faqItems[i];
              return _buildFaqCard(
                question: item['question']!,
                answer: item['answer']!,
              );
            }),
            const SizedBox(height: 32),

            // Contact
            _sectionHeader('Contact Us'),
            const SizedBox(height: 12),
            _contactCard(
              icon: LucideIcons.phone,
              label: 'Phone',
              value: _phone,
              onTap: () => _launchUrl('tel:$_phone'),
            ),
            const SizedBox(height: 10),
            _contactCard(
              icon: LucideIcons.mail,
              label: 'Email',
              value: _email,
              onTap: () => _launchUrl('mailto:$_email'),
            ),
            const SizedBox(height: 32),

            // About
            _sectionHeader('About'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.cardBorder, width: 0.5),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALE FAST',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fast delivery, right to your door. Order food, book rides, and send parcels with ease.',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFaqCard({required String question, required String answer}) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 0.5),
          boxShadow: context.cardShadow,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            iconColor: AppColors.accent,
            collapsedIconColor: context.textMuted,
            title: Text(
              question,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            children: [
              Text(
                answer,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder, width: 0.5),
            boxShadow: context.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: context.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
