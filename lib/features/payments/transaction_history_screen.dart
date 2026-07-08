import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;

  String _selectedOperator = 'Tous';
  String _selectedPeriod = 'Tous';

  final List<String> _operators = ['Tous', 'Orange Money', 'Moov Money', 'Wave'];
  final List<String> _periods = ['Tous', 'Aujourd\'hui', '7 derniers jours', '30 derniers jours'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });
    final list = await ref.read(paymentsRepositoryProvider).getTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = list;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> list = List.from(_allTransactions);

    // Operator filter
    if (_selectedOperator != 'Tous') {
      list = list.where((tx) => tx['operator'] == _selectedOperator).toList();
    }

    // Period filter
    final now = DateTime.now();
    if (_selectedPeriod == 'Aujourd\'hui') {
      list = list.where((tx) {
        final txDate = DateTime.parse(tx['timestamp']);
        return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
      }).toList();
    } else if (_selectedPeriod == '7 derniers jours') {
      final weekAgo = now.subtract(const Duration(days: 7));
      list = list.where((tx) {
        final txDate = DateTime.parse(tx['timestamp']);
        return txDate.isAfter(weekAgo);
      }).toList();
    } else if (_selectedPeriod == '30 derniers jours') {
      final monthAgo = now.subtract(const Duration(days: 30));
      list = list.where((tx) {
        final txDate = DateTime.parse(tx['timestamp']);
        return txDate.isAfter(monthAgo);
      }).toList();
    }

    setState(() {
      _filteredTransactions = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de Transactions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Paiements effectués (${_filteredTransactions.length})',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = _filteredTransactions[index];
                              return _buildTransactionCard(tx);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operator Filter Scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Opérateurs Mobile money',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: _operators.map((op) {
                final isSelected = _selectedOperator == op;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOperator = op;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      op,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Period Filter Scroll
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Période',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: _periods.map((per) {
                final isSelected = _selectedPeriod == per;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = per;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      per,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final name = tx['beneficiaryName'] ?? 'Bénéficiaire';
    final amount = tx['amount'] ?? 0.0;
    final op = tx['operator'] ?? 'Mobile Money';
    final timestamp = tx['timestamp'] ?? DateTime.now().toIso8601String();
    
    final formattedAmount = NumberFormat.currency(symbol: 'XOF', decimalDigits: 0).format(amount);
    final date = DateTime.parse(timestamp);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    Color opColor = AppColors.orangeMoney;
    if (op.toLowerCase().contains('moov')) opColor = AppColors.moovMoney;
    if (op.toLowerCase().contains('wave')) opColor = AppColors.wave;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: opColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.send_rounded, color: opColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- $formattedAmount',
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error),
              ),
              const SizedBox(height: 2),
              Text(
                op.split(' ')[0],
                style: GoogleFonts.spaceGrotesk(fontSize: 9, color: opColor, fontWeight: FontWeight.w500),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction trouvée',
              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Modifiez vos filtres ou lancez un scan pour initier un paiement.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
