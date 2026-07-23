import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/widgets/app_animations.dart';
import 'package:scanme_app/features/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Simplifiez vos\nPartages de Contacts',
      description: 'Générez des QR codes uniques pour votre numéro ou vos réseaux sociaux. Partagez instantanément en un scan, même hors-ligne.',
      icon: Icons.qr_code_2_rounded,
      color: AppColors.primary,
    ),
    OnboardingPageData(
      title: 'Contrôlez vos\nDonnées Privées',
      description: 'Rien n\'est partagé sans votre consentement. Acceptez ou refusez les demandes d\'accès en temps réel.',
      icon: Icons.security_rounded,
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: FadeSlideIn(
                    delayMs: 0,
                    slideOffset: 12,
                    child: TextButton(
                      onPressed: () => _navigateToLogin(context),
                      child: Text(
                        'Passer',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      final isActive = _currentIndex == index;
                      return AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingIcon(
                              icon: page.icon,
                              color: page.color,
                            ),
                            const SizedBox(height: 48),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutCubic,
                              child: Text(
                                page.title,
                                key: ValueKey('title-$index'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutCubic,
                              child: Text(
                                page.description,
                                key: ValueKey('desc-$index'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: _currentIndex == index ? 24.0 : 8.0,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? AppColors.primary : AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedScaleButton(
                onTap: () {
                  if (_currentIndex < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _navigateToLogin(context);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentIndex == _pages.length - 1 ? 'Commencer' : 'Continuer',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      SlideFadePageRoute(page: const LoginScreen()),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
