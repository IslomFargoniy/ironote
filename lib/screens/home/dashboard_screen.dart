import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/debt_model.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';
import '../debt/debt_form_screen.dart';
import '../debt/repayment_dialog.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String currentLang;
  final bool isDarkMode;
  final Function(String) onLanguageChanged;
  final VoidCallback onThemeToggle;

  const DashboardScreen({
    super.key,
    required this.currentLang,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all | given | taken | overdue | completed
  bool _hideBalance = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final clean = phoneNumber.replaceAll(' ', '');
    final Uri launchUri = Uri(scheme: 'tel', path: clean);
    try {
      await launchUrl(launchUri);
    } catch (_) {}
  }

  Future<void> _sendDirectSms(String phoneNumber, DebtModel debt, double remaining) async {
    if (phoneNumber.isEmpty) return;
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = "Assalomu alaykum ${debt.debtorName}. Ironote orqali sizdagi ${NumberFormatter.format(remaining)} ${debt.currency} qarz summasini eslatib o'tmoqchimiz. Rahmat!";
    final Uri uri = Uri(scheme: 'sms', path: clean, queryParameters: {'body': msg});
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _sendTelegramReminder(DebtModel debt, double remaining) async {
    final msg = Uri.encodeComponent(
      "Assalomu alaykum ${debt.debtorName}! Sizdagi ${NumberFormatter.format(remaining)} ${debt.currency} qarz summasini eslatib o'tmoqchimiz.",
    );
    final Uri telegramUri = Uri.parse("https://t.me/share/url?url=&text=$msg");
    try {
      await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // Built-in Quick Loan Calculator Sheet (Redesigned with Presets & Responsive Layout)
  void _openCalculatorSheet() {
    double amount = 5000000;
    double monthlyInterest = 0.0; // 0% by default (halol qarz daftari)
    int months = 6;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = widget.isDarkMode;
          final totalInterest = (amount * (monthlyInterest / 100)) * months;
          final totalToPay = amount + totalInterest;
          final monthlyPayment = totalToPay / months;

          return Container(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 16 + bottomInset),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1A1B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calculate_rounded, color: AppTheme.neonGreen, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          t('calcTitle'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Header & Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('calcAmount'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                    ),
                    Text(
                      "${NumberFormatter.format(amount)} UZS",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.neonGreen),
                    ),
                  ],
                ),
                Slider(
                  value: amount,
                  min: 500000,
                  max: 50000000,
                  divisions: 99,
                  activeColor: AppTheme.neonGreen,
                  onChanged: (val) => setSheetState(() => amount = val),
                ),

                // Quick Amount Presets
                Row(
                  children: [1000000, 5000000, 10000000, 20000000, 50000000].map((preset) {
                    final isSel = amount == preset.toDouble();
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: InkWell(
                          onTap: () => setSheetState(() => amount = preset.toDouble()),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppTheme.neonGreen
                                  : (isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? AppTheme.neonGreen
                                    : (isDark ? const Color(0xFF1F3538) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "${preset ~/ 1000000} mln",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                  color: isSel
                                      ? const Color(0xFF042F2E)
                                      : (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Period Header & Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('calcPeriod'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                    ),
                    Text(
                      "$months ${t('monthShort')}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF06B6D4)),
                    ),
                  ],
                ),
                Slider(
                  value: months.toDouble(),
                  min: 1,
                  max: 24,
                  divisions: 23,
                  activeColor: const Color(0xFF06B6D4),
                  onChanged: (val) => setSheetState(() => months = val.round()),
                ),

                // Quick Month Presets
                Row(
                  children: [1, 3, 6, 12, 24].map((m) {
                    final isSel = months == m;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: InkWell(
                          onTap: () => setSheetState(() => months = m),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF06B6D4)
                                  : (isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF06B6D4)
                                    : (isDark ? const Color(0xFF1F3538) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "$m ${t('monthShort')}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                  color: isSel ? Colors.white : (isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Calculation Result Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${t('calcMonthlyPay')}:",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${NumberFormatter.format(monthlyPayment.round())} UZS",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.neonGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: AppTheme.neonGreen.withOpacity(0.2)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${t('calcTotalPay')}:",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${NumberFormatter.format(totalToPay.round())} UZS",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.neonGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Confirm / Close Button with Safe Area
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: const Color(0xFF042F2E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(t('confirm'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Full Screen Image Dialog
  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SmartImageHelper.buildImage(imageUrl, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  // Documents & Tilxatlar Sheet (Redesigned with Full Card Layout)
  void _openDocumentsSheet() {
    final isDark = widget.isDarkMode;
    final debtsWithDocs = DatabaseService().debts.where((d) => d.images.isNotEmpty || d.notes.isNotEmpty).toList();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1A1B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_rounded, color: AppTheme.neonGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('documentsTitle'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                          ),
                        ),
                        Text(
                          "${t('imageSectionTitle')} (${debtsWithDocs.length} ${t('itemsCount')})",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: debtsWithDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(t('noDocuments'), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: debtsWithDocs.length,
                      itemBuilder: (context, idx) {
                        final d = debtsWithDocs[idx];
                        final isGiven = d.type == 'given';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF132324) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? const Color(0xFF1F3A3D) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Avatar/Icon + Debtor Name + Amount
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: (isGiven ? AppTheme.neonGreen : AppTheme.warning).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      color: isGiven ? AppTheme.neonGreen : AppTheme.warning,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.debtorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              isGiven ? t('lentDebt') : t('borrowedDebt'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isGiven ? AppTheme.neonGreen : AppTheme.warning,
                                              ),
                                            ),
                                            if (d.phone.isNotEmpty) ...[
                                              const Text(" • ", style: TextStyle(color: Colors.grey)),
                                              Text(d.phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${NumberFormatter.format(d.amount)} ${d.currency}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: isGiven ? AppTheme.neonGreen : AppTheme.warning,
                                    ),
                                  ),
                                ],
                              ),
                              if (d.notes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0C191A) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF1B3234) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppTheme.neonGreen),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          d.notes,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.4,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (d.images.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 64,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: d.images.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, imgIdx) {
                                      final imgUrl = d.images[imgIdx];
                                      return GestureDetector(
                                        onTap: () => _showFullImageDialog(context, imgUrl),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Stack(
                                            children: [
                                              SmartImageHelper.buildImage(
                                                imgUrl,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                              ),
                                              Positioned(
                                                bottom: 2,
                                                right: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ANIMATED NOTIFICATION CENTER SHEET ---
  void _showNotificationCenter(BuildContext context) {
    final db = DatabaseService();
    final debts = db.debts;
    final isDark = widget.isDarkMode;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Overdue Debts
    final overdueList = debts.where((d) {
      final paid = db.getTotalPaidForDebt(d.id);
      final remaining = (d.amount - paid).clamp(0.0, d.amount);
      return d.deadline != null && DateTime.now().isAfter(d.deadline!) && remaining > 0;
    }).toList();

    // Upcoming Debts (due within next 7 days)
    final upcomingList = debts.where((d) {
      final paid = db.getTotalPaidForDebt(d.id);
      final remaining = (d.amount - paid).clamp(0.0, d.amount);
      if (d.deadline == null || remaining <= 0) return false;
      final diff = d.deadline!.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, animVal, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - animVal)),
            child: Opacity(
              opacity: animVal,
              child: child,
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + bottomInset),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C191A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: AppTheme.neonGreen, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('notificationsTitle'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                            ),
                          ),
                          Text(
                            "${overdueList.length + upcomingList.length + 1} ${t('notificationsCount')}",
                            style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Currency Rate Notification Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: AppTheme.neonGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      t('ratesUpdatedTitle'),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.neonGreen),
                                    ),
                                    Text(db.ratesDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${t('ratesSourceDesc')}: 1 USD = ${NumberFormatter.format(db.usdRate)} so'm, 1 EUR = ${NumberFormatter.format(db.eurRate)} so'm, 1 RUB = ${NumberFormatter.format(db.rubRate)} so'm.",
                                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Overdue Debts Notifications
                    if (overdueList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          "${t('overdueSectionTitle')} (${overdueList.length})",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.danger, letterSpacing: 0.5),
                        ),
                      ),
                      ...overdueList.map((d) {
                        final paid = db.getTotalPaidForDebt(d.id);
                        final remaining = (d.amount - paid).clamp(0.0, d.amount);
                        final daysLate = DateTime.now().difference(d.deadline!).inDays;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1214) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.danger.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.debtorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "$daysLate ${t('daysLateLabel')} • ${t('remaining')}: ${NumberFormatter.format(remaining)} ${d.currency}",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.danger),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (d.phone.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        launchUrl(Uri.parse("tel:${d.phone.replaceAll(' ', '')}"));
                                      },
                                      icon: const Icon(Icons.phone_rounded, size: 14, color: AppTheme.neonGreen),
                                      label: Text(t('callBtn'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.neonGreen)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppTheme.neonGreen),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        final remaining = db.getRemainingForDebt(d.id);
                                        _showDebtActionsSheet(d, remaining);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.danger,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Text(t('viewBtn'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],

                    // 3. Upcoming Deadlines Notifications
                    if (upcomingList.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          "${t('upcomingSectionTitle')} (${upcomingList.length})",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B), letterSpacing: 0.5),
                        ),
                      ),
                      ...upcomingList.map((d) {
                        final diff = d.deadline!.difference(DateTime.now()).inDays;
                        final label = diff == 0 ? t('dueToday') : "$diff ${t('dueInDays')}";
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A170F) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.debtorName,
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "$label • ${NumberFormatter.format(d.amount)} ${d.currency}",
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  final remaining = db.getRemainingForDebt(d.id);
                                  _showDebtActionsSheet(d, remaining);
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // 4. System Security info
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF1F3A3D) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppTheme.neonGreen, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "IroNote xavfsizlik tizimi faol. Barcha qarzlar lokal va xavfsiz shifrlangan.",
                              style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final isDark = widget.isDarkMode;
    final debts = db.debts;
    final user = db.currentUser;

    // Theme tokens (Emerald Fintech exact match)
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

    final cardColor = isDark ? const Color(0xFF0E1A1B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF064E3B);
    final textSecondary = isDark ? const Color(0xFF7B9CA0) : const Color(0xFF059669);

    // Multi-currency Net calculation using real-time user configured rates
    double totalNetInUZS = 0;
    int totalCount = debts.length;
    int overdueCount = 0;

    for (var debt in debts) {
      final paid = db.getTotalPaidForDebt(debt.id);
      final remaining = (debt.amount - paid).clamp(0.0, debt.amount);
      final remainingInUZS = db.convertToUzs(remaining, debt.currency);

      if (debt.type == 'given') {
        totalNetInUZS += remainingInUZS;
      } else {
        totalNetInUZS -= remainingInUZS;
      }

      if (debt.deadline != null && DateTime.now().isAfter(debt.deadline!) && remaining > 0) {
        overdueCount++;
      }
    }
    final displayCurr = db.displayCurrency;
    final totalNetInDisplay = db.convertFromUzs(totalNetInUZS, displayCurr);
    final totalNetInUSD = db.convertFromUzs(totalNetInUZS, 'USD');

    // Filter list
    final filteredDebts = debts.where((d) {
      final paid = db.getTotalPaidForDebt(d.id);
      final remaining = (d.amount - paid).clamp(0.0, d.amount);
      final isOverdue = d.deadline != null && DateTime.now().isAfter(d.deadline!) && remaining > 0;
      final isCompleted = d.status == 'completed' || remaining <= 0;

      if (_filterType == 'given' && d.type != 'given') return false;
      if (_filterType == 'taken' && d.type != 'taken') return false;
      if (_filterType == 'overdue' && !isOverdue) return false;
      if (_filterType == 'completed' && !isCompleted) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return d.debtorName.toLowerCase().contains(q) ||
            d.phone.toLowerCase().contains(q) ||
            d.secondPhone.toLowerCase().contains(q) ||
            d.notes.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. Top Bar (Hi, Gabriel / User Avatar + Theme Switch + Bell)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // User Avatar & Hi, Name (Expanded so it never overflows)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => ProfileScreen(currentLang: widget.currentLang)),
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                                ),
                                child: CircleAvatar(
                                  radius: 19,
                                  backgroundColor: cardColor,
                                  backgroundImage: SmartImageHelper.getProvider(
                                    user?.avatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                                  ),
                                  child: user?.avatar == null ? const Icon(Icons.person, color: AppTheme.neonGreen, size: 20) : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${t('hi')}, ${user?.fullName.split(' ').first ?? 'User'}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      t('subTitleBar'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Icons: Theme Toggle, Search, Notification
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Theme Switch Button
                          GestureDetector(
                            onTap: widget.onThemeToggle,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF132324) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 18,
                                color: isDark ? AppTheme.neonGreen : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Search Button
                          GestureDetector(
                            onTap: () => _showSearchBottomSheet(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF132324) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Icon(Icons.search_rounded, size: 18, color: textPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Notification Bell
                          GestureDetector(
                            onTap: () => _showNotificationCenter(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF132324) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.notifications_none_rounded, size: 18, color: textPrimary),
                                  if (overdueCount > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.neonGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Total Balance Header (With real-time UZS & USD conversion, FittedBox)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                t('totalBalance'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _hideBalance = !_hideBalance),
                                child: Icon(
                                  _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 16,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),

                          // Live Rates Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                            ),
                            child: Text(
                              "\$ 1 = ${NumberFormatter.formatCompact(db.usdRate)}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.neonGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _hideBalance ? "••••••••" : "${NumberFormatter.format(totalNetInDisplay.abs())} $displayCurr",
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: totalNetInUZS >= 0 ? textPrimary : AppTheme.danger,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (!_hideBalance && displayCurr != 'UZS') ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      "≈ ${NumberFormatter.format(totalNetInUZS.abs())} so'm",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                                  ] else if (!_hideBalance && displayCurr == 'UZS') ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      "≈ \$ ${NumberFormatter.format(totalNetInUSD.abs())}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Interactive Display Currency Pills (UZS, USD, RUB, EUR)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['UZS', 'USD', 'RUB', 'EUR'].map((c) {
                            final isSel = displayCurr == c;
                            return GestureDetector(
                              onTap: () => db.setDisplayCurrency(c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.neonGreen : (isDark ? const Color(0xFF132324) : const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? AppTheme.neonGreen : (isDark ? const Color(0xFF1F3D41) : const Color(0xFFCBD5E1)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isSel ? const Color(0xFF042F2E) : textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Four Quick Action Circular/Squircle Buttons (Withdraw, Document, Calculator, More)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.upload_rounded,
                        label: t('withdraw'),
                        sublabel: t('withdraw'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => DebtFormScreen(currentLang: widget.currentLang, initialType: 'given'),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        isDark: isDark,
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.description_outlined,
                        label: t('document'),
                        sublabel: t('document'),
                        onTap: _openDocumentsSheet,
                        isDark: isDark,
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.calculate_outlined,
                        label: t('calculator'),
                        sublabel: t('calculator'),
                        onTap: _openCalculatorSheet,
                        isDark: isDark,
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.grid_view_rounded,
                        label: t('more'),
                        sublabel: t('more'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => DebtFormScreen(currentLang: widget.currentLang),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        isDark: isDark,
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Hero Emerald 3D Banner ("THE FUTURE ASSETS / AQLLI QARZ DAFTARI")
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: _buildHeroEmeraldBanner(isDark),
                ),
              ),

              // 5. Category Tabs / Filter Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterCategoryTab("${t('filterAll')} ($totalCount)", 'all', isDark),
                        const SizedBox(width: 8),
                        _buildFilterCategoryTab(t('filterGivenShort'), 'given', isDark),
                        const SizedBox(width: 8),
                        _buildFilterCategoryTab(t('filterTakenShort'), 'taken', isDark),
                        const SizedBox(width: 8),
                        _buildFilterCategoryTab("${t('filterOverdueShort')} ($overdueCount)", 'overdue', isDark),
                        const SizedBox(width: 8),
                        _buildFilterCategoryTab(t('filterCompletedShort'), 'completed', isDark),
                      ],
                    ),
                  ),
                ),
              ),

              // 6. Section Title (Discover Debts / Qarzdorlar Bo'limi)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('debtListTitle'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        "${filteredDebts.length} ${t('itemsCount')}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.neonGreen),
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Debtor Cards Grid / List (Design 1/2/3 Exact Style)
              if (filteredDebts.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          t('emptyDebtsTitle'),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('emptyDebtsSub'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debt = filteredDebts[index];
                        final paid = db.getTotalPaidForDebt(debt.id);
                        final remaining = (debt.amount - paid).clamp(0.0, debt.amount);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildDebtorFintechCard(
                            debt: debt,
                            remaining: remaining,
                            paid: paid,
                            isDark: isDark,
                            cardColor: cardColor,
                            cardBorder: cardBorder,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        );
                      },
                      childCount: filteredDebts.length,
                    ),
                  ),
                ),

              // Bottom space for floating navigation bar and phone system buttons
              SliverToBoxAdapter(child: SizedBox(height: 72.0 + MediaQuery.of(context).padding.bottom)),
            ],
          ),
        ),
      ),
    );
  }

  // --- QUICK ACTION CIRCULAR BUTTONS ---
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color cardBorder,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.35) : AppTheme.neonGreen.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.neonGreen, size: 26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- HERO EMERALD 3D BANNER (Exact Match to Design 1/2/3 Banner) ---
  Widget _buildHeroEmeraldBanner(bool isDark) {
    return Container(
      width: double.infinity,
      height: 176,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00E599),
            Color(0xFF059669),
            Color(0xFF064E3B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E599).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Banner Content (Constrained so it never collides with the right logo)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 110,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t('heroBannerSub'),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('heroBannerTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DebtFormScreen(currentLang: widget.currentLang),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF042F2E),
                  foregroundColor: AppTheme.neonGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(t('joinNow'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),

          // Official IroNote Logo on Right of Banner
          Positioned(
            right: 8,
            top: 12,
            bottom: 12,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/ironote_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => CustomPaint(
                    size: const Size(100, 100),
                    painter: _Emerald3DCrystalPainter(),
                  ),
                ),
              ),
            ),
          ),

          // Pagination Dots
          Positioned(
            bottom: 4,
            right: 48,
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER CATEGORY TABS ---
  Widget _buildFilterCategoryTab(String title, String type, bool isDark) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonGreen
              : (isDark ? const Color(0xFF132324) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.neonGreen : (isDark ? const Color(0xFF1F3739) : const Color(0xFFD1FAE5)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF042F2E)
                : (isDark ? const Color(0xFF8DAEB2) : const Color(0xFF065F46)),
          ),
        ),
      ),
    );
  }

  // --- DEBTOR FINTECH CARD (Exact Match to User's Nexora Asymmetric Curved Tab Header Card) ---
  Widget _buildDebtorFintechCard({
    required DebtModel debt,
    required double remaining,
    required double paid,
    required bool isDark,
    required Color cardColor,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final db = DatabaseService();
    final isGiven = debt.type == 'given';
    final isTaken = debt.type == 'taken';
    final isCompleted = debt.status == 'completed' || remaining <= 0;
    final isOverdue = debt.deadline != null && DateTime.now().isAfter(debt.deadline!) && remaining > 0;
    final paidFraction = debt.amount > 0 ? (paid / debt.amount).clamp(0.0, 1.0) : 0.0;
    final paidPercent = (paidFraction * 100).toStringAsFixed(0);

    // Tab Color & Text (Kirim = Vibrant Green, Chiqim = Vibrant Red as requested)
    final Color tabColor = isCompleted
        ? const Color(0xFF6EE7B7) // Mint
        : isOverdue
            ? const Color(0xFFFCA5A5) // Soft Red
            : isGiven
                ? const Color(0xFF10B981) // Vibrant Green for Kirim!
                : const Color(0xFFEF4444); // Vibrant Red for Chiqim!

    final Color tabTextColor = isCompleted
        ? const Color(0xFF064E3B)
        : isOverdue
            ? const Color(0xFF7F1D1D)
            : isGiven
                ? const Color(0xFF064E3B) // Dark green
                : Colors.white; // White on red

    final String tabLabel = isCompleted
        ? t('filterCompletedShort')
        : isOverdue
            ? t('filterOverdueShort')
            : isGiven
                ? "↑ Kirim"
                : "↓ Chiqim";

    // Header Right Time & Date
    final timeStr = "${debt.createdAt.hour.toString().padLeft(2, '0')}:${debt.createdAt.minute.toString().padLeft(2, '0')}";
    final dateObj = debt.deadline ?? debt.createdAt;
    final dateStr = "${dateObj.day.toString().padLeft(2, '0')}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.year}";

    // Days left calculation
    String deadlineBadgeText = "";
    if (debt.deadline != null && remaining > 0) {
      final diff = debt.deadline!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        deadlineBadgeText = "${diff.abs()} kun kechikdi";
      } else if (diff == 0) {
        deadlineBadgeText = "Bugun oxirgi muddat";
      } else {
        deadlineBadgeText = "$diff kun qoldi";
      }
    }

    final headerBgColor = isDark ? const Color(0xFF081C1E) : const Color(0xFFE2EBF0);
    final bodyBgColor = isDark ? const Color(0xFF0C2427) : Colors.white;

    return GestureDetector(
      onTap: () => _showDebtActionsSheet(debt, remaining),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? const Color(0xFF1B3C40) : const Color(0xFFD8E4E8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Asymmetrical Notched Tab Header (Exact Match to Screenshot)
              SizedBox(
                height: 38,
                child: Stack(
                  children: [
                    // Canvas with curved transition
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FintechTabHeaderPainter(
                          tabColor: tabColor,
                          headerBgColor: headerBgColor,
                          borderColor: cardBorder,
                          tabWidthPercent: isGiven || isTaken ? 0.38 : 0.42,
                        ),
                      ),
                    ),

                    // Content on top of header
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            // Left Tab Label
                            Text(
                              tabLabel,
                              style: TextStyle(
                                color: tabTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const Spacer(),

                            // Right Time with Clock Icon
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isDark ? const Color(0xFF86A5AA) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF9FB9BD) : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Right Date with Calendar Icon
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: isDark ? const Color(0xFF86A5AA) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF9FB9BD) : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Card Body
              Container(
                color: bodyBgColor,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row A: Monogram / Photo Avatar + Debtor Full Name + Options Button
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF133438) : const Color(0xFFE6F4EA),
                            border: Border.all(
                              color: isCompleted ? AppTheme.neonGreen : tabColor,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              debt.debtorName.isNotEmpty
                                  ? debt.debtorName
                                      .trim()
                                      .split(' ')
                                      .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                                      .take(2)
                                      .join('')
                                  : 'ID',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppTheme.neonGreen : const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Debtor Name & Currency Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${debt.debtorName} (${debt.currency})",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                debt.phone.isNotEmpty
                                    ? debt.phone
                                    : (debt.notes.isNotEmpty ? debt.notes : t('subTitleBar')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions Popup / More icon
                        GestureDetector(
                          onTap: () => _showDebtActionsSheet(debt, remaining),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF143033) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.more_horiz_rounded, size: 18, color: textSecondary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row B: Status & Metric Pill Badges (Match +4.73% & +$1,286 - Today style)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Pill 1: % Paid with Trend Arrow
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF102D30) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E484D) : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle_rounded : Icons.trending_up_rounded,
                                size: 13,
                                color: AppTheme.neonGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$paidPercent% to'landi",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.neonGreen,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pill 2: Deadline or Today info
                        if (deadlineBadgeText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? const Color(0xFFF43F5E).withOpacity(0.12)
                                  : (isDark ? const Color(0xFF102D30) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isOverdue
                                    ? const Color(0xFFF43F5E).withOpacity(0.4)
                                    : (isDark ? const Color(0xFF1E484D) : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                                  size: 13,
                                  color: isOverdue ? const Color(0xFFF43F5E) : textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  deadlineBadgeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isOverdue ? const Color(0xFFF43F5E) : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Linear Repayment Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: paidFraction,
                        minHeight: 5,
                        backgroundColor: isDark ? const Color(0xFF163236) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? AppTheme.neonGreen
                              : (isGiven ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Row C: Bottom Financial Summary (Converted dynamically to db.displayCurrency)
                    Builder(
                      builder: (context) {
                        final dispCurr = db.displayCurrency;
                        final totalInDisp = db.convertToDisplay(debt.amount, debt.currency);
                        final paidInDisp = db.convertToDisplay(paid, debt.currency);
                        final remInDisp = db.convertToDisplay(remaining, debt.currency);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Left: Jami Summa
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('total'),
                                    style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "${NumberFormatter.format(totalInDisp)} $dispCurr",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Middle: To'langan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    t('paid'),
                                    style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${NumberFormatter.format(paidInDisp)} $dispCurr",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right: Qoldiq (Highlighted)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    t('remaining'),
                                    style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "${NumberFormatter.format(remInDisp)} $dispCurr",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: remaining > 0 ? AppTheme.neonGreen : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  if (debt.currency != dispCurr)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "(${NumberFormatter.format(remaining)} ${debt.currency})",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: isDark ? const Color(0xFF153336) : const Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Row D: Quick Action Icon Buttons (Call, Telegram, SMS, To'lov)
                    Row(
                      children: [
                        if (debt.phone.isNotEmpty) ...[
                          _buildQuickIconCircle(
                            icon: Icons.phone_rounded,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                            tooltip: t('tel'),
                            onTap: () => _makePhoneCall(debt.phone),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickIconCircle(
                            icon: Icons.send_rounded,
                            color: const Color(0xFF0284C7),
                            isDark: isDark,
                            tooltip: "Telegram",
                            onTap: () => _sendTelegramReminder(debt, remaining),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickIconCircle(
                            icon: Icons.sms_rounded,
                            color: const Color(0xFF06B6D4),
                            isDark: isDark,
                            tooltip: "SMS",
                            onTap: () => _sendDirectSms(debt.phone, debt, remaining),
                          ),
                        ],
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => RepaymentDialog(debt: debt, currentLang: widget.currentLang),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(t('repay'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: const Color(0xFF042F2E),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIconCircle({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35), width: 1.0),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }

  // --- ACTIONS SHEET ---
  void _showDebtActionsSheet(DebtModel debt, double remaining) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppTheme.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              debt.debtorName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text("${t('remaining')} ${NumberFormatter.format(remaining)} ${debt.currency}",
                style: const TextStyle(fontSize: 14, color: AppTheme.neonGreen, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            if (debt.phone.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(debt.phone),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: Text(t('tel')),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendDirectSms(debt.phone, debt, remaining),
                      icon: const Icon(Icons.sms_rounded, size: 16),
                      label: Text(t('sms')),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendTelegramReminder(debt, remaining),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(t('tg')),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => RepaymentDialog(debt: debt, currentLang: widget.currentLang),
                );
              },
              icon: const Icon(Icons.payment_rounded),
              label: Text(t('repay')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonGreen,
                foregroundColor: const Color(0xFF042F2E),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (debt.address.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => LocationService.openMap(debt.address),
                icon: const Icon(Icons.map_rounded, color: Color(0xFF06B6D4)),
                label: Text(
                  debt.address.startsWith('GPS:') ? t('viewOnMap') : "${t('address')}: ${debt.address}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF06B6D4), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: t('searchHint'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: const Color(0xFF042F2E)),
                child: Text(t('searchResults'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3D EMERALD CRYSTAL PAINTER (Exact match to Banner 3D icon in screenshot) ---
class _Emerald3DCrystalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.35, w * 0.8, h * 0.45), ringPaint);

    // 3D Isometric Diamond Cube
    final cubePath = Path()
      ..moveTo(w * 0.55, h * 0.15)
      ..lineTo(w * 0.85, h * 0.4)
      ..lineTo(w * 0.55, h * 0.75)
      ..lineTo(w * 0.25, h * 0.5)
      ..close();

    final cubePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE6FFFA), Color(0xFF6EE7B7), Color(0xFF059669)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawShadow(cubePath, Colors.white.withOpacity(0.6), 8, true);
    canvas.drawPath(cubePath, cubePaint);

    // Inner bevel edge
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(w * 0.55, h * 0.15), Offset(w * 0.55, h * 0.75), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the asymmetrical curved tab header on each debtor fintech card
class _FintechTabHeaderPainter extends CustomPainter {
  final Color tabColor;
  final Color headerBgColor;
  final Color borderColor;
  final double tabWidthPercent;

  _FintechTabHeaderPainter({
    required this.tabColor,
    required this.headerBgColor,
    required this.borderColor,
    this.tabWidthPercent = 0.40,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tabW = w * tabWidthPercent;

    // 1. Right Header Background
    final rightPath = Path();
    rightPath.moveTo(tabW - 10, 0);
    rightPath.lineTo(w - 18, 0);
    rightPath.quadraticBezierTo(w, 0, w, 18);
    rightPath.lineTo(w, h);
    rightPath.lineTo(0, h);
    rightPath.lineTo(0, 18);
    rightPath.quadraticBezierTo(0, 0, 18, 0);
    rightPath.close();

    final bgPaint = Paint()..color = headerBgColor;
    canvas.drawPath(rightPath, bgPaint);

    // 2. Left Tab with smooth organic S-curve shoulder
    final tabPath = Path();
    tabPath.moveTo(0, 18);
    tabPath.quadraticBezierTo(0, 0, 18, 0);
    tabPath.lineTo(tabW - 14, 0);
    tabPath.quadraticBezierTo(tabW - 2, 0, tabW + 2, 10);
    tabPath.quadraticBezierTo(tabW + 8, h, tabW + 24, h);
    tabPath.lineTo(0, h);
    tabPath.close();

    final tabPaint = Paint()..color = tabColor;
    canvas.drawPath(tabPath, tabPaint);
  }

  @override
  bool shouldRepaint(covariant _FintechTabHeaderPainter oldDelegate) =>
      oldDelegate.tabColor != tabColor ||
      oldDelegate.headerBgColor != headerBgColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.tabWidthPercent != tabWidthPercent;
}

