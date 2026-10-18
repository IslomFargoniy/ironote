import 'package:flutter/material.dart';

/// Password Strength & Validation Checker
/// Ensures password meets high security standards (length >= 8, uppercase, lowercase, number, special char).
class PasswordStrengthResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;
  final double score; // 0.0 to 1.0
  final bool isPerfect;
  final String statusMessage;
  final Color color;

  PasswordStrengthResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
    required this.score,
    required this.isPerfect,
    required this.statusMessage,
    required this.color,
  });
}

class PasswordValidator {
  static PasswordStrengthResult evaluate(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));

    int criteriaMet = 0;
    if (hasMinLength) criteriaMet++;
    if (hasUppercase) criteriaMet++;
    if (hasLowercase) criteriaMet++;
    if (hasDigit) criteriaMet++;
    if (hasSpecialChar) criteriaMet++;

    final score = criteriaMet / 5.0;
    final isPerfect = criteriaMet == 5;

    String statusMessage;
    Color color;

    if (password.isEmpty) {
      statusMessage = "Parol kiritilishi shart";
      color = const Color(0xFFF43F5E); // Red
    } else if (!isPerfect) {
      // Missing requirements message
      final missing = <String>[];
      if (!hasMinLength) missing.add("kamida 8 belgi");
      if (!hasUppercase) missing.add("katta harf (A-Z)");
      if (!hasLowercase) missing.add("kichik harf (a-z)");
      if (!hasDigit) missing.add("raqam (0-9)");
      if (!hasSpecialChar) missing.add("maxsus belgi (!@#\$)");

      statusMessage = "Mukammal emas: ${missing.join(', ')} kerak!";
      color = const Color(0xFFF43F5E); // Qizil rang
    } else {
      statusMessage = "Mukammal va juda xavfsiz parol! ✓";
      color = const Color(0xFF10B981); // Yashil rang
    }

    return PasswordStrengthResult(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasDigit: hasDigit,
      hasSpecialChar: hasSpecialChar,
      score: score,
      isPerfect: isPerfect,
      statusMessage: statusMessage,
      color: color,
    );
  }
}
