import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import 'biometric_result.dart';

final LocalAuthentication _auth = LocalAuthentication();

bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// Vérifie si la biométrie est disponible
Future<bool> isBiometricAvailable() async {
  try {
    return await _auth.isDeviceSupported();
  } catch (_) {
    return false;
  }
}

/// Vérifie si une empreinte / visage est enregistré.
Future<bool> hasBiometricsEnrolled() async {
  try {
    if (_isDesktop) {
      return await _auth.isDeviceSupported();
    }
    final types = await _auth.getAvailableBiometrics();
    return types.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Authentification via empreinte
Future<BiometricResult> authenticateBiometric() async {
  try {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    if (!supported) {
      return BiometricResult.notAvailable;
    }

    if (!_isDesktop && !canCheck) {
      return BiometricResult.notEnrolled;
    }

    final success = await _auth.authenticate(
      localizedReason:
          'Veuillez vous authentifier pour accéder à l\'application',
      options: AuthenticationOptions(
        stickyAuth: true,
        // PC : Windows Hello / Touch ID accepte aussi le code PIN
        biometricOnly: !_isDesktop,
        useErrorDialogs: false,
      ),
    );
    return success ? BiometricResult.success : BiometricResult.failed;
  } on PlatformException catch (e) {
    switch (e.code) {
      case auth_error.notEnrolled:
        return BiometricResult.notEnrolled;
      case auth_error.lockedOut:
        return BiometricResult.lockedOut;
      case auth_error.permanentlyLockedOut:
        return BiometricResult.permanentlyLockedOut;
      case auth_error.notAvailable:
      case auth_error.passcodeNotSet:
      case auth_error.otherOperatingSystem:
        return BiometricResult.notAvailable;
      default:
        return BiometricResult.failed;
    }
  } catch (_) {
    return BiometricResult.failed;
  }
}

/// Ouvre les réglages système (sécurité / biométrie).
Future<bool> openBiometricSettings() async {
  try {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
    return true;
  } catch (_) {
    try {
      await AppSettings.openAppSettings();
      return true;
    } catch (_) {
      return false;
    }
  }
}
