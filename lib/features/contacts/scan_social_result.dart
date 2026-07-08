import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';

class ScanSocialResultScreen extends ConsumerStatefulWidget {
  final Map<String, String> socialData;

  const ScanSocialResultScreen({super.key, required this.socialData});

  @override
  ConsumerState<ScanSocialResultScreen> createState() => _ScanSocialResultScreenState();
}

class _ScanSocialResultScreenState extends ConsumerState<ScanSocialResultScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _demand;
  Timer? _pollingTimer;
  bool _isSendingRequest = true;
  bool _hasAutoLaunched = false;

  // Pulsing animation for the waiting indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _sendRequestAndStartPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendRequestAndStartPolling() async {
    final ownerPhone = widget.socialData['ownerPhone'] ?? '';
    final network = widget.socialData['network'] ?? '';
    final username = widget.socialData['username'] ?? '';
    final myPhone = ref.read(authRepositoryProvider).currentUser?['phone'] ?? '';

    // Check if we already sent a request for this profile
    final demands = await ref.read(contactsRepositoryProvider).getDemands();
    final existing = demands.where((d) =>
        d['targetUserPhone'] == ownerPhone &&
        d['networkType'] == network &&
        d['requesterPhone'] == myPhone);

    if (existing.isNotEmpty) {
      setState(() {
        _demand = existing.first;
        _isSendingRequest = false;
      });
    } else {
      // Send new request
      await ref.read(contactsRepositoryProvider).sendSocialAccessRequest(
            targetUserPhone: ownerPhone,
            requesterPhone: myPhone,
            networkType: network,
            networkUsername: username,
          );
      await _pollDemandStatus();
      setState(() {
        _isSendingRequest = false;
      });
    }

    // Start polling every 2 seconds for owner's response
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _pollDemandStatus();
    });
  }

  Future<void> _pollDemandStatus() async {
    final ownerPhone = widget.socialData['ownerPhone'] ?? '';
    final network = widget.socialData['network'] ?? '';
    final myPhone = ref.read(authRepositoryProvider).currentUser?['phone'] ?? '';

    final demands = await ref.read(contactsRepositoryProvider).getDemands();
    final match = demands.where((d) =>
        d['targetUserPhone'] == ownerPhone &&
        d['networkType'] == network &&
        d['requesterPhone'] == myPhone);

    if (match.isNotEmpty && mounted) {
      final demand = match.first;
      final previousStatus = _demand?['status'];
      setState(() {
        _demand = demand;
      });

      // If newly accepted, auto-launch the profile
      if (demand['status'] == 'accepted' && previousStatus != 'accepted' && !_hasAutoLaunched) {
        _hasAutoLaunched = true;
        _pollingTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _openSocialProfile();
        }
      }
    }
  }

  Future<void> _openSocialProfile() async {
    final network = (widget.socialData['network'] ?? '').toLowerCase();
    final username = widget.socialData['username'] ?? '';

    String urlString = '';
    // Try native app deep link first, then fallback to web
    if (network == 'instagram') {
      urlString = 'instagram://user?username=$username';
    } else if (network == 'snapchat') {
      urlString = 'snapchat://add/$username';
    } else if (network == 'tiktok') {
      urlString = 'tiktok://user?username=$username';
    }

    bool launched = false;
    if (urlString.isNotEmpty) {
      try {
        final nativeUri = Uri.parse(urlString);
        if (await canLaunchUrl(nativeUri)) {
          launched = await launchUrl(nativeUri);
        }
      } catch (_) {}
    }

    // Fallback to web
    if (!launched) {
      String webUrl = '';
      if (network == 'instagram') {
        webUrl = 'https://instagram.com/$username';
      } else if (network == 'snapchat') {
        webUrl = 'https://www.snapchat.com/add/$username';
      } else if (network == 'tiktok') {
        webUrl = 'https://tiktok.com/@$username';
      }

      if (webUrl.isNotEmpty) {
        try {
          await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final network = (widget.socialData['network'] ?? '').toLowerCase();
    final username = widget.socialData['username'] ?? '';
    final status = _demand?['status'] ?? 'pending';

    Color iconColor = AppColors.primaryLight;
    IconData socialIcon = Icons.person_rounded;
    Color networkBg = AppColors.primary.withValues(alpha: 0.1);

    if (network.toLowerCase() == 'instagram') {
      socialIcon = Icons.camera_alt_rounded;
      iconColor = const Color(0xFFE1306C);
      networkBg = const Color(0xFFE1306C).withValues(alpha: 0.1);
    } else if (network.toLowerCase() == 'snapchat') {
      socialIcon = Icons.snapchat_rounded;
      iconColor = const Color(0xFFFFFC00);
      networkBg = const Color(0xFFFFFC00).withValues(alpha: 0.1);
    } else if (network.toLowerCase() == 'tiktok') {
      socialIcon = Icons.music_note_rounded;
      iconColor = const Color(0xFF00F2FE);
      networkBg = const Color(0xFF00F2FE).withValues(alpha: 0.08);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Accès à $network'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: status == 'pending' ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: networkBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: status == 'accepted' ? 1.0 : 0.3),
                      width: 2.5,
                    ),
                    boxShadow: status == 'accepted'
                        ? [BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4)]
                        : [],
                  ),
                  child: Icon(socialIcon, size: 55, color: iconColor),
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                network,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '@$username',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 40),

              // Status Card
              _buildStatusContent(status, network, username, iconColor),

              const Spacer(),

              // Bottom Buttons
              if (status == 'accepted') ...[
                AnimatedScaleButton(
                  onTap: _openSocialProfile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: iconColor == const Color(0xFFFFFC00) ? Colors.black : iconColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            color: iconColor == const Color(0xFFFFFC00) ? iconColor : Colors.white,
                            size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Ouvrir le profil $network',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: iconColor == const Color(0xFFFFFC00) ? iconColor : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

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

  Widget _buildStatusContent(String status, String network, String username, Color color) {
    if (_isSendingRequest) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Envoi de la demande…',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(color: AppColors.warning, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'En attente d\'approbation',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'La demande a été envoyée. Le propriétaire de ce profil $network a reçu une notification.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppColors.primaryLight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Cette page se met à jour automatiquement',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Accès accordé ! 🎉',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '@$username',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Le propriétaire a accepté ta demande. Ouvre son profil $network pour l\'ajouter directement.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Rejected
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.block_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 14),
          Text(
            'Demande refusée',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'utilisateur a choisi de ne pas partager son profil $network. Aucune information n\'a été communiquée.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
