import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/features/payments/payment_qr_list_screen.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  final double _todayVolume = 67500.0;
  final int _transactionCount = 14;
  List<Map<String, dynamic>> _receivedTransactions = [];

  @override
  void initState() {
    super.initState();
    _seedMockReceivedTransactions();
  }

  void _seedMockReceivedTransactions() {
    _receivedTransactions = [
      {
        'id': 'r1',
        'customerName': 'Sangaré Ibrahim',
        'phone': '+226 70 45 45 45',
        'operator': 'Orange Money',
        'amount': 15000.0,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        'reference': 'SM-OM-REC-93A',
      },
      {
        'id': 'r2',
        'customerName': 'Traoré Aboubacar',
        'phone': '+226 55 12 12 12',
        'operator': 'Wave',
        'amount': 2500.0,
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 20)).toIso8601String(),
        'reference': 'SM-WV-REC-11B',
      },
      {
        'id': 'r3',
        'customerName': 'Sanou Mariam',
        'phone': '+226 67 09 09 09',
        'operator': 'Moov Money',
        'amount': 50000.0,
        'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 40)).toIso8601String(),
        'reference': 'SM-MV-REC-74F',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final formattedVolume = NumberFormat.currency(symbol: 'XOF', decimalDigits: 0).format(_todayVolume);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final name = user?['name'] ?? 'Ma Boutique';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Commerçant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PaymentQrListScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Text(
                name,
                style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Vue d\'ensemble de vos encaissements d\'aujourd\'hui',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              
              // ScanMe stats overview cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total du jour',
                      formattedVolume,
                      Icons.trending_up_rounded,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Transactions',
                      '$_transactionCount Ventes',
                      Icons.shopping_bag_rounded,
                      AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Custom mini graph styling (premium visual touch)
              _buildMiniGraphSection(),
              
              const SizedBox(height: 32),
              
              // Recent customer transactions list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Derniers encaissements',
                    style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full list
                    },
                    child: const Text('Tout voir'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _receivedTransactions.length,
                itemBuilder: (context, index) {
                  final tx = _receivedTransactions[index];
                  return _buildReceivedCard(tx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGraphSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par opérateur',
            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          
          // Progress bar Orange Money
          _buildOperatorProgressRow('Orange Money', 0.55, '37 125 XOF', AppColors.orangeMoney),
          const SizedBox(height: 16),
          // Progress bar Moov Money
          _buildOperatorProgressRow('Moov Money', 0.30, '20 250 XOF', AppColors.moovMoney),
          const SizedBox(height: 16),
          // Progress bar Wave
          _buildOperatorProgressRow('Wave', 0.15, '10 125 XOF', AppColors.wave),
        ],
      ),
    );
  }

  Widget _buildOperatorProgressRow(String name, double percent, String amount, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              amount,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: AppColors.surfaceCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
      ],
    );
  }

  Widget _buildReceivedCard(Map<String, dynamic> tx) {
    final customer = tx['customerName'] ?? 'Client';
    final amount = tx['amount'] ?? 0.0;
    final op = tx['operator'] ?? 'Mobile Money';
    final timestamp = tx['timestamp'] ?? DateTime.now().toIso8601String();
    
    final formattedAmount = NumberFormat.currency(symbol: 'XOF', decimalDigits: 0).format(amount);
    final date = DateTime.parse(timestamp);
    final formattedDate = DateFormat('HH:mm').format(date);

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
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer,
                  style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aujourd\'hui à $formattedDate • via $op',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+ $formattedAmount',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.success),
          )
        ],
      ),
    );
  }
}
