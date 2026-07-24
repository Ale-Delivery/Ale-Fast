import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _methods = [];
  bool _loading = true;
  String _selectedMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('Payment_Methods')
          .select('id, type, card_number, card_holder, expiry, is_default')
          .eq('user_id', userId)
          .order('is_default', ascending: false);
      if (mounted) {
        setState(() {
          _methods = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCard() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final numberCtrl = TextEditingController();
        final holderCtrl = TextEditingController();
        final expiryCtrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Card number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: holderCtrl, textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: 'Card holder name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: expiryCtrl, keyboardType: TextInputType.datetime,
                decoration: InputDecoration(hintText: 'MM/YY', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
            TextButton(
              onPressed: () {
                if (numberCtrl.text.isNotEmpty && holderCtrl.text.isNotEmpty) {
                  Navigator.pop(ctx, {
                    'number': numberCtrl.text,
                    'holder': holderCtrl.text,
                    'expiry': expiryCtrl.text,
                  });
                }
              },
              child: const Text('Add', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('Payment_Methods').insert({
        'user_id': userId,
        'type': 'card',
        'card_number': result['number'],
        'card_holder': result['holder'],
        'expiry': result['expiry'],
        'is_default': _methods.isEmpty,
      });
      _loadMethods();
    } catch (_) {}
  }

  Future<void> _deleteMethod(String id) async {
    try {
      await Supabase.instance.client.from('Payment_Methods').delete().eq('id', id);
      _loadMethods();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
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
                  _buildCashOption(),
                  const SizedBox(height: 12),
                  _buildWalletOption(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
                      GestureDetector(
                        onTap: _addCard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.plus, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text('Add Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_methods.isEmpty)
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
                            Icon(LucideIcons.creditCard, size: 40, color: context.textHint),
                            const SizedBox(height: 12),
                            Text('No cards saved', style: TextStyle(color: context.textMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._methods.map((m) => _buildCardOption(m)),
                ],
              ),
            ),
    );
  }

  Widget _buildCashOption() {
    final isSelected = _selectedMethod == 'cash';
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = 'cash'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.06) : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.banknote, color: AppColors.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  Text('Pay when you receive', style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption() {
    final isSelected = _selectedMethod == 'wallet';
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = 'wallet'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.06) : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.wallet, color: AppColors.green, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALE FAST Wallet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  Text('Pay from wallet balance', style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOption(Map<String, dynamic> method) {
    final cardNumber = method['card_number']?.toString() ?? '';
    final masked = cardNumber.length >= 4 ? '•••• ${cardNumber.substring(cardNumber.length - 4)}' : cardNumber;
    final holder = method['card_holder']?.toString() ?? '';
    final expiry = method['expiry']?.toString() ?? '';
    final isSelected = _selectedMethod == method['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method['id']),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete card?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
              TextButton(
                onPressed: () { _deleteMethod(method['id']); Navigator.pop(ctx); },
                child: const Text('Delete', style: TextStyle(color: AppColors.red)),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.06) : context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.creditCard, color: AppColors.blue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(masked, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary, letterSpacing: 2)),
                  const SizedBox(height: 2),
                  Text('$holder · Exp $expiry', style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }
}
