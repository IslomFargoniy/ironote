/// Model representing the repayments (To'lovlar tarixi)
class RepaymentModel {
  final int id;
  final int debtId;
  final int userId;
  final double amount;
  final DateTime date;
  final String note;

  RepaymentModel({
    required this.id,
    required this.debtId,
    required this.userId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory RepaymentModel.fromMap(Map<String, dynamic> map) {
    return RepaymentModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      debtId: map['debt_id'] is int ? map['debt_id'] : int.tryParse(map['debt_id'].toString()) ?? 0,
      userId: map['user_id'] is int ? map['user_id'] : int.tryParse(map['user_id'].toString()) ?? 0,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount'].toString()) ?? 0.0,
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      note: map['note'] ?? '',
    );
  }
}
