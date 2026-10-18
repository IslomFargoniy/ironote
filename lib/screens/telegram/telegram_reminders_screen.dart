import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/debt_model.dart';
import '../../services/database_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';
import '../../widgets/glass_container.dart';

class TelegramRemindersScreen extends StatefulWidget {
  final String currentLang;

  const TelegramRemindersScreen({super.key, required this.currentLang});

  @override
  State<TelegramRemindersScreen> createState() => _TelegramRemindersScreenState();
}

class _TelegramRemindersScreenState extends State<TelegramRemindersScreen> {
  String _selectedTone = 'polite'; // polite | formal | urgent | friendly
  final _botTokenController = TextEditingController(text: "7489234812:AAH923jklsd...");
  final _chatIdController = TextEditingController(text: "@ironote_debt_channel");
  bool _autoNotifyEnabled = true;

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  String _generateTelegramMessage(DebtModel debt, double remaining, String tone) {
    final name = debt.debtorName;
    final amountStr = NumberFormatter.formatCurrency(remaining);
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
📞 Bog'lanish telefoni: ${DatabaseService().currentUser?.phone ?? '+998...'}
━━━━━━━━━━━━━━━━━━━━""";

      case 'friendly':
        return """Salom *$name*! 👋
Eslatib o'tmoqchiman, o'rtamizdagi qarz hisobidan *$amountStr* qoldiq qolgan edi.
Imkoniyating bo'lganda ko'rib berarsan. Rahmat! 😊""";

      case 'polite':
      default:
        return """Assalomu alaykum, hurmatli *$name*!
Sizdagi *$amountStr* miqdoridagi qarz summasini eslatib o'tmoqchimiz.
📅 Qaytarish muddati: *$deadlineStr*

Hisob-kitobni amalga oshirishda qulaylik tilaymiz. Rahmat!""";
    }
  }

  Future<void> _sendViaTelegram(DebtModel debt, double remaining) async {
    final text = _generateTelegramMessage(debt, remaining, _selectedTone);
    final encoded = Uri.encodeComponent(text);
    final Uri telegramUri = Uri.parse("https://t.me/share/url?url=&text=$encoded");

    try {
      await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telegram ilovasini ochib bo'lmadi")),
      );
    }
  }

  Future<void> _openDirectTelegramProfile(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri uri = Uri.parse("https://t.me/+$clean");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telegram profil ochilmadi")),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Xabar nusxalandi! Telegramga joylashingiz mumkin."),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final debts = db.debts.where((d) => d.type == 'given').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.telegram, color: Color(0xFF2AABEE), size: 28),
            SizedBox(width: 10),
            Text("Telegram Eslatmalar & Bot", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glass Hero Header
            GlassContainer(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF2AABEE).withValues(alpha: isDark ? 0.15 : 0.1),
              borderColor: const Color(0xFF2AABEE).withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2AABEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Telegram Smart Reminders",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              "Qarzdorlarga bir bosishda chiroyli eslatma yuboring",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tone Selection
                  const Text("Xabar uslubi (Shablon):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToneChip("✨ Xushmuomala", "polite"),
                        _buildToneChip("📜 Rasmiy", "formal"),
                        _buildToneChip("🚨 Shoshilinch", "urgent"),
                        _buildToneChip("🤝 Do'stona", "friendly"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Telegram Bot Automation Settings (Collapsible Glass)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.smart_toy_outlined, color: AppTheme.primary),
                title: const Text("Telegram Bot Avtomatizatsiyasi", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text("Har kuni ertalab qarzdorliklar hisobotini bot orqali olish", style: TextStyle(fontSize: 11, color: Colors.grey)),
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: _botTokenController,
                    decoration: const InputDecoration(
                      labelText: "Bot Token (t.me/BotFather)",
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _chatIdController,
                    decoration: const InputDecoration(
                      labelText: "Telegram Chat ID yoki Kanal",
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Avtomatik kunlik eslatma", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text("Muddati yaqinlashgan qarzlar haqida xabar berish", style: TextStyle(fontSize: 11)),
                    value: _autoNotifyEnabled,
                    onChanged: (v) => setState(() => _autoNotifyEnabled = v),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Debtors Quick List for Telegram Reminders
            const Text(
              "Qarzdorlar Ro'yxati (Eslatma yuborish)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            debts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("Sizda hozircha berilgan qarzlar yo'q"),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: debts.length,
                    itemBuilder: (context, index) {
                      final debt = debts[index];
                      final remaining = db.getRemainingForDebt(debt.id);
                      final isCompleted = debt.status == 'completed' || remaining == 0;

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF2AABEE).withValues(alpha: 0.2),
                                      child: Text(
                                        debt.debtorName.isNotEmpty ? debt.debtorName[0] : '?',
                                        style: const TextStyle(color: Color(0xFF2AABEE), fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(debt.debtorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        Text(debt.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(remaining),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isCompleted ? AppTheme.success : AppTheme.danger,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Actions: Send Telegram, Direct Chat, Copy Text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openDirectTelegramProfile(debt.phone),
                                  icon: const Icon(Icons.person_pin, size: 16),
                                  label: const Text("Profili", style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_outlined, size: 20),
                                  tooltip: "Xabarni nusxalash",
                                  onPressed: () => _copyToClipboard(_generateTelegramMessage(debt, remaining, _selectedTone)),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _sendViaTelegram(debt, remaining),
                                  icon: const Icon(Icons.send_rounded, size: 16),
                                  label: const Text("Telegramda Yuborish", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2AABEE),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneChip(String label, String value) {
    final isSelected = _selectedTone == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedTone = value),
        selectedColor: const Color(0xFF2AABEE),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
