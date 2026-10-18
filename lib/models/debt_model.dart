import 'dart:convert';

/// Debt Model representing the `debts` table schema with multi-currency support
class DebtModel {
  final int id;
  final int userId;
  String debtorName;
  double amount;
  String currency; // 'UZS', 'USD', 'EUR', 'RUB'
  DateTime debtDate;
  DateTime? deadline;
  String phone;
  String secondPhone;
  String address;
  List<String> images; // JSON array of image URLs or base64 strings
  String type; // 'given' (Kirim/Chiqim: Men berdim) or 'taken' (Men oldim)
  String notes;
  String status; // 'active' or 'completed'
  DateTime createdAt;

  DebtModel({
    required this.id,
    required this.userId,
    required this.debtorName,
    required this.amount,
    this.currency = 'UZS',
    required this.debtDate,
    this.deadline,
    required this.phone,
    this.secondPhone = '',
    this.address = '',
    this.images = const [],
    this.type = 'given',
    this.notes = '',
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'debtor_name': debtorName,
      'amount': amount,
      'currency': currency,
      'debt_date': debtDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'phone': phone,
      'second_phone': secondPhone,
      'address': address,
      'images': jsonEncode(images),
      'type': type,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedImages = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        parsedImages = List<String>.from(map['images']);
      } else if (map['images'] is String && (map['images'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(map['images']);
          if (decoded is List) {
            parsedImages = List<String>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return DebtModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      userId: map['user_id'] is int ? map['user_id'] : int.tryParse(map['user_id'].toString()) ?? 0,
      debtorName: map['debtor_name'] ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount'].toString()) ?? 0.0,
      currency: map['currency'] ?? 'UZS',
      debtDate: map['debt_date'] != null ? DateTime.tryParse(map['debt_date']) ?? DateTime.now() : DateTime.now(),
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline']) : null,
      phone: map['phone'] ?? '',
      secondPhone: map['second_phone'] ?? '',
      address: map['address'] ?? '',
      images: parsedImages,
      type: map['type'] ?? 'given',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
