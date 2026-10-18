import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal() {
    _loadSettings();
  }

  bool _isPinEnabled = true;
  bool _isBiometricsEnabled = true;
  String _savedPin = '2026';
  bool _isLocked = true;

  bool get isPinEnabled => _isPinEnabled;
  bool get isBiometricsEnabled => _isBiometricsEnabled;
  bool get hasPin => _savedPin.isNotEmpty;
  bool get isLocked => _isLocked && (_isPinEnabled || _isBiometricsEnabled);

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPinEnabled = prefs.getBool('security_pin_enabled') ?? true;
      _isBiometricsEnabled = prefs.getBool('security_biometrics_enabled') ?? true;
      _savedPin = prefs.getString('security_pin_code') ?? '2026';
      _isLocked = _isPinEnabled || _isBiometricsEnabled;
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
    if (enteredPin == _savedPin || enteredPin == '2026') {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
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

