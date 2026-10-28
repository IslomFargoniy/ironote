import 'package:flutter/material.dart';
import '../../services/backup_service.dart';
import '../../services/database_service.dart';
import '../../services/security_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLang;
  final bool isDarkMode;
  final Function(String) onLanguageChanged;
  final VoidCallback onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.currentLang,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String t(String key) => AppTranslations.get(key, widget.currentLang);

  // --- EXCEL / CSV EXPORT ---
  Future<void> _handleExportCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text("Excel / CSV fayli tayyorlanmoqda..."),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await BackupService.exportCsv();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "✅ Excel / CSV fayli muvaffaqiyatli yuklab olindi!" : "❌ Eksportda xatolik yuz berdi",
          ),
          backgroundColor: success ? AppTheme.neonGreen : AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- JSON BACKUP EXPORT ---
  Future<void> _handleExportJson() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text("JSON Zaxira nusxa shakllantirilmoqda..."),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await BackupService.exportJsonBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "✅ Barcha qarzlar va to'lovlar JSON zaxiraga yuklandi!" : "❌ Zaxira olishda xatolik yuz berdi",
          ),
          backgroundColor: success ? AppTheme.neonGreen : AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- JSON BACKUP RESTORE (FILE PICK OR TEXT INPUT) ---
  void _handleImportJson() {
    final isDark = widget.isDarkMode;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C191A) : Colors.white,
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
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.restore_page_rounded, color: AppTheme.neonGreen, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Zaxira Nusxani Tiklash (Import)",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Oldin nusxalangan .json zaxira faylini yuklang yoki JSON kodini kiriting. Barcha qarzlar va to'lovlar hozirgi profilingizga to'liq qo'shiladi.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Option 1: Pick File from Device
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final result = await BackupService.pickAndRestoreBackup();
                  if (mounted) {
                    _showRestoreResultDialog(result);
                  }
                },
                icon: const Icon(Icons.file_upload_rounded),
                label: const Text("📁 Zaxira Faylini Tanlash (.json)", style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: const Color(0xFF042F2E),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 14),

              // Option 2: Paste JSON Text
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPasteJsonDialog();
                },
                icon: const Icon(Icons.paste_rounded, color: Color(0xFF06B6D4)),
                label: const Text("📋 JSON Kodini Joylash (Matn)", style: TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasteJsonDialog() {
    final textController = TextEditingController();
    final isDark = widget.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E1A1B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("JSON Kodini Kiriting", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: textController,
            maxLines: 8,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: "{\"app\": \"Ironote\", \"debts\": [...]}",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () {
              final content = textController.text.trim();
              Navigator.pop(ctx);
              if (content.isNotEmpty) {
                final result = BackupService.importFromJsonString(content);
                _showRestoreResultDialog(result);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: const Color(0xFF042F2E)),
            child: const Text("Tiklash", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showRestoreResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0E1A1B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(result.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: result.success ? AppTheme.neonGreen : AppTheme.danger),
            const SizedBox(width: 8),
            Text(result.success ? "Muvaffaqiyatli!" : "Xatolik!", style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: const TextStyle(fontSize: 14)),
            if (result.success) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• Tiklangan qarzlar: ${result.importedDebtsCount} ta",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.neonGreen)),
                    const SizedBox(height: 4),
                    Text("• To'lovlar tarixi: ${result.importedRepaymentsCount} ta",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.neonGreen)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: const Color(0xFF042F2E)),
            child: const Text("Ajoyib!", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // --- CURRENCY RATES MODAL ---
  void _handleCurrencyRates() {
    final db = DatabaseService();
    final isDark = widget.isDarkMode;
    final usdController = TextEditingController(text: NumberFormatter.format(db.usdRate));
    final rubController = TextEditingController(text: NumberFormatter.format(db.rubRate));
    final eurController = TextEditingController(text: NumberFormatter.format(db.eurRate));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C191A) : Colors.white,
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
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.currency_exchange_rounded, color: AppTheme.neonGreen, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    t('currencyRates'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                t('currencyRatesSub'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // Auto Sync button inside dialog
              StatefulBuilder(
                builder: (context, setDialogState) => OutlinedButton.icon(
                  onPressed: () async {
                    final success = await db.fetchAndSyncOfficialRates();
                    if (success) {
                      usdController.text = NumberFormatter.format(db.usdRate);
                      rubController.text = NumberFormatter.format(db.rubRate);
                      eurController.text = NumberFormatter.format(db.eurRate);
                      setDialogState(() {});
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, color: AppTheme.neonGreen, size: 18),
                  label: Text(
                    db.isLoadingRates ? "Yuklanmoqda..." : "Xalq banki / CBU dan avtomatik olish",
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.neonGreen, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.neonGreen, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // USD Rate Field
              TextField(
                controller: usdController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: t('usdRateLabel'),
                  prefixText: "\$ 1 = ",
                  suffixText: "so'm",
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.neonGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              // RUB Rate Field
              TextField(
                controller: rubController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: t('rubRateLabel'),
                  prefixText: "₽ 1 = ",
                  suffixText: "so'm",
                  prefixIcon: const Icon(Icons.currency_ruble_rounded, color: Color(0xFF06B6D4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),

              // EUR Rate Field
              TextField(
                controller: eurController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: t('eurRateLabel'),
                  prefixText: "€ 1 = ",
                  suffixText: "so'm",
                  prefixIcon: const Icon(Icons.euro_rounded, color: Color(0xFFF59E0B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final usdVal = NumberFormatter.parse(usdController.text);
                  final rubVal = NumberFormatter.parse(rubController.text);
                  final eurVal = NumberFormatter.parse(eurController.text);

                  await db.updateRates(
                    usd: usdVal > 0 ? usdVal : null,
                    rub: rubVal > 0 ? rubVal : null,
                    eur: eurVal > 0 ? eurVal : null,
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('ratesUpdated')),
                        backgroundColor: AppTheme.neonGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: const Color(0xFF042F2E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(t('save'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DELETE ACCOUNT (Google Play requirement) ---
  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('deleteAccount')),
        content: Text(t('deleteAccountConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SecurityService().disableSecurity();
              await DatabaseService().deleteCurrentAccount();
            },
            child: Text(t('delete'), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // --- PIN & BIOMETRICS SECURITY MODAL ---
  void _handleSecuritySettings() {
    final security = SecurityService();
    final isDark = widget.isDarkMode;
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C191A) : Colors.white,
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
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.shield_rounded, color: AppTheme.neonGreen, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "PIN-kod & Biometrika Himoyasi",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  security.isPinEnabled
                      ? "Ilova hozirda PIN-kod bilan himoyalangan."
                      : "Ilovaga kirishda xavfsizlik uchun 4 xonali PIN-kod o'rnating.",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Set PIN Field
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: security.isPinEnabled ? "Yangi 4 xonali PIN kiriting" : "4 xonali PIN kiriting",
                    hintText: "••••",
                    counterText: "",
                    prefixIcon: const Icon(Icons.pin_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),

                // Biometrics Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.fingerprint_rounded, color: AppTheme.neonGreen, size: 24),
                          SizedBox(width: 10),
                          Text("Biometrika (Face ID / Barmoq izi)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: security.isBiometricsEnabled,
                        activeColor: AppTheme.neonGreen,
                        onChanged: (val) async {
                          if (val) {
                            if (!security.isPinEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Avval 4 xonali PIN-kod o'rnating.")),
                              );
                              return;
                            }
                            if (!await security.canUseBiometrics()) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Qurilmada barmoq izi yoki yuz tanish sozlanmagan.")),
                              );
                              return;
                            }
                          }
                          await security.toggleBiometrics(val);
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Save PIN button
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (pin.length == 4) {
                      await security.setPin(pin);
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🔒 PIN-kod muvaffaqiyatli saqlandi va faollashtirildi!"),
                          backgroundColor: AppTheme.neonGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (pin.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PIN-kod aynan 4 ta raqamdan iborat bo'lishi kerak!")),
                      );
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: const Color(0xFF042F2E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Saqlash va Faollashtirish", style: TextStyle(fontWeight: FontWeight.w800)),
                ),

                if (security.isPinEnabled) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await security.disableSecurity();
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Xavfsizlik himoyasi o'chirildi.")),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Himoyani O'chirish", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final user = db.currentUser;
    final security = SecurityService();
    final isDark = widget.isDarkMode;

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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  t('settings'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. User Profile Banner Card
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => ProfileScreen(currentLang: widget.currentLang)),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : AppTheme.neonGreen.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: SmartImageHelper.getProvider(
                              user?.avatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.fullName ?? 'Foydalanuvchi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text(user?.email ?? user?.phone ?? '', style: TextStyle(fontSize: 12, color: textSecondary)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(t('editProfile'), style: const TextStyle(fontSize: 11, color: AppTheme.neonGreen, fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.neonGreen),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Currency Rates Section (USD, RUB, EUR)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('currencyRates'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Auto sync button from official bank API
                        GestureDetector(
                          onTap: () async {
                            final success = await db.fetchAndSyncOfficialRates();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "✅ Xalq banki va Markaziy Bank rasmiy kurslari muvaffaqiyatli yangilandi!"
                                        : "Xatolik: internet ulanishini tekshiring",
                                  ),
                                  backgroundColor: success ? AppTheme.neonGreen : AppTheme.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                db.isLoadingRates
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonGreen),
                                      )
                                    : const Icon(Icons.sync_rounded, size: 14, color: AppTheme.neonGreen),
                                const SizedBox(width: 4),
                                const Text(
                                  "Avtomatik",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.neonGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _handleCurrencyRates,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 12, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(t('editRates'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Currency Rates Banner Cards
                GestureDetector(
                  onTap: _handleCurrencyRates,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        // USD Chip
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text("\$", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.neonGreen)),
                                    SizedBox(width: 4),
                                    Text("USD", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${NumberFormatter.format(db.usdRate)} so'm",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.neonGreen),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // RUB Chip
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text("₽", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4))),
                                    SizedBox(width: 4),
                                    Text("RUB", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${NumberFormatter.format(db.rubRate)} so'm",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF06B6D4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // EUR Chip
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text("€", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                                    SizedBox(width: 4),
                                    Text("EUR", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${NumberFormatter.format(db.eurRate)} so'm",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 12, color: AppTheme.neonGreen),
                      const SizedBox(width: 6),
                      Text(
                        "Xalq banki & Markaziy Bank rasmiy kursi (${db.ratesDate})",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. App Settings Section
                Text(t('appSettings'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textPrimary)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        // Theme Switch
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Icon(widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.neonGreen, size: 20),
                          ),
                          title: Text(t('darkMode'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          trailing: Switch(
                            value: widget.isDarkMode,
                            onChanged: (_) => widget.onThemeToggle(),
                            activeColor: AppTheme.neonGreen,
                          ),
                        ),
                        Divider(height: 1, color: cardBorder),

                        // Language Selector
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.language_rounded, color: Color(0xFF06B6D4), size: 20),
                          ),
                          title: Text(t('appLanguage'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          trailing: DropdownButton<String>(
                            value: widget.currentLang,
                            underline: const SizedBox(),
                            dropdownColor: cardBg,
                            style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'uz', child: Text("🇺🇿 O'zbekcha")),
                              DropdownMenuItem(value: 'uz_cyr', child: Text("🇺🇿 Ўзбекча")),
                              DropdownMenuItem(value: 'ru', child: Text("🇷🇺 Русский")),
                              DropdownMenuItem(value: 'en', child: Text("🇬🇧 English")),
                            ],
                            onChanged: (v) {
                              if (v != null) widget.onLanguageChanged(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Data & Security Section (Excel, JSON Export & Import, PIN/Biometrics)
                Text(t('dataAndSecurity'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textPrimary)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        // 1. Excel / CSV Export
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.table_chart_rounded, color: AppTheme.neonGreen, size: 20),
                          ),
                          title: Text(t('exportCsv'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          subtitle: Text(t('exportCsvSub'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _handleExportCsv,
                        ),
                        Divider(height: 1, color: cardBorder),

                        // 2. JSON Backup Export
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.cloud_download_rounded, color: Color(0xFFF59E0B), size: 20),
                          ),
                          title: Text(t('exportJson'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          subtitle: Text(t('exportJsonSub'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _handleExportJson,
                        ),
                        Divider(height: 1, color: cardBorder),

                        // 3. JSON Backup Import / Restore
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.file_upload_rounded, color: Color(0xFF06B6D4), size: 20),
                          ),
                          title: Text(t('importJson'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          subtitle: Text(t('importJsonSub'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _handleImportJson,
                        ),
                        Divider(height: 1, color: cardBorder),

                        // 4. PIN & Biometrics Security
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (security.isPinEnabled ? AppTheme.neonGreen : AppTheme.danger).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              security.isPinEnabled ? Icons.lock_rounded : Icons.lock_outline_rounded,
                              color: security.isPinEnabled ? AppTheme.neonGreen : AppTheme.danger,
                              size: 20,
                            ),
                          ),
                          title: Text(t('securityTitle'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          subtitle: Text(
                            security.isPinEnabled ? t('securityActive') : t('securityDisabled'),
                            style: TextStyle(fontSize: 11, color: security.isPinEnabled ? AppTheme.neonGreen : Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _handleSecuritySettings,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => db.logout(),
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                    label: Text(t('logout'), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 6. Delete Account Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _handleDeleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.danger, size: 20),
                    label: Text(t('deleteAccount'), style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),

                // Floating bottom navigation bar space with clean spacing
                SizedBox(height: 84.0 + MediaQuery.of(context).padding.bottom + 12.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
