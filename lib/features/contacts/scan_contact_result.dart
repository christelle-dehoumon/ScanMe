import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as native_contacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/utils/permission_utils.dart';
import 'package:scanme_app/core/providers/repositories.dart';

class ScanContactResultScreen extends ConsumerStatefulWidget {
  final Map<String, String> contactData;

  const ScanContactResultScreen({super.key, required this.contactData});

  @override
  ConsumerState<ScanContactResultScreen> createState() => _ScanContactResultScreenState();
}

class _ScanContactResultScreenState extends ConsumerState<ScanContactResultScreen> {
  bool _isSaving = false;
  bool _isSavedLocally = false;
  bool _isSavedNatively = false;

  @override
  void initState() {
    super.initState();
    _saveLocally();
  }

  Future<void> _saveLocally() async {
    final name = widget.contactData['name'] ?? 'Inconnu';
    final phone = widget.contactData['phone'] ?? '';
    if (phone.isEmpty) return;

    try {
      await ref.read(contactsRepositoryProvider).saveScannedContact({
        'id': phone,
        'name': name,
        'phone': phone,
        'timestamp': DateTime.now().toIso8601String(),
      });
      setState(() {
        _isSavedLocally = true;
      });
    } catch (e) {
      // Ignored for cache
    }
  }

  Future<void> _saveToNativeContacts() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final hasPermission = await PermissionUtils.requestContactsPermission(context);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission d\'accès aux contacts refusée.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final name = widget.contactData['name'] ?? 'Inconnu';
      final phone = widget.contactData['phone'] ?? '';
      
      // Parse first name / last name
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : name;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final newContact = native_contacts.Contact(
        name: native_contacts.Name(first: firstName, last: lastName),
        phones: [native_contacts.Phone(number: phone)],
      );

      await native_contacts.FlutterContacts.create(newContact);

      setState(() {
        _isSavedNatively = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name a été ajouté à vos contacts.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur est survenue lors de l\'enregistrement dans le répertoire.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.contactData['name'] ?? 'Inconnu';
    final phone = widget.contactData['phone'] ?? 'Aucun numéro';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Scanné'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phone,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              
              // Local save feedback banner
              if (_isSavedLocally)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Enregistré dans l\'historique ScanMe (Hors-ligne)',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),
              
              // Action buttons
              AnimatedScaleButton(
                onTap: _isSavedNatively || _isSaving ? null : _saveToNativeContacts,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _isSavedNatively 
                        ? AppColors.surfaceCard
                        : (_isSaving ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isSavedNatively || _isSaving
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSavedNatively ? Icons.contacts_rounded : Icons.person_add_alt_1_rounded,
                              color: _isSavedNatively ? AppColors.textSecondary : Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isSavedNatively ? 'Ajouté au Répertoire' : 'Ajouter au répertoire natif',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _isSavedNatively ? AppColors.textSecondary : Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
