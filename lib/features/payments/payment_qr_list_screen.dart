import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';

class PaymentQrListScreen extends ConsumerStatefulWidget {
  const PaymentQrListScreen({super.key});

  @override
  ConsumerState<PaymentQrListScreen> createState() => _PaymentQrListScreenState();
}

class _PaymentQrListScreenState extends ConsumerState<PaymentQrListScreen> {
  List<Map<String, dynamic>> _qrList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQrs();
  }

  Future<void> _loadQrs() async {
    setState(() {
      _isLoading = true;
    });
    final list = await ref.read(paymentsRepositoryProvider).getPaymentQrs();
    if (mounted) {
      setState(() {
        _qrList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _addPaymentQr(String name, String phone, String operator) async {
    final id = const Uuid().v4();
    final qrData = {
      'id': id,
      'name': name,
      'phone': phone,
      'operator': operator,
      'isActive': true,
    };
    await ref.read(paymentsRepositoryProvider).savePaymentQr(qrData);
    _loadQrs();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR de Paiement $operator ajouté.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteQr(String id) async {
    await ref.read(paymentsRepositoryProvider).deletePaymentQr(id);
    _loadQrs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR de Paiement supprimé.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddQrBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedOperator = 'Orange Money';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau QR de Paiement',
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sélectionnez l\'opérateur',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Orange Money', 'Moov Money', 'Wave'].map((op) {
                    final isSelected = selectedOperator == op;
                    Color opColor = AppColors.primary;
                    if (op == 'Orange Money') opColor = AppColors.orangeMoney;
                    if (op == 'Moov Money') opColor = AppColors.moovMoney;
                    if (op == 'Wave') opColor = AppColors.wave;

                    return Expanded(
                      child: AnimatedScaleButton(
                        onTap: () => setModalState(() => selectedOperator = op),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? opColor.withValues(alpha: 0.12) : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? opColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            op.split(' ')[0], // Orange, Moov, Wave
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nom du bénéficiaire (Personnel ou Commercial)',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Ex: K-Fast Sarl',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nom obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Numéro de téléphone associé',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Ex: +226 70 00 00 00',
                    prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Numéro obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AnimatedScaleButton(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      _addPaymentQr(
                        nameController.text.trim(),
                        phoneController.text.trim(),
                        selectedOperator,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Créer le QR Code de paiement',
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
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

  void _showQrDetails(Map<String, dynamic> qr) {
    final name = qr['name'] ?? '';
    final phone = qr['phone'] ?? '';
    final op = qr['operator'] ?? '';
    
    Color opColor = AppColors.orangeMoney;
    if (op == 'Moov Money') opColor = AppColors.moovMoney;
    if (op == 'Wave') opColor = AppColors.wave;

    // payment format link: scanme://payment?phone=...&operator=...&name=...
    final qrString = 'scanme://payment?phone=${Uri.encodeComponent(phone)}&operator=${Uri.encodeComponent(op)}&name=${Uri.encodeComponent(name)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: opColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    op,
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: opColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: qrString,
                      version: QrVersions.auto,
                      size: 200,
                      gapless: false,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF13121A)),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF13121A)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteQr(qr['id']);
                        },
                        child: const Text('Supprimer'),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes QR de Paiement'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  Expanded(
                    child: _qrList.isEmpty
                        ? Center(child: Text('Aucun QR de paiement.', style: GoogleFonts.dmSans(color: AppColors.textSecondary)))
                        : ListView.builder(
                            itemCount: _qrList.length,
                            itemBuilder: (context, index) {
                              final qr = _qrList[index];
                              return _buildPaymentQrCard(qr);
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedScaleButton(
                    onTap: _showAddQrBottomSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Créer un QR de paiement',
                            style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentQrCard(Map<String, dynamic> qr) {
    final name = qr['name'] ?? '';
    final phone = qr['phone'] ?? '';
    final op = qr['operator'] ?? '';

    Color opColor = AppColors.orangeMoney;
    if (op == 'Moov Money') opColor = AppColors.moovMoney;
    if (op == 'Wave') opColor = AppColors.wave;

    return GestureDetector(
      onTap: () => _showQrDetails(qr),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: opColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: opColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_rounded, color: opColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: opColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                op.split(' ')[0], // Orange, Moov, Wave
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
