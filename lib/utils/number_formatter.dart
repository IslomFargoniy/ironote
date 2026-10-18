import 'package:flutter/services.dart';

/// Number formatting utility for Ironote
/// Converts numbers to 3-digit grouped string (e.g., 1000000 -> 1 000 000)
class NumberFormatter {
  static String format(num? amount) {
    if (amount == null) return '0';
    final isNegative = amount < 0;
    final absAmount = amount.abs().round();
    final str = absAmount.toString();
    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    final len = str.length;

    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  static String formatCompact(num? amount, [String currency = '']) {
    if (amount == null) return '0';
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    String numStr;
    if (abs >= 1000000000) {
      numStr = '$sign${(abs / 1000000000).toStringAsFixed(1)}B';
    } else if (abs >= 1000000) {
      numStr = '$sign${(abs / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 100000) {
      numStr = '$sign${(abs / 1000).toStringAsFixed(0)}K';
    } else {
      numStr = format(amount);
    }
    return currency.isNotEmpty ? '$numStr $currency' : numStr;
  }

  static String formatCurrency(num? amount, [String currency = 'UZS']) {
    return '${format(amount)} $currency';
  }

  static double parse(String text) {
    final clean = text.replaceAll(' ', '').replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}

/// Real-time 3-digit input formatter for TextFields in Flutter
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final clean = newValue.text.replaceAll(' ', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Limit to 15 digits so large inputs never overflow int or screen
    final capped = clean.length > 15 ? clean.substring(0, 15) : clean;
    final parsed = int.tryParse(capped);
    if (parsed == null) {
      return oldValue;
    }

    final formatted = NumberFormatter.format(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
