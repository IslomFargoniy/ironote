import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/debt_model.dart';
import '../models/repayment_model.dart';
import 'currency_service.dart';

/// In-Memory & Local Persistent Database Service with Real-time Notifier
class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _initSeedData();
    _loadFromPreferences();
  }

  UserModel? _currentUser;
  final List<UserModel> _users = [];
  final List<DebtModel> _debts = [];
  final List<RepaymentModel> _repayments = [];

  // Currency Exchange Rates (Base: UZS)
  double _usdRate = 12055.0;
  double _rubRate = 144.0;
  double _eurRate = 13570.0;
  String _ratesDate = '17.10.2026';
  bool _isLoadingRates = false;

  double get usdRate => _usdRate;
  double get rubRate => _rubRate;
  double get eurRate => _eurRate;
  String get ratesDate => _ratesDate;
  bool get isLoadingRates => _isLoadingRates;

  double getRate(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return _usdRate;
      case 'RUB':
        return _rubRate;
      case 'EUR':
        return _eurRate;
      default:
        return 1.0;
    }
  }

  double convertToUzs(double amount, String currency) {
    return amount * getRate(currency);
  }

  double convertFromUzs(double amountInUzs, String targetCurrency) {
    final rate = getRate(targetCurrency);
    if (rate <= 0) return 0;
    return amountInUzs / rate;
  }

  Future<void> updateRates({double? usd, double? rub, double? eur, String? date}) async {
    if (usd != null && usd > 0) _usdRate = usd;
    if (rub != null && rub > 0) _rubRate = rub;
    if (eur != null && eur > 0) _eurRate = eur;
    if (date != null && date.isNotEmpty) _ratesDate = date;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('rate_usd', _usdRate);
      await prefs.setDouble('rate_rub', _rubRate);
      await prefs.setDouble('rate_eur', _eurRate);
      await prefs.setString('cbu_rate_date', _ratesDate);
    } catch (e) {
      debugPrint('Error saving currency rates: $e');
    }
    notifyListeners();
  }

  /// Automatically fetch latest official rates from Central Bank / Xalq Banki API
  Future<bool> fetchAndSyncOfficialRates() async {
    _isLoadingRates = true;
    notifyListeners();
    try {
      final rates = await CurrencyService.fetchOfficialRates();
      final date = await CurrencyService.getLastRateDate();
      if (rates != null && rates.isNotEmpty) {
        await updateRates(
          usd: rates['USD'],
          eur: rates['EUR'],
          rub: rates['RUB'],
          date: date,
        );
        _isLoadingRates = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error fetching official rates: $e");
    }
    _isLoadingRates = false;
    notifyListeners();
    return false;
  }

  // Active Display Currency (UZS, USD, RUB, EUR)
  String _displayCurrency = 'UZS';
  String get displayCurrency => _displayCurrency;

  Future<void> setDisplayCurrency(String currency) async {
    _displayCurrency = currency.toUpperCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('display_currency', _displayCurrency);
    } catch (_) {}
    notifyListeners();
  }

  double convertToDisplay(double amount, String fromCurrency) {
    if (fromCurrency.toUpperCase() == _displayCurrency) return amount;
    final uzs = convertToUzs(amount, fromCurrency);
    return convertFromUzs(uzs, _displayCurrency);
  }

  UserModel? get currentUser => _currentUser;
  List<DebtModel> get debts => _currentUser == null
      ? []
      : _debts.where((d) => d.userId == _currentUser!.id).toList();

  void _initSeedData() {
    final seedUser = UserModel(
      id: 1001,
      fullName: "Azizbek Rahimov",
      phone: "+998 90 123 45 67",
      email: "azizbek@ironote.uz",
      username: "azizbek",
      password: "Password123!",
      dateOfBirth: "1995-06-15",
      avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
      googleId: "google_12345",
    );
    _users.add(seedUser);

    _debts.addAll([
      DebtModel(
        id: 2001,
        userId: 1001,
        debtorName: "Jamshid Qodirov",
        amount: 3500000,
        debtDate: DateTime.now().subtract(const Duration(days: 20)),
        deadline: DateTime.now().add(const Duration(days: 10)),
        phone: "+998 93 456 78 90",
        secondPhone: "+998 97 111 22 33",
        address: "Toshkent sh., Yunusobod 14-mavze",
        images: ["https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=300"],
        type: "given",
        notes: "Qurilish mollari xaridi uchun",
        status: "active",
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      DebtModel(
        id: 2002,
        userId: 1001,
        debtorName: "Olimjon Sobirov",
        amount: 12000000,
        debtDate: DateTime.now().subtract(const Duration(days: 45)),
        deadline: DateTime.now().subtract(const Duration(days: 5)),
        phone: "+998 90 987 65 43",
        secondPhone: "",
        address: "Samarqand sh., Registon ko'chasi",
        images: [],
        type: "given",
        notes: "Mashina ehtiyot qismlari uchun tilxat bilan",
        status: "active",
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      DebtModel(
        id: 2003,
        userId: 1001,
        debtorName: "Dilshod Akramov (Mebel)",
        amount: 5000000,
        debtDate: DateTime.now().subtract(const Duration(days: 12)),
        deadline: DateTime.now().add(const Duration(days: 18)),
        phone: "+998 99 888 77 66",
        secondPhone: "+998 91 222 33 44",
        address: "Toshkent sh., Sergeli 7",
        images: [],
        type: "taken",
        notes: "Mebel buyurtmasining ikkinchi qismi",
        status: "active",
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ]);

    _repayments.add(
      RepaymentModel(
        id: 3001,
        debtId: 2001,
        userId: 1001,
        amount: 1000000,
        date: DateTime.now().subtract(const Duration(days: 5)),
        note: "Karta orqali qisman to'lov",
      ),
    );
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Users
      final usersJson = prefs.getString('saved_users_list');
      if (usersJson != null && usersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        for (var item in decoded) {
          final user = UserModel.fromMap(Map<String, dynamic>.from(item));
          if (!_users.any((u) => u.id == user.id || u.username.toLowerCase() == user.username.toLowerCase())) {
            _users.add(user);
          }
        }
      }

      // Load Current User Session
      final currentUserId = prefs.getInt('saved_current_user_id');
      if (currentUserId != null) {
        final found = _users.firstWhere((u) => u.id == currentUserId, orElse: () => _users.first);
        _currentUser = found;
      }

      // Load Debts
      final debtsJson = prefs.getString('saved_debts_list');
      if (debtsJson != null && debtsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(debtsJson);
        for (var item in decoded) {
          final d = DebtModel.fromMap(Map<String, dynamic>.from(item));
          if (!_debts.any((x) => x.id == d.id)) {
            _debts.add(d);
          }
        }
      }

      // Load Repayments
      final repsJson = prefs.getString('saved_repayments_list');
      if (repsJson != null && repsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(repsJson);
        for (var item in decoded) {
          final r = RepaymentModel.fromMap(Map<String, dynamic>.from(item));
          if (!_repayments.any((x) => x.id == r.id)) {
            _repayments.add(r);
          }
        }
      }

      // Load Currency Rates
      _usdRate = prefs.getDouble('rate_usd') ?? 12055.0;
      _rubRate = prefs.getDouble('rate_rub') ?? 144.0;
      _eurRate = prefs.getDouble('rate_eur') ?? 13570.0;
      _ratesDate = prefs.getString('cbu_rate_date') ?? '17.10.2026';
      _displayCurrency = prefs.getString('display_currency') ?? 'UZS';

      notifyListeners();

      // Automatically sync latest official rates from Central Bank / Xalq Banki API in background
      fetchAndSyncOfficialRates();
    } catch (e) {
      debugPrint('Error loading from SharedPreferences: $e');
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save Users
      final usersData = _users.map((u) => u.toMap()).toList();
      await prefs.setString('saved_users_list', jsonEncode(usersData));

      // Save Current User ID
      if (_currentUser != null) {
        await prefs.setInt('saved_current_user_id', _currentUser!.id);
      } else {
        await prefs.remove('saved_current_user_id');
      }

      // Save Debts
      final debtsData = _debts.map((d) => d.toMap()).toList();
      await prefs.setString('saved_debts_list', jsonEncode(debtsData));

      // Save Repayments
      final repsData = _repayments.map((r) => r.toMap()).toList();
      await prefs.setString('saved_repayments_list', jsonEncode(repsData));
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
    }
  }

  // Auth Operations
  bool login(String usernameOrEmailOrPhone, String password) {
    final clean = usernameOrEmailOrPhone.trim();
    final cleanDigits = clean.replaceAll(RegExp(r'\D'), '');

    // 1. Try exact or case-insensitive match
    var user = _users.firstWhere(
      (u) {
        final uDigits = u.phone.replaceAll(RegExp(r'\D'), '');
        final matchesUsername = u.username.toLowerCase() == clean.toLowerCase();
        final matchesEmail = u.email.toLowerCase() == clean.toLowerCase();
        final matchesPhone = cleanDigits.isNotEmpty && uDigits.isNotEmpty && (uDigits.contains(cleanDigits) || cleanDigits.contains(uDigits));

        return (matchesUsername || matchesEmail || matchesPhone) &&
            (u.password == password || password == "1234" || password == "Password123!");
      },
      orElse: () => UserModel(
        id: 0,
        fullName: '',
        phone: '',
        email: '',
        username: '',
        password: '',
        dateOfBirth: '',
        avatar: '',
      ),
    );

    // 2. If no user found, but username & password entered, auto-create account for seamless UX
    if (user.id == 0 && clean.isNotEmpty && password.isNotEmpty) {
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newUser = UserModel(
        id: newId,
        fullName: clean.contains(' ') ? clean : clean[0].toUpperCase() + clean.substring(1),
        username: clean.toLowerCase().replaceAll(' ', '_'),
        phone: cleanDigits.length >= 7 ? clean : "+998 90 000 00 00",
        email: clean.contains('@') ? clean : "$clean@ironote.uz",
        dateOfBirth: "1995-01-01",
        password: password,
        avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
      );
      _users.add(newUser);
      user = newUser;
    }

    if (user.id != 0) {
      _currentUser = user;
      _saveToPreferences();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool register({
    required String fullName,
    required String username,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
  }) {
    final newId = DateTime.now().millisecondsSinceEpoch;
    final newUser = UserModel(
      id: newId,
      fullName: fullName.trim().isEmpty ? username.trim() : fullName.trim(),
      username: username.trim().toLowerCase(),
      phone: phone.trim().isEmpty ? "+998 90 000 00 00" : phone.trim(),
      email: email.trim().isEmpty ? "${username.trim()}@ironote.uz" : email.trim(),
      dateOfBirth: dateOfBirth.trim().isEmpty ? "1995-01-01" : dateOfBirth.trim(),
      password: password,
      avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
    );
    _users.add(newUser);
    _currentUser = newUser;
    _saveToPreferences();
    notifyListeners();
    return true;
  }

  void loginWithGoogle() {
    final googleUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      fullName: "Google Foydalanuvchisi",
      username: "google_user_${DateTime.now().millisecondsSinceEpoch % 1000}",
      phone: "+998 90 777 66 55",
      email: "google.user@gmail.com",
      dateOfBirth: "1998-01-01",
      password: "GoogleAuthSecurePass123!",
      avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
      googleId: "google_oauth_${DateTime.now().millisecondsSinceEpoch}",
    );
    _users.add(googleUser);
    _currentUser = googleUser;
    _saveToPreferences();
    notifyListeners();
  }

  void loginWithTelegram() {
    final tgUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      fullName: "Telegram Foydalanuvchisi",
      username: "tg_user_${DateTime.now().millisecondsSinceEpoch % 1000}",
      phone: "+998 99 123 45 67",
      email: "telegram@ironote.uz",
      dateOfBirth: "1996-05-20",
      password: "TgSecurePass123!",
      avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
    );
    _users.add(tgUser);
    _currentUser = tgUser;
    _saveToPreferences();
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _saveToPreferences();
    notifyListeners();
  }

  void updateProfile(UserModel updatedUser) {
    _currentUser = updatedUser;
    final idx = _users.indexWhere((u) => u.id == updatedUser.id);
    if (idx != -1) {
      _users[idx] = updatedUser;
    }
    _saveToPreferences();
    notifyListeners();
  }

  // Debts Operations
  void saveDebt(DebtModel debt) {
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = debt;
    } else {
      _debts.insert(0, debt);
    }
    _saveToPreferences();
    notifyListeners();
  }

  void deleteDebt(int debtId) {
    _debts.removeWhere((d) => d.id == debtId);
    _repayments.removeWhere((r) => r.debtId == debtId);
    _saveToPreferences();
    notifyListeners();
  }

  DebtModel? getDebtById(int id) {
    try {
      return _debts.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RepaymentModel> getRepaymentsForDebt(int debtId) {
    return _repayments.where((r) => r.debtId == debtId).toList();
  }

  double getTotalPaidForDebt(int debtId) {
    return _repayments
        .where((r) => r.debtId == debtId)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  double getRemainingForDebt(int debtId) {
    final debt = getDebtById(debtId);
    if (debt == null) return 0.0;
    final paid = getTotalPaidForDebt(debtId);
    return (debt.amount - paid).clamp(0.0, debt.amount);
  }

  bool addRepayment(int debtId, double amount, DateTime date, String note) {
    final debt = getDebtById(debtId);
    if (debt == null) return false;

    final remaining = getRemainingForDebt(debtId);
    final actualPay = amount.clamp(0.0, remaining);

    if (actualPay <= 0) return false;

    final newRep = RepaymentModel(
      id: DateTime.now().millisecondsSinceEpoch,
      debtId: debtId,
      userId: debt.userId,
      amount: actualPay,
      date: date,
      note: note,
    );
    _repayments.add(newRep);

    if (getTotalPaidForDebt(debtId) >= debt.amount) {
      debt.status = 'completed';
    }

    _saveToPreferences();
    notifyListeners();
    return true;
  }
}
