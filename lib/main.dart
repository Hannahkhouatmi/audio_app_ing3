// ════════════════════════════════════════
// lib/main.dart
// ════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'ui/splash/splash_screen.dart';
import 'ui/biometric/biometric_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/auth/reset_password_screen.dart';
import 'ui/shell/main_shell.dart';
import 'ui/stats/stats_screen.dart';
import 'ui/quran/quran_screen.dart';
import 'ui/favorites/favorites_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);

  if (!kIsWeb) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.ing3.usthb.audio_app_ing3.audio',
        androidNotificationChannelName: 'Quran Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      );
    } catch (_) {}
  }

  runApp(const ProviderScope(child: MyApp()));
}

Page<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: pageChild,
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (Firebase.apps.isEmpty) return AppRoutes.splash;

      final isAuth = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;

      final isPublicRoute =
          location == AppRoutes.splash ||
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.resetPass ||
          location == AppRoutes.biometric;

      if (!isAuth && !isPublicRoute) return AppRoutes.biometric;

      if (isAuth &&
          (location == AppRoutes.login ||
              location == AppRoutes.register ||
              location == AppRoutes.resetPass ||
              location == AppRoutes.biometric)) {
        return AppRoutes.quran; // Quran as home
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fadeTransition(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.biometric,
        pageBuilder: (context, state) => _fadeTransition(state, const BiometricScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadeTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _fadeTransition(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPass,
        pageBuilder: (context, state) => _fadeTransition(state, const ResetPasswordScreen()),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quran,
                pageBuilder: (context, state) => _fadeTransition(state, const QuranScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                pageBuilder: (context, state) => _fadeTransition(state, const FavoritesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                pageBuilder: (context, state) => _fadeTransition(state, const StatsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Quran App Secure',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
