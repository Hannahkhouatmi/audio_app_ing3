import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'package:web_authn_web/web_authn_web.dart';

import 'biometric_result.dart';

const _credentialKey = 'webauthn_credential_id';
final _webAuthn = WebAuthnWeb();

/// Génère un challenge aléatoire encodé en base64url.
String _randomChallenge() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Identifiant du site (localhost en développement).
String _rpId() {
  final host = web.window.location.hostname;
  if (host.isEmpty || host == '127.0.0.1') {
    return 'localhost';
  }
  return host;
}

/// ID utilisateur encodé en base64 pour WebAuthn.
String _userIdBase64() {
  return base64.encode(utf8.encode('audio_app_user'));
}

/// Vérifie si WebAuthn est supporté par le navigateur (Chrome, Edge, etc.).
Future<bool> isBiometricAvailable() async {
  try {
    return web.window.isSecureContext;
  } catch (_) {
    return false;
  }
}

/// Vérifie si une empreinte Windows Hello / Touch ID est déjà enregistrée.
Future<bool> hasBiometricsEnrolled() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getString(_credentialKey);
  if (id != null && id.isNotEmpty) {
    return true;
  }
  return isBiometricAvailable();
}

/// Enregistre ou vérifie l'empreinte via WebAuthn (Windows Hello, Touch ID Mac).
Future<BiometricResult> authenticateBiometric() async {
  if (!await isBiometricAvailable()) {
    return BiometricResult.notAvailable;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_credentialKey);
    final challenge = _randomChallenge();
    final rpId = _rpId();

    if (storedId == null || storedId.isEmpty) {
      final result = await _webAuthn.register(
        PublicKeyCredentialCreationOptions(
          rp: RpEntity(name: 'Audio App Secure', id: rpId),
          user: UserEntity(
            name: 'utilisateur@audioapp.local',
            id: _userIdBase64(),
            displayName: 'Utilisateur Audio App',
          ),
          challenge: challenge,
          pubKeyCredParams: [
            PubKeyCredParam(type: 'public-key', alg: -7),
            PubKeyCredParam(type: 'public-key', alg: -257),
          ],
          timeout: 60000,
          authenticatorSelection: AuthenticatorSelectionCriteria(
            authenticatorAttachment: 'platform',
            residentKey: 'preferred',
            userVerification: 'required',
          ),
          attestation: 'none',
        ),
      );

      final credentialId = _extractCredentialId(result);
      if (credentialId == null || credentialId.isEmpty) {
        return BiometricResult.failed;
      }

      await prefs.setString(_credentialKey, credentialId);
      return BiometricResult.success;
    }

    await _webAuthn.sign(
      PublicKeyCredentialRequestOptions(
        challenge: challenge,
        rpId: rpId,
        timeout: 60000,
        userVerification: 'required',
        allowCredentials: [
          CredentialDescriptor(
            type: 'public-key',
            id: storedId,
            transports: const ['internal'],
          ),
        ],
      ),
    );
    return BiometricResult.success;
  } on WebAuthnWebException catch (e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('cancel') || msg.contains('abort')) {
      return BiometricResult.failed;
    }
    if (msg.contains('not allowed') || msg.contains('notallowed')) {
      return BiometricResult.notEnrolled;
    }
    return BiometricResult.failed;
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('notallowederror') || msg.contains('cancel')) {
      return BiometricResult.failed;
    }
    if (msg.contains('notsupported') || msg.contains('security')) {
      return BiometricResult.notAvailable;
    }
    return BiometricResult.failed;
  }
}

/// Extrait l'identifiant du credential depuis la réponse WebAuthn.
String? _extractCredentialId(Map<String, dynamic> result) {
  final id = result['id'];
  if (id is String && id.isNotEmpty) {
    return id;
  }
  final rawId = result['rawId'];
  if (rawId is String && rawId.isNotEmpty) {
    return rawId;
  }
  return null;
}

/// Sur le web, guide l'utilisateur vers la configuration Windows Hello.
Future<bool> openBiometricSettings() async {
  return false;
}
