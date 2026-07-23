import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/core/utils/qr_link_utils.dart';
import 'package:scanme_app/core/widgets/app_animations.dart';

class PersonalQrsScreen extends ConsumerStatefulWidget {
  const PersonalQrsScreen({super.key});

  @override
  ConsumerState<PersonalQrsScreen> createState() => _PersonalQrsScreenState();
}

class _PersonalQrsScreenState extends ConsumerState<PersonalQrsScreen> {
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
    final list = await ref.read(contactsRepositoryProvider).getPersonalQrs();
    if (mounted) {
      setState(() {
        _qrList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewSocialQr(String network, String username) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final myPhone = user?['phone'] ?? '+226 70 00 00 00';
    final id = const Uuid().v4();

    // Custom deep link: scanme://social?ownerPhone=...&network=...&username=...
    final qrData = {
      'id': id,
      'type': 'social',
      'title': 'Mon $network',
      'network': network,
      'username': username,
      'phone': myPhone,
      'isActive': true,
    };

    await ref.read(contactsRepositoryProvider).savePersonalQr(qrData);
    _loadQrs();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code QR $network créé avec succès.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteQr(String id) async {
    await ref.read(contactsRepositoryProvider).deletePersonalQr(id);
    _loadQrs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code QR supprimé.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleQrActive(Map<String, dynamic> qr) async {
    final updated = Map<String, dynamic>.from(qr);
    updated['isActive'] = !(qr['isActive'] ?? true);
    await ref.read(contactsRepositoryProvider).savePersonalQr(updated);
    _loadQrs();
  }

  void _showAddQrBottomSheet() {
    String selectedNetwork = 'Instagram';
    final TextEditingController usernameController = TextEditingController();
    final user = ref.read(authRepositoryProvider).currentUser;
    final myPhone = user?['phone'] ?? '+226 70 00 00 00';
    final formKey = GlobalKey<FormState>();

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
                  'Ajouter un profil social',
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sélectionnez le réseau social',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Instagram', 'Snapchat', 'TikTok', 'WhatsApp'].map((network) {
                    final isSelected = selectedNetwork == network;
                    Color nColor = AppColors.primary;
                    if (network == 'Instagram') nColor = const Color(0xFFE1306C);
                    if (network == 'Snapchat') nColor = const Color(0xFFFFFC00);
                    if (network == 'TikTok') nColor = const Color(0xFF00F2FE);
                      if (network == 'WhatsApp') nColor = const Color(0xFF25D366);

                    return Expanded(
                      child: GestureDetector(
                          onTap: () => setModalState(() {
                            selectedNetwork = network;
                            if (selectedNetwork == 'WhatsApp') {
                              usernameController.text = myPhone;
                            } else {
                              usernameController.clear();
                            }
                          }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? nColor.withValues(alpha: 0.12) : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? nColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            network,
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
                const SizedBox(height: 24),
                Text(
                  selectedNetwork == 'WhatsApp' ? 'Numéro de téléphone' : 'Identifiant / Nom d\'utilisateur',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: usernameController,
                  autofocus: selectedNetwork != 'WhatsApp',
                  readOnly: selectedNetwork == 'WhatsApp',
                  keyboardType: selectedNetwork == 'WhatsApp' ? TextInputType.phone : TextInputType.text,
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: selectedNetwork == 'WhatsApp' ? myPhone : 'Ex: diallo_pro',
                    prefixText: selectedNetwork == 'WhatsApp' ? '' : '@ ',
                    prefixStyle: GoogleFonts.dmSans(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  validator: (value) {
                    if (selectedNetwork == 'WhatsApp') return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Identifiant requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AnimatedScaleButton(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      _addNewSocialQr(selectedNetwork, usernameController.text.trim());
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
                      'Générer le QR Code',
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

  void _showQrDetailsDialog(Map<String, dynamic> qr) {
    final isContact = qr['type'] == 'contact';
    final phone = qr['phone'] ?? '';
    final name = qr['name'] ?? '';
    final network = qr['network'] ?? '';
    final username = qr['username'] ?? '';

    // Build the QR data string
    String qrString = '';
    if (isContact) {
      // Offline vCard — works without internet
      qrString = 'BEGIN:VCARD\nVERSION:3.0\nFN:$name\nTEL;TYPE=CELL:$phone\nNOTE:ScanMe User\nEND:VCARD';
    } else {
      // HTTPS link — readable by phone cameras; ScanMe scanner handles the approval flow
      if (network.toLowerCase() == 'whatsapp') {
        final normalized = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
        qrString = 'https://wa.me/$normalized';
      } else {
        qrString = QrLinkUtils.buildSocialQrLink(
          ownerPhone: phone,
          network: network,
          username: username,
        );
      }
    }

    // Network branding
    Color netColor = AppColors.primaryLight;
    IconData netIcon = Icons.person_rounded;
    if (network.toLowerCase() == 'snapchat') {
      netColor = const Color(0xFFFFFC00);
      netIcon = Icons.snapchat_rounded;
    } else if (network.toLowerCase() == 'instagram') {
      netColor = const Color(0xFFE1306C);
      netIcon = Icons.camera_alt_rounded;
    } else if (network.toLowerCase() == 'tiktok') {
      netColor = const Color(0xFF00F2FE);
      netIcon = Icons.music_note_rounded;
    } else if (network.toLowerCase() == 'whatsapp') {
      netColor = const Color(0xFF25D366);
      netIcon = Icons.chat_bubble_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            if (!isContact) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(netIcon, size: 28, color: netColor),
              ),
              const SizedBox(height: 12),
              Text(
                '@$username',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'sur $network',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
              ),
            ] else ...[
              Text(
                'Mon Contact',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ],

            const SizedBox(height: 20),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isContact ? AppColors.primary : netColor).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: SizedBox(
                width: 230,
                height: 230,
                child: QrImageView(
                  data: qrString,
                  version: QrVersions.auto,
                  size: 230,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: Color(0xFF13121A)),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: Color(0xFF13121A)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // How it works (for social QRs)
            if (!isContact) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'À scanner avec le scanner ScanMe (pas l\'appareil photo iPhone).',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildStep('1', 'La personne scanne ce QR avec ScanMe'),
                    const SizedBox(height: 8),
                    _buildStep('2', 'Vous recevez un popup : «\u00a0X veut vous ajouter sur $network\u00a0»'),
                    const SizedBox(height: 8),
                    _buildStep('3', 'Vous acceptez → elle est redirigée vers votre profil pour vous ajouter'),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.primaryLight, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fonctionne hors-ligne · Les données sont encodées directement dans le QR',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ),
                if (!isContact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteQr(qr['id']);
                      },
                      child: Text(
                        'Supprimer',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Codes QR'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  Expanded(
                    child: _qrList.isEmpty
                        ? Center(child: Text('Aucun QR code.', style: GoogleFonts.dmSans(color: AppColors.textSecondary)))
                        : ListView.builder(
                            itemCount: _qrList.length,
                            itemBuilder: (context, index) {
                              final qr = _qrList[index];
                              return FadeSlideIn(
                                delayMs: index * 80,
                                slideOffset: 16,
                                child: _buildQrCard(qr),
                              );
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
                            'Ajouter un QR Réseau Social',
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

  Widget _buildQrCard(Map<String, dynamic> qr) {
    final isContact = qr['type'] == 'contact';
    final title = qr['title'] ?? 'QR Code';
    final isActive = qr['isActive'] ?? true;
    final network = qr['network'] ?? '';
    final username = qr['username'] ?? '';
    final phone = qr['phone'] ?? '';

    Color netColor = AppColors.primaryLight;
    IconData netIcon = Icons.person_rounded;

    if (!isContact) {
      if (network.toLowerCase() == 'instagram') {
        netIcon = Icons.camera_alt_rounded;
        netColor = const Color(0xFFE1306C);
      } else if (network.toLowerCase() == 'snapchat') {
        netIcon = Icons.snapchat_rounded;
        netColor = const Color(0xFFFFFC00);
      } else if (network.toLowerCase() == 'tiktok') {
        netIcon = Icons.music_note_rounded;
        netColor = const Color(0xFF00F2FE);
      } else if (network.toLowerCase() == 'whatsapp') {
        netIcon = Icons.chat_bubble_rounded;
        netColor = const Color(0xFF25D366);
      }
    }

    return InkWell(
      onTap: () => _showQrDetailsDialog(qr),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: netColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(netIcon, color: netColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isContact
                        ? 'Partage de téléphone direct'
                        : (network.toLowerCase() == 'whatsapp' ? phone : '@$username'),
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              activeThumbColor: AppColors.primaryLight,
              onChanged: (value) => _toggleQrActive(qr),
            ),
          ],
        ),
      ),
    );
  }

}
