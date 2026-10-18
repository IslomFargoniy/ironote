import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/debt_model.dart';
import '../../services/database_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class RemindersScreen extends StatefulWidget {
  final String currentLang;

  const RemindersScreen({super.key, required this.currentLang});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _selectedTone = 'polite'; // polite | formal | urgent | short
  bool _isBotConfigExpanded = false;
  final _botTokenController = TextEditingController(text: "7489234812:AAH923jklsd...");
  final _chatIdController = TextEditingController(text: "@ironote_debt_channel");

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  String _generateSmsMessage(DebtModel debt, double remaining, String tone) {
    final name = debt.debtorName;
    final amountStr = "${NumberFormatter.format(remaining)} ${debt.currency}";
    final deadlineStr = debt.deadline != null
        ? "${debt.deadline!.day}.${debt.deadline!.month}.${debt.deadline!.year}"
        : "kelishilgan muddat";

    switch (tone) {
      case 'formal':
        return "Hurmatli $name, Ironote orqali eslatma: sizdagi $amountStr qarzni qaytarish muddati: $deadlineStr. Iltimos, hisob-kitob qiling.";
      case 'urgent':
        return "DIQQAT $name! Sizning $amountStr qarzingiz muddati ($deadlineStr) o'tib ketgan. Iltimos zudlik bilan qaytaring yoki bog'laning!";
      case 'short':
        return "$name, $amountStr qarz hisobini eslatmoqchiman. Muddat: $deadlineStr. Rahmat!";
      case 'polite':
      default:
        return "Assalomu alaykum $name. Sizdagi $amountStr qarz summasini eslatib o'tmoqchimiz. Muddat: $deadlineStr. Rahmat!";
    }
  }

  String _generateTelegramMessage(DebtModel debt, double remaining, String tone) {
    final name = debt.debtorName;
    final amountStr = "${NumberFormatter.format(remaining)} ${debt.currency}";
    final dateStr = "${debt.debtDate.day}.${debt.debtDate.month}.${debt.debtDate.year}";
    final deadlineStr = debt.deadline != null
        ? "${debt.deadline!.day}.${debt.deadline!.month}.${debt.deadline!.year}"
        : "Kelishilgan muddat";

    switch (tone) {
      case 'formal':
        return """📑 *RASMIY QARZ BILDIRISHNOMASI*
━━━━━━━━━━━━━━━━━━━━
Hurmatli *$name*,
Siz bilan *$dateStr* sanada rasmiylashtirilgan qarz munosabati bo'yicha ma'lumot:

💰 *Qaytarilishi kerak bo'lgan qoldiq:* $amountStr
📅 *Qaytarish muddati:* $deadlineStr
📍 *Shartnoma holati:* Faol

Iltimos, ko'rsatilgan muddatda hisob-kitobni amalga oshirishingizni so'raymiz.
━━━━━━━━━━━━━━━━━━━━
_Ironote Qarz Boshqaruv Tizimi orqali yuborildi_""";

      case 'urgent':
        return """⚠️ *SHOSHILINCH QARZ ESLATMASI (MUDDATI O'TGAN)*
━━━━━━━━━━━━━━━━━━━━
*$name*,
Sizning *$amountStr* miqdoridagi qarzingizni qaytarish muddati (*$deadlineStr*) o'tib ketgan!

Iltimos, qarzni zudlik bilan qaytaring yoki kechikish sababi bo'yicha bog'laning.
━━━━━━━━━━━━━━━━━━━━""";

      case 'short':
        return """Salom *$name*! 👋
O'rtamizdagi qarz hisobidan *$amountStr* qoldiq qolgan edi.
Muddat: *$deadlineStr*. Imkoniyating bo'lganda ko'rib berarsan. Rahmat!""";

      case 'polite':
      default:
        return """Assalomu alaykum, hurmatli *$name*!
Sizdagi *$amountStr* miqdoridagi qarz summasini eslatib o'tmoqchimiz.
📅 Qaytarish muddati: *$deadlineStr*

Hisob-kitobni amalga oshirishda qulaylik tilaymiz. Rahmat!""";
    }
  }

  Future<void> _sendDirectSms(String phone, DebtModel debt, double remaining) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final body = _generateSmsMessage(debt, remaining, _selectedTone);
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{'body': body},
    );

    try {
      await launchUrl(smsUri);
    } catch (_) {
      _copyToClipboard(body, "SMS matni nusxalandi, SMS ilovasida yuborishingiz mumkin");
    }
  }

  Future<void> _openTelegramProfile(String phone, DebtModel debt, double remaining) async {
    String rawPhone = phone.isNotEmpty ? phone : debt.secondPhone;
    var clean = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 9) {
      clean = '998$clean';
    }

    if (clean.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Telefon raqami ko'rsatilmagan"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Eslatma matnini avtomatik xotiraga olish (Telegramda qulay joylashtirish uchun)
    final text = _generateTelegramMessage(debt, remaining, _selectedTone);
    await Clipboard.setData(ClipboardData(text: text));

    final Uri appUri = Uri.parse("tg://resolve?phone=$clean");
    final Uri webUri = Uri.parse("https://t.me/+$clean");

    try {
      bool launched = false;
      try {
        launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Telegram ochilmoqda, eslatma nusxalandi!"),
            backgroundColor: Color(0xFF229ED9),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Telegram ilovasini ochib bo'lmadi"),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _callDirect(String phone) async {
    if (phone.isEmpty) return;
    var clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!clean.startsWith('+') && clean.length == 9) {
      clean = '+998$clean';
    }
    final Uri uri = Uri(scheme: 'tel', path: clean);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35), width: 1.2),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, [String? successMsg]) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg ?? "Matn nusxalandi!"),
        backgroundColor: AppTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = DatabaseService();
    final debts = db.debts;

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF071110), Color(0xFF091717), Color(0xFF050D0E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFE6F9F0), Color(0xFFDCFCE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final cardBg = isDark ? const Color(0xFF0E1A1B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF064E3B);
    final textSecondary = isDark ? const Color(0xFF7B9CA0) : const Color(0xFF059669);

    final activeDebts = debts.where((d) {
      final rem = db.getRemainingForDebt(d.id);
      return rem > 0;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Text(
                  t('remindersTitle'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Centered SMS Xabarnoma Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonGreen.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sms_rounded,
                          size: 20,
                          color: Color(0xFF042F2E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t('channelSms'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF042F2E),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Tone / Template Selector Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('toneSelector'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildToneChip(t('tonePolite'), 'polite', isDark),
                            const SizedBox(width: 8),
                            _buildToneChip(t('toneFormal'), 'formal', isDark),
                            const SizedBox(width: 8),
                            _buildToneChip(t('toneUrgent'), 'urgent', isDark),
                            const SizedBox(width: 8),
                            _buildToneChip(t('toneShort'), 'short', isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Telegram Bot & SMS Avtomatizatsiyasi Card
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                      initiallyExpanded: _isBotConfigExpanded,
                      onExpansionChanged: (val) => setState(() => _isBotConfigExpanded = val),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: AppTheme.neonGreen, size: 22),
                      ),
                      title: Text(
                        t('botAutomationTitle'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      subtitle: Text(
                        t('botAutomationSub'),
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _botTokenController,
                                decoration: InputDecoration(
                                  labelText: t('botTokenLabel'),
                                  prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.neonGreen),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _chatIdController,
                                decoration: InputDecoration(
                                  labelText: t('chatIdLabel'),
                                  prefixIcon: const Icon(Icons.tag_rounded, color: AppTheme.neonGreen),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t('botSavedMsg')),
                                      backgroundColor: AppTheme.neonGreen,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: Text(t('saveBot')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonGreen,
                                  foregroundColor: const Color(0xFF042F2E),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Section Title (Protected with Expanded against overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t('activeDebtorsList'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${activeDebts.length} ${t('activeCount')}",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.neonGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Debtors Reminder List
                if (activeDebts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.neonGreen),
                          const SizedBox(height: 10),
                          Text(t('emptyDebtsTitle'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                        ],
                      ),
                    ),
                  )
                else
                  ...activeDebts.map((d) {
                    final rem = db.getRemainingForDebt(d.id);
                    final remInDisp = db.convertToDisplay(rem, d.currency);
                    final dispCurr = db.displayCurrency;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : AppTheme.neonGreen.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Debtor Info Header
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    d.debtorName.isNotEmpty ? d.debtorName[0].toUpperCase() : "Q",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.neonGreen),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.debtorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.phone.isNotEmpty ? d.phone : t('phone'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${NumberFormatter.format(remInDisp)} $dispCurr",
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.danger),
                                      ),
                                    ),
                                    Text(t('remaining'), style: TextStyle(fontSize: 10, color: textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons Row: Call, SMS, Telegram, Copy
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 1. Phone Call Icon
                              _buildActionCircle(
                                icon: Icons.phone_rounded,
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                                onTap: () => _callDirect(d.phone),
                                tooltip: t('tel'),
                              ),
                              // 2. Direct SMS Icon
                              _buildActionCircle(
                                icon: Icons.sms_rounded,
                                color: AppTheme.neonGreen,
                                isDark: isDark,
                                onTap: () => _sendDirectSms(d.phone, d, rem),
                                tooltip: t('sms'),
                              ),
                              // 3. Telegram Icon (Opens debtor's Telegram profile directly & copies reminder)
                              _buildActionCircle(
                                icon: Icons.telegram,
                                color: const Color(0xFF229ED9),
                                isDark: isDark,
                                onTap: () => _openTelegramProfile(d.phone, d, rem),
                                tooltip: "Telegram",
                              ),
                              // 4. Copy Text Icon
                              _buildActionCircle(
                                icon: Icons.copy_rounded,
                                color: textSecondary,
                                isDark: isDark,
                                onTap: () {
                                  final msg = _generateTelegramMessage(d, rem, _selectedTone);
                                  _copyToClipboard(msg);
                                },
                                tooltip: t('copyTextBtn'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                // Floating bottom navigation bar space with clean spacing
                SizedBox(height: 84.0 + MediaQuery.of(context).padding.bottom + 12.0),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildToneChip(String title, String tone, bool isDark) {
    final isSelected = _selectedTone == tone;
    return GestureDetector(
      onTap: () => setState(() => _selectedTone = tone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonGreen : (isDark ? const Color(0xFF132324) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.neonGreen : (isDark ? const Color(0xFF1F3739) : const Color(0xFFD1FAE5)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? const Color(0xFF042F2E) : (isDark ? const Color(0xFF8DAEB2) : const Color(0xFF065F46)),
          ),
        ),
      ),
    );
  }
}
