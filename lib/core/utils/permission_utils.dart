import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanme_app/core/theme/theme.dart';

class PermissionUtils {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (kIsWeb) return true;
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final proceed = await showRationaleDialog(
        context,
        title: 'Accès Appareil Photo',
        description: 'ScanMe a besoin d\'utiliser votre appareil photo pour scanner les QR codes de contact et de paiement.',
        icon: Icons.camera_alt_rounded,
      );
      if (!proceed) return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  static Future<bool> requestContactsPermission(BuildContext context) async {
    if (kIsWeb) return true;
    final status = await Permission.contacts.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final proceed = await showRationaleDialog(
        context,
        title: 'Accès aux Contacts',
        description: 'ScanMe a besoin de l\'autorisation de votre répertoire pour pouvoir y enregistrer directement les contacts scannés.',
        icon: Icons.contacts_rounded,
      );
      if (!proceed) return false;
    }

    final result = await Permission.contacts.request();
    return result.isGranted;
  }

  static Future<bool> requestNotificationsPermission(BuildContext context) async {
    if (kIsWeb) return true;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final proceed = await showRationaleDialog(
        context,
        title: 'Notifications Push',
        description: 'ScanMe a besoin de vous envoyer des notifications pour vous alerter en temps réel des demandes d\'autorisation de réseaux sociaux.',
        icon: Icons.notifications_active_rounded,
      );
      if (!proceed) return false;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  static Future<bool> showRationaleDialog(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Refuser',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Continuer',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }
}
