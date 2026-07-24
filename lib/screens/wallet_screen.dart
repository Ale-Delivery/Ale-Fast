import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';
import 'transactions_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final wallet = await Supabase.instance.client
          .from('Wallet')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      final txns = await Supabase.instance.client
          .from('Wallet_Transactions')
          .select('id, type, amount, description, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _balance = (wallet?['balance'] as num?)?.toDouble() ?? 0;
          _recentTransactions = List<Map<String, dynamic>>.from(txns);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _topUp() async {
    final amountController = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Top Up Wallet', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter amount to add', style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [100, 200, 500, 1000].map((amt) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        amountController.text = amt.toString();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rs.$amt',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text);
              if (amt != null && amt > 0) Navigator.pop(ctx, amt);
            },
            child: const Text('Top Up', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == null || result <= 0) return;

    final userId = await LocalStorageService.getUserId();
    if (userId == null) return;

    try {
      // Ensure wallet exists
      final existing = await Supabase.instance.client
          .from('Wallet')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await Supabase.instance.client.from('Wallet').insert({
          'user_id': userId,
          'balance': result,
        });
      } else {
        await Supabase.instance.client.rpc('increment_wallet_balance', params: {
          'p_user_id': userId,
          'p_amount': result,
        });
      }

      await Supabase.instance.client.from('Wallet_Transactions').insert({
        'user_id': userId,
        'type': 'topup',
        'amount': result,
        'description': 'Wallet top up',
      });

      _loadWallet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rs.${result.toStringAsFixed(0)} added to wallet'), backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      debugPrint('Top up error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  _buildTopUpOptions(),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.green, AppColors.green.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.green.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.wallet, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text('ALE FAST Wallet', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Rs.${_balance.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Top Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [100, 200, 500, 1000].map((amt) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: _topUp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.cardBorder, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.plus, size: 18, color: AppColors.green),
                        const SizedBox(height: 6),
                        Text('Rs.$amt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _topUp,
            icon: const Icon(LucideIcons.creditCard, size: 18),
            label: const Text('Custom Amount', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
              child: Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder, width: 0.5),
            ),
            child: Center(
              child: Text('No transactions yet', style: TextStyle(color: context.textMuted)),
            ),
          )
        else
          ..._recentTransactions.map((txn) => _buildTransactionItem(txn)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn) {
    final type = txn['type']?.toString() ?? '';
    final amount = (txn['amount'] as num?)?.toDouble() ?? 0;
    final desc = txn['description']?.toString() ?? '';
    final isCredit = type == 'topup' || type == 'refund' || type == 'reward';
    final dateStr = txn['created_at'] != null
        ? '${DateTime.parse(txn['created_at']).day}/${DateTime.parse(txn['created_at']).month}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.green : AppColors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              size: 18,
              color: isCredit ? AppColors.green : AppColors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                Text(dateStr, style: TextStyle(fontSize: 12, color: context.textMuted)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}Rs.${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCredit ? AppColors.green : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
