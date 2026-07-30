import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

class BiometricService {
  static const _enabledKey = 'biometric_unlock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  Future<void> setEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(_enabledKey, enabled);

  Future<bool> isAvailable() async =>
      await _auth.canCheckBiometrics &&
      (await _auth.getAvailableBiometrics()).isNotEmpty;

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Buka NALA dengan biometrik',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockSavedSession() async {
    if (!await isEnabled() || await TokenStorage.readRefresh() == null) {
      return false;
    }
    return authenticate();
  }
}
