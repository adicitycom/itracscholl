import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuth {
  static const String BIOMETRIC_ENABLED_KEY = 'biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();
  SharedPreferences? _prefs;

  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get isBiometricEnabled => _isBiometricEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isBiometricAvailable = await _auth.canCheckBiometrics;

      if (_isBiometricAvailable) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
        _isBiometricEnabled = _prefs?.getBool(BIOMETRIC_ENABLED_KEY) ?? false;

        print('[BiometricAuth] Available: $_isBiometricAvailable');
        print('[BiometricAuth] Enabled: $_isBiometricEnabled');
        print('[BiometricAuth] Types: $_availableBiometrics');
      }
    } catch (e) {
      print('[BiometricAuth] Error during initialization: $e');
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!_isBiometricAvailable || !_isBiometricEnabled) {
        print('[BiometricAuth] Biometric not available or not enabled');
        return false;
      }

      print('[BiometricAuth] Starting authentication...');
      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      print('[BiometricAuth] Authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      print('[BiometricAuth] Authentication error: $e');
      return false;
    }
  }

  Future<void> enableBiometric() async {
    try {
      if (!_isBiometricAvailable) {
        throw Exception('Biometric not available on this device');
      }

      _isBiometricEnabled = true;
      await _prefs?.setBool(BIOMETRIC_ENABLED_KEY, true);
      print('[BiometricAuth] Biometric enabled');
    } catch (e) {
      print('[BiometricAuth] Error enabling biometric: $e');
      rethrow;
    }
  }

  Future<void> disableBiometric() async {
    try {
      _isBiometricEnabled = false;
      await _prefs?.setBool(BIOMETRIC_ENABLED_KEY, false);
      print('[BiometricAuth] Biometric disabled');
    } catch (e) {
      print('[BiometricAuth] Error disabling biometric: $e');
      rethrow;
    }
  }

  String get biometricName {
    if (_availableBiometrics.isEmpty) return 'Biometric';
    if (_availableBiometrics.contains(BiometricType.face)) return 'Face ID';
    if (_availableBiometrics.contains(BiometricType.fingerprint)) return 'Fingerprint';
    return 'Biometric';
  }
}
