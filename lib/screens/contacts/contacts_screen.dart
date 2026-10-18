import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';
import '../../widgets/glass_container.dart';
import '../debt/debt_form_screen.dart';

class ContactsScreen extends StatelessWidget {
  final String currentLang;

  const ContactsScreen({super.key, required this.currentLang});

  String t(String key) => AppTranslations.get(key, currentLang);

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(' ', '');
    final Uri uri = Uri(scheme: 'tel', path: clean);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _openTelegram(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri uri = Uri.parse("https://t.me/+$clean");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _sendSms(String phone) async {
    final clean = phone.replaceAll(' ', '');
    final Uri uri = Uri(scheme: 'sms', path: clean);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final debts = db.debts;

    // Aggregate by Debtor Name
    final contactsMap = <String, Map<String, dynamic>>{};
    for (var d in debts) {
      final key = d.debtorName;
      final rem = db.getRemainingForDebt(d.id);

      if (!contactsMap.containsKey(key)) {
        contactsMap[key] = {
          'name': d.debtorName,
          'phone': d.phone,
          'secondPhone': d.secondPhone,
          'address': d.address,
          'totalAmount': d.amount,
          'totalRemaining': rem,
          'recordsCount': 1,
        };
      } else {
        contactsMap[key]!['totalAmount'] += d.amount;
        contactsMap[key]!['totalRemaining'] += rem;
        contactsMap[key]!['recordsCount'] += 1;
      }
    }

    final contactsList = contactsMap.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t('contactsTitle'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_outlined, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${t('totalContacts')} ${contactsList.length}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(t('contactsSub'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            contactsList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(t('noContacts')),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contactsList.length,
                    itemBuilder: (context, index) {
                      final item = contactsList[index];
                      final remaining = item['totalRemaining'] as double;
                      final phone = item['phone'] as String;

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                        child: Text(
                                          item['name'][0].toUpperCase(),
                                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                            ),
                                            Text(
                                              "${item['recordsCount']} ${t('dealsCount')}",
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${NumberFormatter.format(db.convertToDisplay(remaining, 'UZS'))} ${db.displayCurrency}",
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.danger, fontSize: 14),
                                      ),
                                    ),
                                    Text(t('totalRemaining'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Quick contact buttons (Icon-only, minimalist, no overflow)
                            Row(
                              children: [
                                if (phone.isNotEmpty) ...[
                                  _buildActionIcon(
                                    icon: Icons.phone_rounded,
                                    color: AppTheme.success,
                                    onTap: () => _makeCall(phone),
                                    tooltip: t('tel'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionIcon(
                                    icon: Icons.send_rounded,
                                    color: const Color(0xFF2AABEE),
                                    onTap: () => _openTelegram(phone),
                                    tooltip: t('tg'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionIcon(
                                    icon: Icons.sms_rounded,
                                    color: Colors.purpleAccent,
                                    onTap: () => _sendSms(phone),
                                    tooltip: t('sms'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ] else ...[
                                  const Spacer(),
                                ],
                                _buildActionIcon(
                                  icon: Icons.add_rounded,
                                  color: AppTheme.primary,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => DebtFormScreen(currentLang: currentLang),
                                      ),
                                    );
                                  },
                                  tooltip: t('addNewDebt'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            SizedBox(height: 84.0 + MediaQuery.of(context).padding.bottom + 12.0),
          ],
        ),
      ),
    );
  }
}
