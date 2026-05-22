// ════════════════════════════════════════
// lib/main.dart
// ════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'ui/splash/splash_screen.dart';
import 'ui/biometric/biometric_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/auth/reset_password_screen.dart';
import 'ui/placeholder/placeholder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // JustAudioBackground — sera activé par le binôme
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'com.example.audio_app.channel.audio',
  //   androidNotificationChannelName: 'Audio Playback',
  //   androidNotificationOngoing: true,
  // );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Page avec transition en fondu (250ms, easeOut).
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

/// Fournisseur global GoRouter avec garde d'authentification.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (Firebase.apps.isEmpty) {
        return AppRoutes.splash;
      }

      final isAuth = FirebaseAuth.instance.currentUser != null;

      final goingToSplash = state.matchedLocation == AppRoutes.splash;
      final goingToLogin = state.matchedLocation == AppRoutes.login;
      final goingToRegister = state.matchedLocation == AppRoutes.register;
      final goingToReset = state.matchedLocation == AppRoutes.resetPass;
      final goingToBiometric = state.matchedLocation == AppRoutes.biometric;

      if (!isAuth &&
          !goingToSplash &&
          !goingToLogin &&
          !goingToRegister &&
          !goingToReset &&
          !goingToBiometric) {
        return AppRoutes.biometric;
      }

      if (isAuth &&
          (goingToLogin ||
              goingToRegister ||
              goingToReset ||
              goingToBiometric)) {
        return AppRoutes.stats;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _fadeTransition(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.biometric,
        pageBuilder: (context, state) =>
            _fadeTransition(state, const BiometricScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _fadeTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _fadeTransition(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPass,
        pageBuilder: (context, state) =>
            _fadeTransition(state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.stats,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const PlaceholderScreen(title: 'Statistiques'),
        ),
      ),
      GoRoute(
        path: AppRoutes.player,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const PlaceholderScreen(title: 'Lecteur Audio'),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const PlaceholderScreen(title: 'Favoris'),
        ),
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
      title: 'Audio App Secure',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
