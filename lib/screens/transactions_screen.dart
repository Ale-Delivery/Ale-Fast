import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../services/local_storage_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      var query = Supabase.instance.client
          .from('Wallet_Transactions')
          .select('id, type, amount, description, created_at')
          .eq('user_id', userId);

      if (_filter != 'all') {
        query = query.eq('type', _filter);
      }

      final data = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2))
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.receipt, size: 48, color: context.textHint),
                            const SizedBox(height: 12),
                            Text('No transactions found', style: TextStyle(color: context.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                        itemCount: _transactions.length,
                        itemBuilder: (context, i) => _buildTransactionItem(_transactions[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Top Up', 'value': 'topup'},
      {'label': 'Payment', 'value': 'payment'},
      {'label': 'Refund', 'value': 'refund'},
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isActive = _filter == f['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _filter = f['value']!);
              _loadTransactions();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.green.withValues(alpha: 0.1) : context.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? AppColors.green : context.cardBorder,
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.green : context.textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn) {
    final type = txn['type']?.toString() ?? '';
    final amount = (txn['amount'] as num?)?.toDouble() ?? 0;
    final desc = txn['description']?.toString() ?? '';
    final isCredit = type == 'topup' || type == 'refund' || type == 'reward';
    final dateStr = txn['created_at'] != null
        ? DateTime.parse(txn['created_at']).toLocal().toString().substring(0, 16).replaceAll('T', ' ')
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.green : AppColors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              size: 20,
              color: isCredit ? AppColors.green : AppColors.red,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                const SizedBox(height: 3),
                Text(dateStr, style: TextStyle(fontSize: 12, color: context.textMuted)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}Rs.${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isCredit ? AppColors.green : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
