import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service to fetch real-time official exchange rates from Central Bank of Uzbekistan / Xalq Banki
class CurrencyService {
  static const String _cbuApiUrl = 'https://cbu.uz/uz/arkhiv-kursov-valyut/json/';

  /// Fetch latest currency rates (USD, EUR, RUB) from CBU / Xalq Banki official API
  static Future<Map<String, double>?> fetchOfficialRates() async {
    try {
      final response = await http.get(
        Uri.parse(_cbuApiUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Ironote-App/1.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        double? usd;
        double? eur;
        double? rub;
        String? rateDate;

        for (var item in data) {
          final ccy = item['Ccy']?.toString().toUpperCase();
          final rateStr = item['Rate']?.toString().replaceAll(' ', '');
          final rate = double.tryParse(rateStr ?? '');

          if (ccy == 'USD' && rate != null) {
            usd = rate;
            rateDate = item['Date']?.toString();
          } else if (ccy == 'EUR' && rate != null) {
            eur = rate;
          } else if (ccy == 'RUB' && rate != null) {
            rub = rate;
          }
        }

        if (usd != null || eur != null || rub != null) {
          final prefs = await SharedPreferences.getInstance();
          if (rateDate != null) {
            await prefs.setString('cbu_rate_date', rateDate);
          }
          await prefs.setString('cbu_last_fetched', DateTime.now().toIso8601String());

          return {
            if (usd != null) 'USD': usd,
            if (eur != null) 'EUR': eur,
            if (rub != null) 'RUB': rub,
          };
        }
      }
    } catch (e) {
      debugPrint('CurrencyService fetch error: $e');
    }
    return null;
  }

  /// Get date of last official rate update
  static Future<String?> getLastRateDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('cbu_rate_date');
    } catch (_) {
      return null;
    }
  }
}
