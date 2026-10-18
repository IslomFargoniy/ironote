import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironote/utils/translations.dart';

void main() {
  group('AppTranslations Deep Analysis & Verification', () {
    final uzKeys = AppTranslations.values['uz']!.keys.toSet();
    final ruKeys = AppTranslations.values['ru']!.keys.toSet();
    final enKeys = AppTranslations.values['en']!.keys.toSet();
    final uzCyrKeys = AppTranslations.values['uz_cyr']!.keys.toSet();

    test('All 4 languages are defined in AppTranslations.values', () {
      expect(AppTranslations.values.containsKey('uz'), isTrue);
      expect(AppTranslations.values.containsKey('uz_cyr'), isTrue);
      expect(AppTranslations.values.containsKey('ru'), isTrue);
      expect(AppTranslations.values.containsKey('en'), isTrue);
    });

    test('Uzbek (uz) keys count and non-empty values', () {
      expect(uzKeys.isNotEmpty, isTrue);
      for (final entry in AppTranslations.values['uz']!.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue,
            reason: "Key '${entry.key}' in 'uz' has empty value");
      }
    });

    test('Russian (ru) translation completeness against uz', () {
      final missingInRu = uzKeys.difference(ruKeys);
      final extraInRu = ruKeys.difference(uzKeys);

      print('UZ keys count: ${uzKeys.length}');
      print('RU keys count: ${ruKeys.length}');
      if (missingInRu.isNotEmpty) {
        print('Missing in RU: $missingInRu');
      }
      if (extraInRu.isNotEmpty) {
        print('Extra in RU: $extraInRu');
      }

      for (final entry in AppTranslations.values['ru']!.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue,
            reason: "Key '${entry.key}' in 'ru' has empty value");
      }

      expect(missingInRu, isEmpty,
          reason: 'Keys present in UZ but missing in RU: $missingInRu');
    });

    test('English (en) translation completeness against uz', () {
      final missingInEn = uzKeys.difference(enKeys);
      final extraInEn = enKeys.difference(uzKeys);

      print('EN keys count: ${enKeys.length}');
      if (missingInEn.isNotEmpty) {
        print('Missing in EN: $missingInEn');
      }
      if (extraInEn.isNotEmpty) {
        print('Extra in EN: $extraInEn');
      }

      for (final entry in AppTranslations.values['en']!.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue,
            reason: "Key '${entry.key}' in 'en' has empty value");
      }

      expect(missingInEn, isEmpty,
          reason: 'Keys present in UZ but missing in EN: $missingInEn');
    });

    test('Cyrillic Uzbek (uz_cyr) translation completeness against uz', () {
      final missingInCyr = uzKeys.difference(uzCyrKeys);
      print('UZ_CYR keys count: ${uzCyrKeys.length}');
      if (missingInCyr.isNotEmpty) {
        print('Missing in UZ_CYR: $missingInCyr');
      }

      for (final entry in AppTranslations.values['uz_cyr']!.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue,
            reason: "Key '${entry.key}' in 'uz_cyr' has empty value");
      }

      expect(missingInCyr, isEmpty,
          reason: 'Keys present in UZ but missing in UZ_CYR: $missingInCyr');
    });

    test('Verify all t(...) keys used in codebase exist in translations', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final tKeyRegex = RegExp(r"""\bt\(['"]([a-zA-Z0-9_]+)['"]\)""");
      final appTransRegex =
          RegExp(r"""AppTranslations\.get\(['"]([a-zA-Z0-9_]+)['"]""");

      final usedKeys = <String>{};

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final m in tKeyRegex.allMatches(content)) {
          usedKeys.add(m.group(1)!);
        }
        for (final m in appTransRegex.allMatches(content)) {
          usedKeys.add(m.group(1)!);
        }
      }

      print('Total unique translation keys used in lib code: ${usedKeys.length}');
      final missingKeys = usedKeys.difference(uzKeys);
      if (missingKeys.isNotEmpty) {
        print('Used keys missing in AppTranslations.values["uz"]: $missingKeys');
      }
      expect(missingKeys, isEmpty,
          reason: 'Used keys missing from translation file: $missingKeys');
    });
  });
}
