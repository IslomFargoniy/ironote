import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';
import '../analytics/analytics_screen.dart';
import '../contacts/contacts_screen.dart';
import '../debt/debt_form_screen.dart';
import '../notifications/reminders_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String currentLang;
  final bool isDarkMode;
  final Function(String) onLanguageChanged;
  final VoidCallback onThemeToggle;

  const MainNavigationScreen({
    super.key,
    required this.currentLang,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeToggle,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        DashboardScreen(
          currentLang: widget.currentLang,
          isDarkMode: widget.isDarkMode,
          onLanguageChanged: widget.onLanguageChanged,
          onThemeToggle: widget.onThemeToggle,
        ),
        AnalyticsScreen(
          currentLang: widget.currentLang,
          onBackToHome: () => setState(() => _currentIndex = 0),
        ),
        RemindersScreen(currentLang: widget.currentLang),
        ContactsScreen(currentLang: widget.currentLang),
        SettingsScreen(
          currentLang: widget.currentLang,
          isDarkMode: widget.isDarkMode,
          onLanguageChanged: widget.onLanguageChanged,
          onThemeToggle: widget.onThemeToggle,
        ),
      ];

  void _openAddDebt() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DebtFormScreen(currentLang: widget.currentLang),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNotchedBottomBar(isDark),
    );
  }

  Widget _buildNotchedBottomBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0A1E20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1B3B3E) : const Color(0xFFE2E8F0);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barHeight = 84.0 + bottomInset;

    return SizedBox(
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Curved Notched Bar Canvas (Extends completely to screen bottom)
          Positioned.fill(
            top: 14,
            child: CustomPaint(
              painter: _CurvedNotchPainter(
                backgroundColor: bgColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
          ),

          // 2. Navigation Items Row with bottom inset padding
          Positioned.fill(
            top: 14,
            bottom: bottomInset > 0 ? bottomInset * 0.6 : 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Left 2 items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: AppTranslations.get('navHome', widget.currentLang),
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart_rounded,
                        label: AppTranslations.get('navAnalytics', widget.currentLang),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Center Notch Gap
                const SizedBox(width: 76),

                // Right 2 items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 2,
                        icon: Icons.notifications_none_rounded,
                        activeIcon: Icons.notifications_rounded,
                        label: AppTranslations.get('navReminders', widget.currentLang),
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings_rounded,
                        label: AppTranslations.get('navSettings', widget.currentLang),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Center Floating Action Button (in the Notch) - PLUS ICON (+)
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: _openAddDebt,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6EE7B7), // Mint green top
                      Color(0xFF10B981), // Emerald green bottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF0A1E20) : Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = AppTheme.neonGreen;
    final inactiveColor = isDark ? const Color(0xFF7E9DA4) : const Color(0xFF64748B);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws the curved scooped notch in the navigation bar top edge
class _CurvedNotchPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final bool isDark;

  _CurvedNotchPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    const notchRadius = 38.0; // Radius of center circular cutout
    const shoulderWidth = 26.0; // Width of the smooth curve transition
    const dipDepth = 32.0; // Depth of the scooped notch

    final path = Path();
    path.moveTo(0, 0);

    // 1. Left top horizontal edge
    path.lineTo(cx - notchRadius - shoulderWidth, 0);

    // 2. Smooth bezier curve sloping down into notch
    path.cubicTo(
      cx - notchRadius - 6,
      0,
      cx - notchRadius + 4,
      dipDepth,
      cx - notchRadius * 0.45,
      dipDepth,
    );

    // 3. Bottom of notch under the button
    path.cubicTo(
      cx - notchRadius * 0.2,
      dipDepth + 2,
      cx + notchRadius * 0.2,
      dipDepth + 2,
      cx + notchRadius * 0.45,
      dipDepth,
    );

    // 4. Smooth bezier curve sloping back up to horizontal edge
    path.cubicTo(
      cx + notchRadius - 4,
      dipDepth,
      cx + notchRadius + 6,
      0,
      cx + notchRadius + shoulderWidth,
      0,
    );

    // 5. Right top horizontal edge
    path.lineTo(w, 0);

    // 6. Right side, bottom, and left side
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Draw drop shadow
    canvas.drawShadow(
      path,
      isDark ? Colors.black.withOpacity(0.7) : AppTheme.neonGreen.withOpacity(0.18),
      16,
      true,
    );

    // Fill background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // Draw subtle top edge border
    final borderPath = Path();
    borderPath.moveTo(0, 0);
    borderPath.lineTo(cx - notchRadius - shoulderWidth, 0);
    borderPath.cubicTo(
      cx - notchRadius - 6,
      0,
      cx - notchRadius + 4,
      dipDepth,
      cx - notchRadius * 0.45,
      dipDepth,
    );
    borderPath.cubicTo(
      cx - notchRadius * 0.2,
      dipDepth + 2,
      cx + notchRadius * 0.2,
      dipDepth + 2,
      cx + notchRadius * 0.45,
      dipDepth,
    );
    borderPath.cubicTo(
      cx + notchRadius - 4,
      dipDepth,
      cx + notchRadius + 6,
      0,
      cx + notchRadius + shoulderWidth,
      0,
    );
    borderPath.lineTo(w, 0);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.isDark != isDark;
}

