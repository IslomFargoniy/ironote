import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/security_service.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_container.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const BiometricLockScreen({super.key, required this.onUnlocked});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = "";
  bool _isScanning = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNumberTap(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    final security = SecurityService();
    if (security.verifyPin(_enteredPin)) {
      widget.onUnlocked();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 PIN kod noto'g'ri! (Standart PIN: 2026)"),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _enteredPin = "";
      });
    }
  }

  void _triggerBiometricScan() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isScanning = false);

    // Biometric verified
    SecurityService().unlockApp();
    widget.onUnlocked();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ Barmoq izi orqali muvaffaqiyatli tasdiqlandi!"),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = DatabaseService().currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071517), Color(0xFF042F2E), Color(0xFF0A1C1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IroNote Official Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonGreen.withOpacity(0.3),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/ironote_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.lock_rounded, color: AppTheme.neonGreen, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // App Title
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("Iro", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text("Note", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.neonGreen)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    "Xush kelibsiz, ${user?.fullName ?? 'Foydalanuvchi'}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Kirish uchun 4 xonali PIN-kodni kiriting",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF8DAEB2)),
                  ),
                  const SizedBox(height: 20),

                  // Biometric Fingerprint Button with Neon Glow Animation
                  GestureDetector(
                    onTap: _triggerBiometricScan,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final glow = _animController.value * 12 + 6;
                        return Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0C2427),
                            border: Border.all(color: AppTheme.neonGreen, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGreen.withOpacity(0.4),
                                blurRadius: glow,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isScanning ? Icons.fingerprint_rounded : Icons.fingerprint,
                            size: 42,
                            color: AppTheme.neonGreen,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Barmoq izi orqali kirish",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.neonGreen),
                  ),
                  const SizedBox(height: 20),

                  // 4-Dot PIN Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppTheme.neonGreen : Colors.transparent,
                          border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonGreen.withOpacity(0.6),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Number Keypad
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: Column(
                      children: [
                        _buildKeypadRow(["1", "2", "3"]),
                        const SizedBox(height: 12),
                        _buildKeypadRow(["4", "5", "6"]),
                        const SizedBox(height: 12),
                        _buildKeypadRow(["7", "8", "9"]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSpecialKey(Icons.fingerprint, _triggerBiometricScan),
                            _buildNumberKey("0"),
                            _buildSpecialKey(Icons.backspace_outlined, _onDeleteTap),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Hint and Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          DatabaseService().logout();
                          SecurityService().lockApp();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFF8DAEB2)),
                        label: const Text("Hisobdan chiqish", style: TextStyle(color: Color(0xFF8DAEB2), fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberKey(n)).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    return GlassContainer(
      width: 62,
      height: 62,
      borderRadius: 31,
      padding: EdgeInsets.zero,
      onTap: () => _onNumberTap(number),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(IconData icon, VoidCallback onTap) {
    return GlassContainer(
      width: 62,
      height: 62,
      borderRadius: 31,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Center(
        child: Icon(icon, size: 22, color: AppTheme.neonGreen),
      ),
    );
  }
}

