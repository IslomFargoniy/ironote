import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isDarkMode;
  final String currentLang;
  final VoidCallback onThemeToggle;
  final Function(String) onLanguageChanged;
  final VoidCallback? onCompleted;

  const OnboardingScreen({
    super.key,
    required this.isDarkMode,
    required this.currentLang,
    required this.onThemeToggle,
    required this.onLanguageChanged,
    this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
          currentLang: widget.currentLang,
          isDarkMode: widget.isDarkMode,
          onLanguageChanged: widget.onLanguageChanged,
          onThemeToggle: widget.onThemeToggle,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  List<Map<String, dynamic>> _getSlides() {
    final lang = widget.currentLang;

    final slidesData = {
      'uz': [
        {
          'title': 'Aqlli Qarz Daftari',
          'highlight': '100% Aniq Hisob-Kitob',
          'description':
              'Barcha berilgan va olingan qarzlarni bir joyda qulay jamlang. Har bir to\'lov va qoldiqni avtomatlashtirilgan tarzda nazorat qiling.',
          'icon': Icons.account_balance_wallet_rounded,
          'badge1': 'Kirim & Chiqim',
          'badge2': 'Valyuta konvertatsiyasi',
          'badge3': '0% Xatolik',
          'color': AppTheme.neonGreen,
        },
        {
          'title': 'Tilxat & Xavfsizlik',
          'highlight': 'Biometrik & GPS Audit',
          'description':
              'Qarz berishda tilxat fotosurati va joylashuvni (GPS) saqlang. Face ID, Barmoq izi va PIN-kod bilan ma\'lumotlaringiz to\'liq himoyalangan.',
          'icon': Icons.security_rounded,
          'badge1': 'Biometrik Face/Touch ID',
          'badge2': 'Tilxat Fotosurati',
          'badge3': 'GPS Joylashuv',
          'color': AppTheme.accentCyan,
        },
        {
          'title': 'Eslatmalar & Telegram',
          'highlight': 'Bir Tugmada Xabar',
          'description':
              'Qaytarish muddati kelganda ilova sizni ogohlantiradi. Qarzdorlarga Telegram orqali bitta tugmada professional eslatma va tilxat yuboring.',
          'icon': Icons.send_rounded,
          'badge1': 'Telegram Eslatma',
          'badge2': 'PDF & Excel Eksport',
          'badge3': 'Avto Ogohlantirish',
          'color': const Color(0xFF10B981),
        },
      ],
      'uz_cyr': [
        {
          'title': 'Ақлли Қарз Дафтари',
          'highlight': '100% Аниқ Ҳисоб-Китоб',
          'description':
              'Барча берилган ва олинган қарзларни бир жойда қулай жамланг. Ҳар бир тўлов ва қолдиқни автоматлаштирилган тарзда назорат қилинг.',
          'icon': Icons.account_balance_wallet_rounded,
          'badge1': 'Кирим & Чиқим',
          'badge2': 'Валюта конвертацияси',
          'badge3': '0% Хатолик',
          'color': AppTheme.neonGreen,
        },
        {
          'title': 'Тилхат & Хавфсизлик',
          'highlight': 'Биометрик & GPS Аудит',
          'description':
              'Қарз беришда тилхат фотосурати ва жойлашувни (GPS) сақланг. Face ID, Бармоқ изи ва PIN-код билан маълумотларингиз тўлиқ ҳимояланган.',
          'icon': Icons.security_rounded,
          'badge1': 'Биометрик Face/Touch ID',
          'badge2': 'Тилхат Фотосурати',
          'badge3': 'GPS Жойлашув',
          'color': AppTheme.accentCyan,
        },
        {
          'title': 'Эслатмалар & Telegram',
          'highlight': 'Бир Тугмада Хабар',
          'description':
              'Қайтариш муддати келганда илова сизни огоҳлантиради. Қарздорларга Telegram орқали битта тугмада профессионал эслатма ва тилхат юборинг.',
          'icon': Icons.send_rounded,
          'badge1': 'Telegram Эслатма',
          'badge2': 'PDF & Excel Экспорт',
          'badge3': 'Авто Огоҳлантириш',
          'color': const Color(0xFF10B981),
        },
      ],
      'ru': [
        {
          'title': 'Умная Долговая Книга',
          'highlight': '100% Точный Учет Финансов',
          'description':
              'Контролируйте все выданные и взятые долги в одном месте. Автоматический расчет остатков, платежей и поддержка любых валют.',
          'icon': Icons.account_balance_wallet_rounded,
          'badge1': 'Доходы & Расходы',
          'badge2': 'Мультивалютность',
          'badge3': '0% Ошибок',
          'color': AppTheme.neonGreen,
        },
        {
          'title': 'Расписки & Безопасность',
          'highlight': 'Биометрия и Фото Расписок',
          'description':
              'Прикрепляйте фото расписок и GPS локацию. Надежная защита данных через Face ID, сканер отпечатка пальца и PIN-код.',
          'icon': Icons.security_rounded,
          'badge1': 'Face ID / Touch ID',
          'badge2': 'Фото расписок',
          'badge3': 'GPS Координаты',
          'color': AppTheme.accentCyan,
        },
        {
          'title': 'Уведомления & Telegram',
          'highlight': 'Напоминания в 1 клик',
          'description':
              'Умные напоминания о сроках возврата долгов. Отправляйте готовые квитанции и уведомления должникам через Telegram за секунду.',
          'icon': Icons.send_rounded,
          'badge1': 'Telegram интеграция',
          'badge2': 'Экспорт в Excel/PDF',
          'badge3': 'Авто-напоминания',
          'color': const Color(0xFF10B981),
        },
      ],
      'en': [
        {
          'title': 'Smart Debt Ledger',
          'highlight': '100% Accurate Finance Tracking',
          'description':
              'Manage all debts given and taken in one secure dashboard. Real-time balance calculations, multi-currency and zero errors.',
          'icon': Icons.account_balance_wallet_rounded,
          'badge1': 'Income & Debts',
          'badge2': 'Multi-Currency',
          'badge3': 'Zero Error',
          'color': AppTheme.neonGreen,
        },
        {
          'title': 'Receipts & Security',
          'highlight': 'Biometrics & GPS Auditing',
          'description':
              'Attach photo receipts, notes, and exact GPS locations. Safeguard your financial records with Face ID, Fingerprint and PIN lock.',
          'icon': Icons.security_rounded,
          'badge1': 'Biometric Face/Touch',
          'badge2': 'Photo Receipts',
          'badge3': 'GPS Geolocation',
          'color': AppTheme.accentCyan,
        },
        {
          'title': 'Reminders & Telegram',
          'highlight': '1-Tap Instant Messaging',
          'description':
              'Never miss a due date. Send customized friendly debt reminder notices to debtors via Telegram and export to Excel/PDF anytime.',
          'icon': Icons.send_rounded,
          'badge1': 'Telegram Fast Send',
          'badge2': 'Excel & PDF Export',
          'badge3': 'Smart Alarms',
          'color': const Color(0xFF10B981),
        },
      ],
    };

    return slidesData[lang] ?? slidesData['uz']!;
  }

  String _getSkipLabel() {
    switch (widget.currentLang) {
      case 'ru':
        return 'Пропустить';
      case 'en':
        return 'Skip';
      case 'uz_cyr':
        return 'Ўтказиб юбориш';
      default:
        return 'O\'tkazib yuborish';
    }
  }

  String _getNextLabel() {
    if (_currentPage == 2) {
      switch (widget.currentLang) {
        case 'ru':
          return 'Начать';
        case 'en':
          return 'Get Started';
        case 'uz_cyr':
          return 'Бошлаш';
        default:
          return 'Boshlash';
      }
    } else {
      switch (widget.currentLang) {
        case 'ru':
          return 'Далее';
        case 'en':
          return 'Next';
        case 'uz_cyr':
          return 'Кейингиси';
        default:
          return 'Keyingisi';
      }
    }
  }

  void _showLanguageDialog() {
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
    final textColor = isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain;
    final subTextColor = isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub;
    final slides = _getSlides();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Theme, Language and SKIP Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Language Selector Chip
                  InkWell(
                    onTap: _showLanguageDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, size: 16, color: AppTheme.neonGreen),
                          const SizedBox(width: 6),
                          Text(
                            widget.currentLang.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.neonGreen),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Theme Toggle Button
                  IconButton(
                    onPressed: widget.onThemeToggle,
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? AppTheme.warning : AppTheme.neonGreenDark,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      side: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // SKIP BUTTON
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: isDark
                          ? AppTheme.darkCard.withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: AppTheme.neonGreen.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getSkipLabel(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neonGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.skip_next_rounded,
                          size: 16,
                          color: AppTheme.neonGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main PageView for 3 Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _currentPage = idx);
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final Color slideColor = slide['color'];

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Hero Visual Container
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    slideColor.withOpacity(isDark ? 0.35 : 0.22),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppTheme.darkCard.withOpacity(0.9),
                                          AppTheme.darkCardHover.withOpacity(0.6),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.9),
                                          AppTheme.lightCardHover.withOpacity(0.7),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: slideColor.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: slideColor.withOpacity(isDark ? 0.25 : 0.15),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: slideColor.withOpacity(0.12),
                                    ),
                                  ),
                                  Icon(
                                    slide['icon'] as IconData,
                                    size: 78,
                                    color: slideColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Highlight Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: slideColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: slideColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            slide['highlight'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: slideColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Slide Title
                        Text(
                          slide['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Slide Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            slide['description'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Feature Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFeatureBadge(slide['badge1'], slideColor, isDark),
                            _buildFeatureBadge(slide['badge2'], slideColor, isDark),
                            _buildFeatureBadge(slide['badge3'], slideColor, isDark),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: isSelected ? 28 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.neonGreen
                                : (isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.neonGreen.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  InkWell(
                    onTap: _nextPage,
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.neonGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonGreen.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getNextLabel(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF042F2E),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 2
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                            color: const Color(0xFF042F2E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
            ),
          ),
        ],
      ),
    );
  }
}
