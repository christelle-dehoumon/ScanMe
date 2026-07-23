import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/features/payments/payment_confirmation_screen.dart';

class PaymentInputScreen extends ConsumerStatefulWidget {
  final Map<String, String> paymentData;

  const PaymentInputScreen({super.key, required this.paymentData});

  @override
  ConsumerState<PaymentInputScreen> createState() => _PaymentInputScreenState();
}

class _HomeScreenState extends State<PaymentInputScreen> {
  // Temporary basic build to satisfy Flutter's requirement
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paiement")),
      body: Center(child: Text("Écran de paiement")),
    );
  }
}

class _PaymentInputScreenState extends ConsumerState<PaymentInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    final amountStr = _amountController.text.trim();
    final double amount = double.tryParse(amountStr) ?? 0.0;
    final phone = widget.paymentData['phone'] ?? '';
    final operator = widget.paymentData['operator'] ?? '';
    final beneficiary = widget.paymentData['name'] ?? 'Bénéficiaire';

    // Formulate Deep Link / USSD Sequence for West Africa (Burkina Faso focus)
    // Orange Money BF: *144*4*2*phone*amount#
    // Moov Money BF: *555*2*1*phone*amount# (or similar)
    // Wave: wave://payment?phone=...&amount=...
    String deepLink = '';
    String instructions = '';

    if (operator.toLowerCase().contains('orange')) {
      deepLink = 'tel:%23144%23'; // Note: Cannot easily dial complex *144*4*2# due to OS restrictions on USSD, dial basic USSD instead
      instructions = '1. Nous avons copié le numéro de téléphone ($phone) et le montant (${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(amount)}).\n'
          '2. Tapez le code USSD Orange Money (*144#).\n'
          '3. Choisissez l\'option Transfert, puis collez le numéro et saisissez le montant.';
    } else if (operator.toLowerCase().contains('moov')) {
      deepLink = 'tel:%23555%23';
      instructions = '1. Nous avons copié le numéro de téléphone ($phone) et le montant (${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(amount)}).\n'
          '2. Tapez le code USSD Moov Money (*555#).\n'
          '3. Sélectionnez l\'option Transfert d\'argent, puis entrez le numéro et le montant.';
    } else if (operator.toLowerCase().contains('wave')) {
      deepLink = 'wave://payment?phone=$phone&amount=$amount';
      instructions = '1. L\'application Wave va s\'ouvrir automatiquement.\n'
          '2. Si elle ne s\'ouvre pas, ouvrez-la manuellement : le numéro ($phone) et le montant (${NumberFormat.currency(symbol: 'FCFA', decimalDigits: 0).format(amount)}) ont été copiés dans votre presse-papier.';
    }

    // Copy details to clipboard
    await Clipboard.setData(ClipboardData(text: '$phone $amount'));

    // Attempt to open native application / dialer
    bool launched = false;
    final uri = Uri.parse(deepLink);
    
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (e) {
      // Failed to launch
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      // Show confirmation dialog with instructions & clipboard copy details
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Finaliser le Paiement',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opérateur : $operator',
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 12),
              Text(
                instructions,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Données copiées dans le presse-papier !',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: GoogleFonts.spaceGrotesk(color: AppColors.textTertiary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Add transaction history record
                final txId = const Uuid().v4();
                final transaction = {
                  'id': txId,
                  'beneficiaryName': beneficiary,
                  'phone': phone,
                  'operator': operator,
                  'amount': amount,
                  'timestamp': DateTime.now().toIso8601String(),
                  'reference': 'SM-${const Uuid().v4().substring(0, 8).toUpperCase()}',
                  'type': 'sent',
                };
                
                await ref.read(paymentsRepositoryProvider).addTransaction(transaction);

                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => PaymentConfirmationScreen(transactionData: transaction),
                    ),
                  );
                }
              },
              child: Text(
                'Confirmé, paiement fait',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final operator = widget.paymentData['operator'] ?? 'Mobile Money';
    final phone = widget.paymentData['phone'] ?? '';
    final beneficiary = widget.paymentData['name'] ?? 'Bénéficiaire';

    Color opColor = AppColors.orangeMoney;
    if (operator.toLowerCase().contains('moov')) opColor = AppColors.moovMoney;
    if (operator.toLowerCase().contains('wave')) opColor = AppColors.wave;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectuer un Paiement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Operator styled header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [opColor.withValues(alpha: 0.9), opColor.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              beneficiary,
                              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$operator • $phone',
                              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Text(
                  'Saisissez le Montant (XOF)',
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ex: 1000',
                    suffixText: 'FCFA',
                    suffixStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    final amount = double.tryParse(value) ?? 0;
                    if (amount <= 0) {
                      return 'Le montant doit être supérieur à 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Quick Amount Shortcuts
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _quickAmounts.map((amount) {
                      return GestureDetector(
                        onTap: () => _onQuickAmountSelected(amount),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: opColor.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            '+${NumberFormat.decimalPattern().format(amount)}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 56),
                
                AnimatedScaleButton(
                  onTap: _isLoading ? null : _submitPayment,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: opColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: opColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Payer maintenant',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
