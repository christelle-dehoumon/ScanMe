import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';

class PendingDemandsScreen extends ConsumerStatefulWidget {
  const PendingDemandsScreen({super.key});

  @override
  ConsumerState<PendingDemandsScreen> createState() => _PendingDemandsScreenState();
}

class _PendingDemandsScreenState extends ConsumerState<PendingDemandsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _demands = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  // Tracks which demand IDs we've already shown a popup for (so we don't show it twice)
  final Set<String> _shownPopupIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDemands();

    // Poll every 3 seconds to simulate real-time notifications
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _loadDemands(showPopups: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDemands({bool showPopups = false}) async {
    final myPhone = ref.read(authRepositoryProvider).currentUser?['phone'] ?? '';
    final list = await ref.read(contactsRepositoryProvider).getDemands();

    // Seed dummy demands on first load if empty
    if (list.isEmpty) {

      await ref.read(contactsRepositoryProvider).sendSocialAccessRequest(
            targetUserPhone: myPhone,
            requesterPhone: '+226 71 22 33 44',
            networkType: 'Snapchat',
            networkUsername: 'my_snap_profile',
          );

      await ref.read(contactsRepositoryProvider).sendSocialAccessRequest(
            targetUserPhone: myPhone,
            requesterPhone: '+226 62 88 77 66',
            networkType: 'Instagram',
            networkUsername: 'my_insta_profile',
          );
    }

    final updatedList = await ref.read(contactsRepositoryProvider).getDemands();

    if (mounted) {
      // Detect new incoming pending demands we haven't shown a popup for yet
      if (showPopups) {
        final newPending = updatedList.where((d) =>
            d['targetUserPhone'] == myPhone &&
            d['status'] == 'pending' &&
            !_shownPopupIds.contains(d['id']));

        for (final demand in newPending) {
          _shownPopupIds.add(demand['id']);
          // Show with a tiny delay so widget is built
          final ctx = context;
          Future.delayed(const Duration(milliseconds: 200), () {
            if (!mounted) return;
            _showApprovalPopup(ctx, demand);
          });
        }
      } else {
        // On first load, mark all existing pending as "already notified"
        for (final d in updatedList) {
          if (d['targetUserPhone'] == myPhone && d['status'] == 'pending') {
            _shownPopupIds.add(d['id']);
          }
        }
      }

      setState(() {
        _demands = updatedList;
        _isLoading = false;
      });
    }
  }

  /// Shows the approval popup dialog — this is the "pop-up" the owner receives
  void _showApprovalPopup(BuildContext ctx, Map<String, dynamic> demand) {
    final requesterName = demand['requesterName'] ?? 'Quelqu\'un';
    final network = demand['networkType'] ?? 'Réseau Social';
    final id = demand['id'];

    Color netColor = AppColors.primary;
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
    }

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: netColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: netColor.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Network Icon with glow
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: netColor.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: netColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(netIcon, size: 38, color: netColor),
              ),

              const SizedBox(height: 20),

              Text(
                'Demande d\'ajout',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                requesterName,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'veut vous ajouter sur ',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: network,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: netColor == const Color(0xFFFFFC00) ? Colors.amber : netColor,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Si vous acceptez, il sera redirigé directement vers votre profil pour vous ajouter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _respond(id, 'rejected');
                      },
                      child: Text(
                        'Refuser',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: netColor == const Color(0xFFFFFC00)
                            ? Colors.black
                            : (netColor == AppColors.primary ? AppColors.primary : netColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _respond(id, 'accepted');
                        // Show success confirmation
                        if (mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.black),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '$requesterName peut maintenant accéder à votre profil $network.',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Accepter ✓',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: netColor == const Color(0xFFFFFC00) ? netColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respond(String id, String status) async {
    await ref.read(contactsRepositoryProvider).respondToDemand(id, status);
    await _loadDemands();
  }

  Future<void> _revoke(String id) async {
    await ref.read(contactsRepositoryProvider).revokeSocialAccess(id);
    await _loadDemands();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès révoqué.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openSocialProfile(String network, String username) async {
    String urlString = '';
    final net = network.toLowerCase();
    // Try native deep link first
    if (net == 'instagram') {
      urlString = 'https://instagram.com/$username';
    } else if (net == 'snapchat') {
      urlString = 'https://www.snapchat.com/add/$username';
    } else if (net == 'tiktok') {
      urlString = 'https://tiktok.com/@$username';
    } else {
      urlString = 'https://google.com';
    }

    try {
      await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final myPhone = ref.read(authRepositoryProvider).currentUser?['phone'] ?? '';

    final receivedDemands = _demands.where((d) => d['targetUserPhone'] == myPhone).toList();
    final sentDemands = _demands.where((d) => d['requesterPhone'] == myPhone).toList();

    final pendingCount = receivedDemands.where((d) => d['status'] == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Demandes d\'Accès'),
            if (pendingCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Reçues${pendingCount > 0 ? ' ($pendingCount)' : ''}'),
            const Tab(text: 'Envoyées'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReceivedTab(receivedDemands),
                _buildSentTab(sentDemands),
              ],
            ),
    );
  }

  Widget _buildReceivedTab(List<Map<String, dynamic>> list) {
    final pending = list.where((d) => d['status'] == 'pending').toList();
    final active = list.where((d) => d['status'] == 'accepted').toList();
    final rejected = list.where((d) => d['status'] == 'rejected').toList();

    if (list.isEmpty) {
      return _buildEmptyState(
          'Aucune demande reçue',
          'Quand quelqu\'un scannera votre QR code réseau social, sa demande apparaîtra ici.');
    }

    return RefreshIndicator(
      onRefresh: () => _loadDemands(showPopups: true),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pending demands first (most important)
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('🔔 En attente · ${pending.length}'),
            const SizedBox(height: 12),
            ...pending.map((d) => _buildReceivedCard(d)),
            const SizedBox(height: 24),
          ],

          if (active.isNotEmpty) ...[
            _buildSectionHeader('✅ Accès accordés · ${active.length}'),
            const SizedBox(height: 12),
            ...active.map((d) => _buildReceivedCard(d)),
            const SizedBox(height: 24),
          ],

          if (rejected.isNotEmpty) ...[
            _buildSectionHeader('🚫 Demandes refusées · ${rejected.length}'),
            const SizedBox(height: 12),
            ...rejected.map((d) => _buildReceivedCard(d)),
          ],
        ],
      ),
    );
  }

  Widget _buildSentTab(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _buildEmptyState(
          'Aucune demande envoyée',
          'Scannez un QR code réseau social pour envoyer une demande d\'accès à un profil.');
    }

    return RefreshIndicator(
      onRefresh: () => _loadDemands(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildSentCard(list[index]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
    );
  }

  Widget _buildReceivedCard(Map<String, dynamic> d) {
    final network = d['networkType'] ?? 'Réseau';
    final name = d['requesterName'] ?? 'Utilisateur';
    final phone = d['requesterPhone'] ?? '';
    final status = d['status'] ?? 'pending';

    Color netColor = AppColors.primaryLight;
    IconData netIcon = Icons.person_rounded;

    if (network.toLowerCase() == 'snapchat') {
      netIcon = Icons.snapchat_rounded;
      netColor = const Color(0xFFFFFC00);
    } else if (network.toLowerCase() == 'instagram') {
      netIcon = Icons.camera_alt_rounded;
      netColor = const Color(0xFFE1306C);
    } else if (network.toLowerCase() == 'tiktok') {
      netIcon = Icons.music_note_rounded;
      netColor = const Color(0xFF00F2FE);
    }

    Color statusColor = AppColors.warning;
    String statusLabel = '⏳ En attente';
    if (status == 'accepted') {
      statusColor = AppColors.success;
      statusLabel = '✅ Accordé';
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusLabel = '🚫 Refusé';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == 'pending' ? AppColors.warning.withValues(alpha: 0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Person avatar
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w500, color: AppColors.primaryLight),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      Text(
                        phone,
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                // Network badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: netColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(netIcon, size: 14, color: netColor),
                      const SizedBox(width: 4),
                      Text(
                        network,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 10, fontWeight: FontWeight.w500, color: netColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Status + Actions
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _respond(d['id'], 'rejected'),
                      child: Text(
                        'Refuser',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: netColor == const Color(0xFFFFFC00)
                            ? Colors.black
                            : (netColor == AppColors.primaryLight ? AppColors.primary : netColor),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await _respond(d['id'], 'accepted');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name peut maintenant voir votre profil $network.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Accepter',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              netColor == const Color(0xFFFFFC00) ? netColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                    ),
                  ),
                  if (status == 'accepted')
                    TextButton.icon(
                      onPressed: () => _revoke(d['id']),
                      icon: const Icon(Icons.block_rounded, size: 14, color: AppColors.error),
                      label: Text(
                        'Révoquer',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentCard(Map<String, dynamic> d) {
    final network = d['networkType'] ?? 'Réseau';
    final targetPhone = d['targetUserPhone'] ?? '';
    final username = d['networkUsername'] ?? '';
    final status = d['status'] ?? 'pending';

    Color statusColor = AppColors.warning;
    String statusLabel = 'En attente';
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (status == 'accepted') {
      statusColor = AppColors.success;
      statusLabel = 'Acceptée';
      statusIcon = Icons.verified_user_rounded;
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusLabel = 'Refusée';
      statusIcon = Icons.block_rounded;
    }

    // netColor not used in the sent card UI; omit to avoid unused-variable warning

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demande sur $network',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                    Text(
                      '@$username · $targetPhone',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, fontWeight: FontWeight.w500, color: statusColor),
                ),
              ),
              if (status == 'accepted')
                TextButton.icon(
                  onPressed: () => _openSocialProfile(network, username),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: Text(
                    'Ouvrir le profil',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryLight),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_read_rounded,
                  size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
