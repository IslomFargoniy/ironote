import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal() {
    _loadSettings();
  }

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isPinEnabled = false;
  bool _isBiometricsEnabled = false;
  String _savedPin = '';
  bool _isLocked = false;

  bool get isPinEnabled => _isPinEnabled;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get hasPin => _savedPin.isNotEmpty;
  bool get isLocked => _isLocked && (_isPinEnabled || _isBiometricsEnabled);

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedPin = prefs.getString('security_pin_code') ?? '';
      _isPinEnabled = (prefs.getBool('security_pin_enabled') ?? false) && _savedPin.isNotEmpty;
      _isBiometricsEnabled = _isPinEnabled && (prefs.getBool('security_biometrics_enabled') ?? false);
      _isLocked = _isPinEnabled;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setPin(String pin) async {
    _savedPin = pin;
    _isPinEnabled = pin.isNotEmpty;
    _isLocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_pin_code', pin);
    await prefs.setBool('security_pin_enabled', _isPinEnabled);
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool enabled) async {
    _isBiometricsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('security_biometrics_enabled', enabled);
    notifyListeners();
  }

  Future<void> disableSecurity() async {
    _isPinEnabled = false;
    _isBiometricsEnabled = false;
    _savedPin = '';
    _isLocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('security_pin_enabled', false);
    await prefs.setBool('security_biometrics_enabled', false);
    await prefs.setString('security_pin_code', '');
    notifyListeners();
  }

  bool verifyPin(String enteredPin) {
    if (_savedPin.isNotEmpty && enteredPin == _savedPin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Whether the device has enrolled biometrics (fingerprint / face).
  Future<bool> canUseBiometrics() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system biometric prompt. Returns true only on real success.
  Future<bool> authenticateWithBiometrics(String reason) async {
    if (!_isBiometricsEnabled) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      if (ok) unlockApp();
      return ok;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  void lockApp() {
    if (_isPinEnabled || _isBiometricsEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }
}

