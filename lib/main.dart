import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scanme_app/firebase_options.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/database/hive_service.dart';
import 'package:scanme_app/core/providers/repositories.dart';
import 'package:scanme_app/features/onboarding/onboarding_screen.dart';
import 'package:scanme_app/features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase (auth, etc.) — nécessite lib/firebase_options.dart,
  // généré par `flutterfire configure`.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive Database local cache
  await HiveService.init();

  runApp(
    const ProviderScope(
      child: ScanMeApp(),
    ),
  );
}

class ScanMeApp extends ConsumerWidget {
  const ScanMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Auth state stream to dynamically route the user
    final authState = ref.watch(authRepositoryProvider);
    final user = authState.currentUser;

    return MaterialApp(
      title: 'ScanMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: user == null ? const OnboardingScreen() : const HomeScreen(),
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeOutCubic,
    );
  }
}
