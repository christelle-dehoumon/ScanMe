import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanme_app/core/theme/theme.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const PaymentConfirmationScreen({super.key, required this.transactionData});

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareReceipt() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // 1. Capture the widget as PNG bytes using RepaintBoundary
      final RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Wait for rendering frame
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // 2. Save the PNG bytes into a temporary directory
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/recu_scanme_${widget.transactionData['reference']}.png').create();
        await imagePath.writeAsBytes(pngBytes);

        // 3. Share the file via share_plus
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Reçu de paiement ScanMe - ${widget.transactionData['beneficiaryName']}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de générer ou de partager le reçu.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.transactionData['beneficiaryName'] ?? 'Bénéficiaire';
    final phone = widget.transactionData['phone'] ?? '';
    final op = widget.transactionData['operator'] ?? 'Mobile Money';
    final amount = widget.transactionData['amount'] ?? 0.0;
    final reference = widget.transactionData['reference'] ?? 'SM-0000000';
    final timestamp = widget.transactionData['timestamp'] ?? DateTime.now().toIso8601String();
    
    final formattedAmount = NumberFormat.currency(symbol: 'XOF', decimalDigits: 0).format(amount);
    final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(timestamp));

    // Mask phone number for privacy (e.g. +226 70 •••• 12)
    String maskedPhone = phone;
    if (phone.length > 8) {
      maskedPhone = '${phone.substring(0, 8)} •••• ${phone.substring(phone.length - 2)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // SUCCESS ICON BANNER
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Paiement Effectué !',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // REPAINT BOUNDARY TO CAPTURE IMAGE
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header logo/ticket representation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'REÇU KPAY',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryLight,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const Icon(Icons.receipt_long_rounded, color: AppColors.textTertiary),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.textTertiary, thickness: 0.5),
                            const SizedBox(height: 16),
                            
                            // Amount Display
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Montant payé',
                                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedAmount,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Receipt Details
                            _buildReceiptRow('Bénéficiaire', name),
                            _buildReceiptRow('Numéro de Tél', maskedPhone),
                            _buildReceiptRow('Opérateur', op),
                            _buildReceiptRow('Date & Heure', formattedDate),
                            _buildReceiptRow('Référence ScanMe', reference),
                            
                            const SizedBox(height: 16),
                            const Divider(color: AppColors.textTertiary, thickness: 0.5),
                            const SizedBox(height: 12),
                            
                            Center(
                              child: Text(
                                'Merci d\'avoir utilisé ScanMe.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        // Pop all and return to root navigation (Home Screen)
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Accueil'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSharing ? null : _shareReceipt,
                      child: _isSharing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Partager',
                                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
