import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- 1. CHECK IF BIOMETRICS IS AVAILABLE ---
  Future<bool> isBiometricAvailable() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // --- 2. AUTHENTICATE USER ---
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // --- 3. SECURELY SAVE CREDENTIALS (Run this after normal login) ---
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  // --- 4. GET SAVED CREDENTIALS ---
  Future<Map<String, String>?> getCredentials() async {
    String? email = await _storage.read(key: 'email');
    String? password = await _storage.read(key: 'password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
