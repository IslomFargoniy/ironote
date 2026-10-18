import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironote/screens/contacts/contacts_screen.dart';
import 'package:ironote/screens/notifications/reminders_screen.dart';
import 'package:ironote/utils/translations.dart';

void main() {
  group('Comprehensive Multi-Language Switching & UI Verification', () {
    test('Translation dictionary accuracy across Uzbek, Russian, and English', () {
      // 1. App Title
      expect(AppTranslations.get('appTitle', 'uz'), 'IroNote');
      expect(AppTranslations.get('appTitle', 'ru'), 'IroNote');
      expect(AppTranslations.get('appTitle', 'en'), 'IroNote');

      // 2. Navigation items
      expect(AppTranslations.get('navHome', 'uz'), 'Asosiy');
      expect(AppTranslations.get('navHome', 'ru'), 'Главная');
      expect(AppTranslations.get('navHome', 'en'), 'Home');

      expect(AppTranslations.get('navAnalytics', 'uz'), 'Statistika');
      expect(AppTranslations.get('navAnalytics', 'ru'), 'Статистика');
      expect(AppTranslations.get('navAnalytics', 'en'), 'Analytics');

      expect(AppTranslations.get('navReminders', 'uz'), 'Eslatmalar');
      expect(AppTranslations.get('navReminders', 'ru'), 'Напоминания');
      expect(AppTranslations.get('navReminders', 'en'), 'Reminders');

      expect(AppTranslations.get('navContacts', 'uz'), 'Kontaktlar');
      expect(AppTranslations.get('navContacts', 'ru'), 'Контакты');
      expect(AppTranslations.get('navContacts', 'en'), 'Contacts');

      expect(AppTranslations.get('navSettings', 'uz'), 'Sozlamalar');
      expect(AppTranslations.get('navSettings', 'ru'), 'Настройки');
      expect(AppTranslations.get('navSettings', 'en'), 'Settings');

      // 3. Debt Form labels
      expect(AppTranslations.get('addNewDebt', 'uz'), 'Yangi Qarz Qo\'shish');
      expect(AppTranslations.get('addNewDebt', 'ru'), 'Добавить Новый Долг');
      expect(AppTranslations.get('addNewDebt', 'en'), 'Add New Debt');

      expect(AppTranslations.get('save', 'uz'), 'Saqlash');
      expect(AppTranslations.get('save', 'ru'), 'Сохранить');
      expect(AppTranslations.get('save', 'en'), 'Save');

      // 4. Notifications & Reminders
      expect(AppTranslations.get('remindersTitle', 'uz'), 'SMS & Telegram Eslatmalar');
      expect(AppTranslations.get('remindersTitle', 'ru'), 'SMS & Telegram Напоминания');
      expect(AppTranslations.get('remindersTitle', 'en'), 'SMS & Telegram Reminders');

      expect(AppTranslations.get('notificationsTitle', 'uz'), 'Xabarlar & Eslatmalar');
      expect(AppTranslations.get('notificationsTitle', 'ru'), 'Уведомления и Напоминания');
      expect(AppTranslations.get('notificationsTitle', 'en'), 'Notifications & Reminders');

      // 5. Currency rates & month
      expect(AppTranslations.get('currencyRates', 'uz'), 'Valyuta Kursi');
      expect(AppTranslations.get('currencyRates', 'ru'), 'Курсы валют');
      expect(AppTranslations.get('currencyRates', 'en'), 'Exchange Rates');

      expect(AppTranslations.get('monthShort', 'uz'), 'oy');
      expect(AppTranslations.get('monthShort', 'ru'), 'мес');
      expect(AppTranslations.get('monthShort', 'en'), 'mo');
    });

    testWidgets('ContactsScreen renders properly in Uzbek, Russian, and English', (tester) async {
      for (final lang in ['uz', 'ru', 'en']) {
        await tester.pumpWidget(
          MaterialApp(
            home: ContactsScreen(currentLang: lang),
          ),
        );
        await tester.pumpAndSettle();

        final expectedTitle = AppTranslations.get('contactsTitle', lang);
        expect(find.text(expectedTitle), findsOneWidget,
            reason: 'ContactsScreen title should match for language $lang');
      }
    });

    testWidgets('RemindersScreen renders properly in Uzbek, Russian, and English', (tester) async {
      for (final lang in ['uz', 'ru', 'en']) {
        await tester.pumpWidget(
          MaterialApp(
            home: RemindersScreen(currentLang: lang),
          ),
        );
        await tester.pumpAndSettle();

        final expectedTitle = AppTranslations.get('remindersTitle', lang);
        expect(find.text(expectedTitle), findsOneWidget,
            reason: 'RemindersScreen title should match for language $lang');
      }
    });

    testWidgets('Language switching updates reactive string outputs in real-time', (tester) async {
      String currentLanguage = 'uz';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text(AppTranslations.get('navHome', currentLanguage)),
                    Text(AppTranslations.get('navAnalytics', currentLanguage)),
                    Text(AppTranslations.get('navReminders', currentLanguage)),
                    ElevatedButton(
                      onPressed: () => setState(() => currentLanguage = 'ru'),
                      child: const Text('Switch to RU'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => currentLanguage = 'en'),
                      child: const Text('Switch to EN'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Check initial Uzbek
      expect(find.text('Asosiy'), findsOneWidget);
      expect(find.text('Statistika'), findsOneWidget);
      expect(find.text('Eslatmalar'), findsOneWidget);

      // Switch to Russian
      await tester.tap(find.text('Switch to RU'));
      await tester.pumpAndSettle();
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Статистика'), findsOneWidget);
      expect(find.text('Напоминания'), findsOneWidget);

      // Switch to English
      await tester.tap(find.text('Switch to EN'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
    });
  });
}
