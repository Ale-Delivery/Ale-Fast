import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  List<Map<String, dynamic>> _promos = [];
  bool _loading = true;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPromos() async {
    try {
      final data = await Supabase.instance.client
          .from('Offers')
          .select('id, code, title, description, discount_percent, discount_amount, min_order, max_discount, valid_until, is_active')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _promos = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code "$code" copied! Apply at checkout'),
        backgroundColor: AppColors.green,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Promo Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnterCode(),
                  const SizedBox(height: 24),
                  Text('Available Offers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  const SizedBox(height: 12),
                  if (_promos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.cardBorder, width: 0.5),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(LucideIcons.tag, size: 40, color: context.textHint),
                            const SizedBox(height: 12),
                            Text('No promo codes available', style: TextStyle(color: context.textMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._promos.map((promo) => _buildPromoCard(promo)),
                ],
              ),
            ),
    );
  }

  Widget _buildEnterCode() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                hintStyle: TextStyle(color: context.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final code = _codeController.text.trim();
              if (code.isNotEmpty) _applyCode(code);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final code = promo['code']?.toString() ?? '';
    final title = promo['title']?.toString() ?? '';
    final desc = promo['description']?.toString() ?? '';
    final discountPercent = promo['discount_percent'] as int?;
    final discountAmount = promo['discount_amount'] as int?;
    final minOrder = promo['min_order'] as int?;
    final maxDiscount = promo['max_discount'] as int?;
    final validUntil = promo['valid_until']?.toString();

    final discountText = discountPercent != null
        ? '$discountPercent% OFF'
        : discountAmount != null
            ? 'Rs.$discountAmount OFF'
            : 'Special Offer';

    final colors = [AppColors.accent, AppColors.green, AppColors.purple, AppColors.blue];
    final cardColor = colors[_promos.indexOf(promo) % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.tag, size: 24, color: cardColor),
                const SizedBox(height: 8),
                Text(
                  discountText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cardColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (minOrder != null) ...[
                        Text('Min: Rs.$minOrder', style: TextStyle(fontSize: 11, color: context.textMuted)),
                        const SizedBox(width: 8),
                      ],
                      if (maxDiscount != null)
                        Text('Max: Rs.$maxDiscount', style: TextStyle(fontSize: 11, color: context.textMuted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _applyCode(code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cardColor, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
