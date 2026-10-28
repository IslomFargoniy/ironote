import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class LoginScreen extends StatefulWidget {
  final String currentLang;
  final bool isDarkMode;
  final Function(String) onLanguageChanged;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    Key? key,
    required this.currentLang,
    this.isDarkMode = false,
    required this.onLanguageChanged,
    this.onThemeToggle,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0 = Login, 1 = Register

  // Login Controllers
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _rememberMe = true;

  // Register Controllers
  final _regFullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _regObscure = true;

  // Animation Controllers
  late AnimationController _entranceController;
  late AnimationController _ambientFloatController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    ));

    _ambientFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientFloatController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regUsernameController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  String t(String key) => AppTranslations.getText(widget.currentLang, key);

  void _switchTab(int index) {
    if (_selectedTabIndex == index) return;
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _handleLogin() {
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(
        widget.currentLang == 'ru'
            ? 'Пожалуйста, введите логин и пароль!'
            : (widget.currentLang == 'en'
                ? 'Please enter username and password!'
                : 'Iltimos, login va parolni kiriting!'),
        isError: true,
      );
      return;
    }

    final success = DatabaseService().login(username, password);
    if (success) {
      widget.onLoginSuccess?.call();
    } else {
      _showSnackBar(t('invalidCredentials'), isError: true);
    }
  }

  void _handleRegister() {
    final fullName = _regFullNameController.text.trim();
    final username = _regUsernameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(
        widget.currentLang == 'ru'
            ? 'Пожалуйста, заполните логин и пароль!'
            : (widget.currentLang == 'en'
                ? 'Please enter username and password!'
                : 'Iltimos, login va parolni kiriting!'),
        isError: true,
      );
      return;
    }

    final success = DatabaseService().register(
      fullName: fullName.isEmpty ? username : fullName,
      username: username,
      phone: phone,
      email: '$username@ironote.uz',
      dateOfBirth: '1995-01-01',
      password: password,
    );

    if (success) {
      _showSnackBar(widget.currentLang == 'ru'
          ? 'Регистрация успешна! Добро пожаловать!'
          : (widget.currentLang == 'en'
              ? 'Registration successful! Welcome!'
              : 'Muvaffaqiyatli ro\'yxatdan o\'tdingiz! Xush kelibsiz!'));
      widget.onLoginSuccess?.call();
    }
  }

  void _handleDemoLogin() {
    _loginUsernameController.text = "azizbek";
    _loginPasswordController.text = "Password123!";
    DatabaseService().login("azizbek", "Password123!");
    widget.onLoginSuccess?.call();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppTheme.danger : AppTheme.neonGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLanguageSelector() {
    final isDark = widget.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final languages = [
          {'code': 'uz', 'name': "O'zbekcha (Lotin)", 'flag': '🇺🇿'},
          {'code': 'uz_cyr', 'name': 'Ўзбекча (Кирилл)', 'flag': '🇺🇿'},
          {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
          {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppTheme.neonGreen, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Tilni tanlang / Select Language',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...languages.map((l) {
                  final isSelected = widget.currentLang == l['code'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.neonGreen.withOpacity(0.15)
                          : (isDark ? AppTheme.darkInput : AppTheme.lightInput),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.neonGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        l['name']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen)
                          : null,
                      onTap: () {
                        widget.onLanguageChanged(l['code']!);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain;
    final textSecondary = isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonGreen.withOpacity(isDark ? 0.22 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0 + MediaQuery.of(context).padding.bottom),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top Bar (Language Selector & Theme Toggle)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: _showLanguageSelector,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.language_rounded, size: 16, color: AppTheme.neonGreen),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.currentLang.toUpperCase(),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                                        ),
                                        const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.neonGreen),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onThemeToggle,
                                  icon: Icon(
                                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    size: 20,
                                    color: isDark ? AppTheme.warning : AppTheme.neonGreenDark,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: cardBg,
                                    side: BorderSide(color: borderColor),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Floating Logo
                            AnimatedBuilder(
                              animation: _ambientFloatController,
                              builder: (context, child) {
                                final floatY = math.sin(_ambientFloatController.value * 2 * math.pi) * 4.0;
                                return Transform.translate(offset: Offset(0, floatY), child: child);
                              },
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.neonGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.neonGreen.withOpacity(isDark ? 0.45 : 0.3),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 42,
                                    color: Color(0xFF042F2E),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Brand Name
                            const Text(
                              "IroNote",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: AppTheme.neonGreen,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Dynamic Title & Subtitle
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Column(
                                key: ValueKey(_selectedTabIndex),
                                children: [
                                  Text(
                                    _selectedTabIndex == 0 ? t('welcomeBack') : t('registerTab'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedTabIndex == 0 ? t('loginSubtitle') : t('registerSubtitle'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Tab Switcher (Login / Register)
                            Container(
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkInput : AppTheme.lightBgSecondary,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTabButton(
                                      title: t('login'),
                                      isSelected: _selectedTabIndex == 0,
                                      onTap: () => _switchTab(0),
                                      isDark: isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTabButton(
                                      title: t('register'),
                                      isSelected: _selectedTabIndex == 1,
                                      onTap: () => _switchTab(1),
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Full-width, mobile-optimized Form
                            AnimatedCrossFade(
                              firstChild: _buildLoginForm(isDark, textPrimary, textSecondary, borderColor),
                              secondChild: _buildRegisterForm(isDark, textPrimary, textSecondary, borderColor),
                              crossFadeState: _selectedTabIndex == 0 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 300),
                            ),

                            const SizedBox(height: 18),

                            const SizedBox(height: 24),

                            // Footer Tagline
                            Text(
                              "XAVFSIZ • TEZKOR • AQLLI MOLIYA",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: textSecondary.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkCard : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.neonGreen : (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
          ),
        ),
      ),
    );
  }

  // --- LOGIN FORM (100% Full Width & Mobile Ergonomic) ---
  Widget _buildLoginForm(bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _loginUsernameController,
          hintText: t('usernameOrEmail'),
          prefixIcon: Icons.person_rounded,
          textInputAction: TextInputAction.next,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          controller: _loginPasswordController,
          hintText: t('password'),
          prefixIcon: Icons.lock_rounded,
          obscureText: _loginObscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          suffixIcon: IconButton(
            icon: Icon(
              _loginObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _loginObscure = !_loginObscure),
          ),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _rememberMe ? AppTheme.neonGreen : (isDark ? AppTheme.darkInput : AppTheme.lightInput),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _rememberMe ? AppTheme.neonGreen : borderColor,
                      ),
                    ),
                    child: _rememberMe
                        ? const Icon(Icons.check_rounded, color: Color(0xFF042F2E), size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t('rememberMe'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _handleDemoLogin,
              icon: const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.neonGreen),
              label: Text(
                t('demoLogin'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.neonGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          title: t('login'),
          icon: Icons.login_rounded,
          onPressed: _handleLogin,
        ),
      ],
    );
  }

  // --- REGISTER FORM (100% Full Width, Clean Linear Layout) ---
  Widget _buildRegisterForm(bool isDark, Color textPrimary, Color textSecondary, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _regFullNameController,
          hintText: t('fullName'),
          prefixIcon: Icons.badge_rounded,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _regUsernameController,
          hintText: t('username'),
          prefixIcon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.next,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _regPhoneController,
          hintText: t('phone'),
          prefixIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _regPasswordController,
          hintText: t('password'),
          prefixIcon: Icons.lock_rounded,
          obscureText: _regObscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleRegister(),
          suffixIcon: IconButton(
            icon: Icon(
              _regObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _regObscure = !_regObscure),
          ),
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          title: t('register'),
          icon: Icons.person_add_rounded,
          onPressed: _handleRegister,
        ),
      ],
    );
  }

  // --- BEAUTIFUL MODERN FULL-WIDTH INPUT FIELD ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkInput : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: textSecondary.withOpacity(0.65),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(prefixIcon, color: AppTheme.neonGreen, size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // --- PRIMARY GRADIENT BUTTON ---
  Widget _buildPrimaryButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.neonGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonGreen.withOpacity(0.4),
              offset: const Offset(0, 4),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF042F2E),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: const Color(0xFF042F2E), size: 20),
          ],
        ),
      ),
    );
  }}
