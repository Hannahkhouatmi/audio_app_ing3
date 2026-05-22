import 'biometric_result.dart';

Future<bool> isBiometricAvailable() async => false;

Future<bool> hasBiometricsEnrolled() async => false;

Future<BiometricResult> authenticateBiometric() async =>
    BiometricResult.notAvailable;

Future<bool> openBiometricSettings() async => false;
