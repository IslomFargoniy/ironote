import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChanged;
  final VoidCallback onSplashFinished;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageChanged,
    required this.onSplashFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _animController.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onSplashFinished();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonGreen.withOpacity(isDark ? 0.25 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentCyan.withOpacity(isDark ? 0.20 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Animated Logo and Branding
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value * (_animController.value > 0.6 ? _pulseAnim.value : 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Futuristic Glowing Logo Container
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.neonGreen,
                                AppTheme.neonGreenDark,
                                Color(0xFF064E3B),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGreen.withOpacity(isDark ? 0.5 : 0.35),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating outer ring
                              Transform.rotate(
                                angle: _animController.value * 2 * math.pi,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Core Icon
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 54,
                                color: Color(0xFF042F2E),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Title with Emerald Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppTheme.neonGreen,
                              Color(0xFF34D399),
                              Color(0xFF10B981),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'IRONOTE',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.5,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkCard.withOpacity(0.6)
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.neonGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppTranslations.getText(widget.currentLang, 'appSubtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor.withOpacity(0.85),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Sleek Loading Bar
                        SizedBox(
                          width: 140,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _animController.value,
                              backgroundColor: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.neonGreen,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Footer Branding
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'EMERALD FINTECH • SECURE & ACCURATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub).withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
