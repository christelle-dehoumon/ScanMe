import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/features/auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  void initState() {
    super.initState();
  }


  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Politique de Confidentialité',
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPolicySection(
                      '1. Collecte des informations',
                      'ScanMe collecte vos informations d\'identification (nom d\'affichage, numéro de téléphone) uniquement pour permettre l\'identification de vos contacts lors des partages de codes QR et la préparation des transferts Mobile Money. Aucune donnée relative aux réseaux sociaux n\'est collectée ou stockée sur nos serveurs sans votre demande explicite.',
                    ),
                    _buildPolicySection(
                      '2. Partage de données & Consentement',
                      'Le partage de vos profils sociaux (Instagram, Snapchat, TikTok) s\'effectue exclusivement via un protocole d\'autorisation à deux facteurs. ScanMe n\'affiche et ne transmet jamais vos données ou identifiants de réseaux sociaux à des tiers sans votre consentement préalable et actif depuis l\'écran "Demandes".',
                    ),

                    _buildPolicySection(
                      '4. Stockage local & Cache',
                      'Pour assurer un fonctionnement fluide, notamment en situation de connectivité intermittente en Afrique de l\'Ouest, vos données d\'utilisation et l\'historique des transactions sont mis en cache localement et de manière chiffrée sur votre appareil mobile.',
                    ),
                    _buildPolicySection(
                      '5. Vos droits (RGPD & Réglementations)',
                      'Conformément aux exigences légales, vous disposez d\'un contrôle total sur vos données. Vous pouvez révoquer à tout moment l\'accès accordé à un contact, et supprimer définitivement votre compte et toutes les données associées directement depuis vos paramètres.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer le compte ?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: AppColors.error),
        ),
        content: Text(
          'Cette action est irréversible. Toutes vos données locales (QR créés, contacts enregistrés) seront supprimées définitivement.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authRepositoryProvider).deleteAccount();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Supprimer', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final name = user?['name'] ?? 'Utilisateur ScanMe';
    final phone = user?['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Paramètres'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // Profile Summary
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 36),
              
              const SizedBox(height: 24),
              
              // Settings Submenu Group
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Paramètres généraux',
                  style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Langue de l\'application',
                      value: 'Français (FR)',
                      onTap: () {
                        // Language change template trigger
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.security_rounded,
                      title: 'Politique de Confidentialité',
                      onTap: _showPrivacyPolicy,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'À propos de ScanMe',
                      value: 'v1.0.0 (Production)',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // Account Actions Group
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Se déconnecter',
                      textColor: AppColors.warning,
                      onTap: _logout,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Supprimer mon compte',
                      textColor: AppColors.error,
                      onTap: _showDeleteAccountConfirm,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? value,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.primaryLight, size: 22),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.textTertiary.withValues(alpha: 0.08),
      indent: 16,
      endIndent: 16,
    );
  }
}
