import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/widgets/app_animations.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/features/scanner/universal_scanner_screen.dart';
import 'package:scanme_app/features/contacts/pending_demands_screen.dart';
import 'package:scanme_app/features/payments/transaction_history_screen.dart';
import 'package:scanme_app/features/profile/profile_screen.dart';
import 'package:scanme_app/features/contacts/personal_qrs_screen.dart';
import 'package:scanme_app/features/contacts/proximity_share_screen.dart';
import 'package:scanme_app/features/payments/payment_qr_list_screen.dart';
import 'package:scanme_app/features/payments/merchant_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = const [
      HomeTab(),
      PendingDemandsScreen(),
      TransactionHistoryScreen(),
      ProfileScreen(),
    ];
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Que voulez-vous faire ?',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            ActionSheetTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scanner un QR',
              subtitle: 'Contact, paiement ou réseau social',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(SpringPageRoute(page: const UniversalScannerScreen()));
              },
            ),
            ActionSheetTile(
              icon: Icons.phonelink_ring_rounded,
              title: 'Tap Share',
              subtitle: 'Rapprocher deux téléphones pour partager',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(SpringPageRoute(page: const ProximityShareScreen()));
              },
            ),
            ActionSheetTile(
              icon: Icons.qr_code_rounded,
              title: 'Mes QR codes',
              subtitle: 'Gérer contacts et réseaux sociaux',
              color: AppColors.orangeMoney,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(SpringPageRoute(page: const PersonalQrsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _tabs[_currentIndex]),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AnimatedNavItem(isSelected: _currentIndex == 0, icon: Icons.home_rounded, label: 'Accueil', onTap: () => setState(() => _currentIndex = 0)),
              AnimatedNavItem(isSelected: _currentIndex == 1, icon: Icons.mark_email_unread_rounded, label: 'Demandes', onTap: () => setState(() => _currentIndex = 1)),
              const SizedBox(width: 40),
              AnimatedNavItem(isSelected: _currentIndex == 2, icon: Icons.history_rounded, label: 'Historique', onTap: () => setState(() => _currentIndex = 2)),
              AnimatedNavItem(isSelected: _currentIndex == 3, icon: Icons.person_rounded, label: 'Profil', onTap: () => setState(() => _currentIndex = 3)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: PulseGlow(
        child: FloatingActionButton(
          onPressed: _showActionSheet,
          backgroundColor: AppColors.primary,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  int _shareMode = 0; // 0 = QR, 1 = Tap Share
  int _pendingCount = 0;
  int _socialQrCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final myPhone = ref.read(authRepositoryProvider).currentUser?['phone'] ?? '';
    final demands = await ref.read(contactsRepositoryProvider).getDemands();
    final qrs = await ref.read(contactsRepositoryProvider).getPersonalQrs();

    if (mounted) {
      setState(() {
        _pendingCount = demands.where((d) => d['targetUserPhone'] == myPhone && d['status'] == 'pending').length;
        _socialQrCount = qrs.where((q) => q['type'] == 'social').length;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final name = user?['name'] ?? 'Utilisateur ScanMe';
    final phone = user?['phone'] ?? '+226 70 00 00 00';
    final isMerchant = user?['accountType'] == 'commercant';

    final vCardData = 'BEGIN:VCARD\nVERSION:3.0\nFN:$name\nTEL;TYPE=CELL:$phone\nNOTE:ScanMe User\nEND:VCARD';

    return AnimatedGlowBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    Hero(
                      tag: 'avatar',
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.primaryLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                          Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    if (isMerchant)
                      AnimatedScaleButton(
                        onTap: () => Navigator.of(context).push(SpringPageRoute(page: const MerchantDashboardScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.orangeMoney.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.orangeMoney.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 18, color: AppColors.orangeMoney),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              FadeSlideIn(
                delayMs: 80,
                child: Row(
                  children: [
                    Expanded(
                      child: LiveStatCard(
                        label: 'Demandes en attente',
                        value: '$_pendingCount',
                        icon: Icons.mark_email_unread_rounded,
                        color: AppColors.warning,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LiveStatCard(
                        label: 'QR sociaux actifs',
                        value: '$_socialQrCount',
                        icon: Icons.hub_rounded,
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).push(SpringPageRoute(page: const PersonalQrsScreen())),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FadeSlideIn(
                delayMs: 140,
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      QuickActionChip(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scanner',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).push(SpringPageRoute(page: const UniversalScannerScreen())),
                      ),
                      const SizedBox(width: 10),
                      QuickActionChip(
                        icon: Icons.phonelink_ring_rounded,
                        label: 'Tap Share',
                        color: AppColors.success,
                        onTap: () => Navigator.of(context).push(SpringPageRoute(page: const ProximityShareScreen())),
                      ),
                      const SizedBox(width: 10),
                      QuickActionChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Paiement',
                        color: AppColors.orangeMoney,
                        onTap: () => Navigator.of(context).push(SpringPageRoute(page: const PaymentQrListScreen())),
                      ),
                      const SizedBox(width: 10),
                      QuickActionChip(
                        icon: Icons.qr_code_rounded,
                        label: 'Mes QR',
                        color: AppColors.primaryLight,
                        onTap: () => Navigator.of(context).push(SpringPageRoute(page: const PersonalQrsScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FadeSlideIn(
                delayMs: 200,
                child: SegmentedToggle(
                  labels: const ['Mon QR', 'Tap Share'],
                  selectedIndex: _shareMode,
                  onChanged: (i) => setState(() => _shareMode = i),
                ),
              ),

              const SizedBox(height: 20),

              FadeSlideIn(
                delayMs: 260,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _shareMode == 0
                      ? Center(
                          key: const ValueKey('qr'),
                          child: ShimmerBorder(
                            child: Container(
                              width: 280,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  Text('Scanner pour mon contact', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  Text('Partage direct · hors-ligne', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                    child: QrImageView(
                                      data: vCardData,
                                      version: QrVersions.auto,
                                      size: 190,
                                      gapless: false,
                                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF13121A)),
                                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF13121A)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(phone, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primaryLight)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _TapSharePreviewCard(
                          key: const ValueKey('tap'),
                          onStart: () => Navigator.of(context).push(SpringPageRoute(page: const ProximityShareScreen())),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapSharePreviewCard extends StatefulWidget {
  final VoidCallback onStart;

  const _TapSharePreviewCard({super.key, required this.onStart});

  @override
  State<_TapSharePreviewCard> createState() => _TapSharePreviewCardState();
}

class _TapSharePreviewCardState extends State<_TapSharePreviewCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedScaleButton(
        onTap: widget.onStart,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text('Tap Share', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Comme NameDrop sur iPhone', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(height: 24),
              SizedBox(
                height: 100,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(-30 + t * 18, 0),
                          child: _miniPhone(AppColors.primary),
                        ),
                        Transform.translate(
                          offset: Offset(30 - t * 18, 0),
                          child: _miniPhone(AppColors.success),
                        ),
                        Icon(Icons.bolt_rounded, color: AppColors.success.withValues(alpha: t), size: 20),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Appuyer pour lancer →',
                  style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPhone(Color color) {
    return Container(
      width: 44,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
    );
  }
}
