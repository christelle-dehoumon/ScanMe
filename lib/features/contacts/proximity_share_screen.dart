import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/core/widgets/app_animations.dart';

enum _BumpPhase { waiting, approaching, connected, success }

/// Simulated proximity share — two phones "bump" to exchange contact.
class ProximityShareScreen extends ConsumerStatefulWidget {
  const ProximityShareScreen({super.key});

  @override
  ConsumerState<ProximityShareScreen> createState() => _ProximityShareScreenState();
}

class _ProximityShareScreenState extends ConsumerState<ProximityShareScreen>
    with TickerProviderStateMixin {
  _BumpPhase _phase = _BumpPhase.waiting;
  late AnimationController _approachController;
  late AnimationController _rippleController;
  late AnimationController _successController;
  late Animation<double> _phoneSlide;
  late Animation<double> _phoneShake;

  @override
  void initState() {
    super.initState();
    _approachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _phoneSlide = CurvedAnimation(parent: _approachController, curve: Curves.easeInOutCubic);
    _phoneShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));

    _approachController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _BumpPhase.connected);
        _rippleController.forward(from: 0);
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _phase = _BumpPhase.success);
          _successController.forward(from: 0);
          HapticFeedback.lightImpact();
        });
      }
    });
  }

  @override
  void dispose() {
    _approachController.dispose();
    _rippleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _startBump() {
    if (_phase != _BumpPhase.waiting) return;
    setState(() => _phase = _BumpPhase.approaching);
    HapticFeedback.selectionClick();
    _approachController.forward(from: 0);
  }

  void _reset() {
    _approachController.reset();
    _rippleController.reset();
    _successController.reset();
    setState(() => _phase = _BumpPhase.waiting);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final name = user?['name'] ?? 'Utilisateur';
    final phone = user?['phone'] ?? '+226 70 00 00 00';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tap Share'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              FadeSlideIn(
                child: Text(
                  _phase == _BumpPhase.success
                      ? 'Contact partagé !'
                      : 'Rapprochez les deux téléphones',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _phase == _BumpPhase.success
                    ? 'La personne en face a reçu votre numéro.'
                    : 'Maintenez le bouton pour simuler le partage.',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                height: 280,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_phoneSlide, _phoneShake, _rippleController]),
                  builder: (context, _) {
                    final slide = _phoneSlide.value;
                    final shake = _phoneShake.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_phase == _BumpPhase.connected || _phase == _BumpPhase.success)
                          ...List.generate(3, (i) {
                            final progress = (_rippleController.value - i * 0.25).clamp(0.0, 1.0);
                            return Container(
                              width: 80 + progress * 200,
                              height: 80 + progress * 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: (1 - progress) * 0.5),
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                        Transform.translate(
                          offset: Offset(-90 + slide * 70 + shake, shake * 0.3),
                          child: _phoneFrame(
                            label: 'Vous',
                            initial: name.isNotEmpty ? name[0].toUpperCase() : 'K',
                            color: AppColors.primary,
                            isLeft: true,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(90 - slide * 70 - shake, -shake * 0.3),
                          child: _phoneFrame(
                            label: 'Contact',
                            initial: '?',
                            color: AppColors.primaryLight,
                            isLeft: false,
                          ),
                        ),
                        if (_phase == _BumpPhase.approaching)
                          Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primary.withValues(alpha: _phoneSlide.value),
                            size: 28 + _phoneSlide.value * 12,
                          ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              if (_phase == _BumpPhase.success) ...[
                FadeSlideIn(
                  slideOffset: 16,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.success.withValues(alpha: 0.15),
                          child: const Icon(Icons.check_rounded, color: AppColors.success),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                              Text(phone, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                  child: const Text('Partager à nouveau'),
                ),
              ] else
                _HoldButton(
                  enabled: _phase == _BumpPhase.waiting,
                  onHoldStart: _startBump,
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.nfc_rounded, size: 16, color: AppColors.primaryLight.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode démo · Le vrai Tap Share utilisera NFC/BLE sur mobile.',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneFrame({
    required String label,
    required String initial,
    required Color color,
    required bool isLeft,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 170,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: Offset(isLeft ? 4 : -4, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(initial, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: color)),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  isLeft ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _HoldButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onHoldStart;

  const _HoldButton({required this.enabled, required this.onHoldStart});

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.enabled ? (_) {
        setState(() => _holding = true);
        widget.onHoldStart();
      } : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final scale = widget.enabled ? 1.0 + _pulse.value * 0.03 : 1.0;
          return Transform.scale(
            scale: _holding ? 0.96 : scale,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.enabled
                  ? [AppColors.primary, AppColors.primaryDark]
                  : [AppColors.textTertiary, AppColors.textTertiary],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.enabled
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Maintenir pour partager',
                style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
