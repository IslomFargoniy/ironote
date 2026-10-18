import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/biometric_lock_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/database_service.dart';
import 'services/security_service.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IronoteApp());
}

class IronoteApp extends StatefulWidget {
  const IronoteApp({super.key});

  @override
  State<IronoteApp> createState() => _IronoteAppState();
}

class _IronoteAppState extends State<IronoteApp> {
  bool _isDarkMode = true;
  String _currentLang = 'uz';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isDarkMode = prefs.getBool('app_dark_mode') ?? true;
          _currentLang = prefs.getString('app_language') ?? 'uz';
        });
      }
    } catch (_) {}
  }

  void _toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_dark_mode', _isDarkMode);
    } catch (_) {}
  }

  void _changeLanguage(String lang) async {
    setState(() => _currentLang = lang);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([DatabaseService(), SecurityService()]),
      builder: (context, _) {
        return MaterialApp(
          title: 'IroNote - Emerald Fintech Qarz Daftari',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: AppGatekeeper(
            isDarkMode: _isDarkMode,
            currentLang: _currentLang,
            onThemeToggle: _toggleTheme,
            onLanguageChanged: _changeLanguage,
          ),
        );
      },
    );
  }
}

class AppGatekeeper extends StatefulWidget {
  final bool isDarkMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChanged;

  const AppGatekeeper({
    super.key,
    required this.isDarkMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageChanged,
  });

  @override
  State<AppGatekeeper> createState() => _AppGatekeeperState();
}

class _AppGatekeeperState extends State<AppGatekeeper> {
  bool _showSplash = true;
  bool _hasSeenOnboarding = false;
  bool _isBiometricUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = seen;
      });
    }
  }

  void _onSplashFinished() {
    setState(() {
      _showSplash = false;
    });
  }

  void _onOnboardingCompleted() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  void _unlockBiometric() {
    setState(() {
      _isBiometricUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        isDarkMode: widget.isDarkMode,
        currentLang: widget.currentLang,
        onThemeToggle: widget.onThemeToggle,
        onLanguageChanged: widget.onLanguageChanged,
        onSplashFinished: _onSplashFinished,
      );
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        isDarkMode: widget.isDarkMode,
        currentLang: widget.currentLang,
        onThemeToggle: widget.onThemeToggle,
        onLanguageChanged: widget.onLanguageChanged,
        onCompleted: _onOnboardingCompleted,
      );
    }

    final currentUser = DatabaseService().currentUser;
    final security = SecurityService();

    if (currentUser == null) {
      return LoginScreen(
        currentLang: widget.currentLang,
        isDarkMode: widget.isDarkMode,
        onLanguageChanged: widget.onLanguageChanged,
        onThemeToggle: widget.onThemeToggle,
      );
    }

    if (security.isPinEnabled && (security.isLocked || !_isBiometricUnlocked)) {
      return BiometricLockScreen(
        onUnlocked: () {
          security.unlockApp();
          _unlockBiometric();
        },
      );
    }

    return MainNavigationScreen(
      currentLang: widget.currentLang,
      isDarkMode: widget.isDarkMode,
      onLanguageChanged: widget.onLanguageChanged,
      onThemeToggle: widget.onThemeToggle,
    );
  }
}
