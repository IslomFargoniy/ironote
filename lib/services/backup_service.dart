import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/debt_model.dart';
import 'database_service.dart';
import 'export/file_saver.dart';

class ImportResult {
  final bool success;
  final int importedDebtsCount;
  final int importedRepaymentsCount;
  final String message;

  ImportResult({
    required this.success,
    this.importedDebtsCount = 0,
    this.importedRepaymentsCount = 0,
    required this.message,
  });
}

class BackupService {
  /// Export all debts to a CSV file compatible with Excel
  static Future<bool> exportCsv() async {
    try {
      final db = DatabaseService();
      final debts = db.debts;
      final dateFormat = DateFormat('yyyy-MM-dd');
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

      final buffer = StringBuffer();
      // UTF-8 BOM for Microsoft Excel compatibility
      buffer.write('\uFEFF');

      // CSV Header
      buffer.writeln(
        'ID,Qarzdor Ismi,Qarz Turi,Summa,Valyuta,Berilgan Sana,Qaytarish Muddati,Telefon,Qo\'shimcha Telefon,Manzil,To\'langan Summa,Qoldiq Summa,Holat,Izoh / Tilxat',
      );

      for (final d in debts) {
        final paid = db.getTotalPaidForDebt(d.id);
        final remaining = (d.amount - paid).clamp(0.0, d.amount);
        final isGiven = d.type == 'given';
        final typeStr = isGiven ? 'Berilgan (Kirim)' : 'Olingan (Chiqim)';
        final debtDateStr = dateFormat.format(d.debtDate);
        final deadlineStr = d.deadline != null ? dateFormat.format(d.deadline!) : '-';
        final statusStr = d.status == 'completed' || remaining <= 0 ? 'To\'langan' : 'Faol';

        final cleanNotes = d.notes.replaceAll('"', '""');
        final cleanAddress = d.address.replaceAll('"', '""');
        final cleanName = d.debtorName.replaceAll('"', '""');

        buffer.writeln(
          '${d.id},"$cleanName","$typeStr",${d.amount},"${d.currency}","$debtDateStr","$deadlineStr","${d.phone}","${d.secondPhone}","$cleanAddress",$paid,$remaining,"$statusStr","$cleanNotes"',
        );
      }

      final bytes = utf8.encode(buffer.toString());
      await FileExportHelper.saveFile(
        bytes: bytes,
        fileName: 'Ironote_Qarzlar_$dateStr.csv',
        mimeType: 'text/csv;charset=utf-8',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Export complete database backup as JSON
  static Future<bool> exportJsonBackup() async {
    try {
      final db = DatabaseService();
      final user = db.currentUser;
      final debts = db.debts;
      final allRepayments = <Map<String, dynamic>>[];

      for (final d in debts) {
        final reps = db.getRepaymentsForDebt(d.id);
        for (final r in reps) {
          allRepayments.add(r.toMap());
        }
      }

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final backupData = {
        'app': 'Ironote Qarz Daftari',
        'version': '2.0',
        'export_timestamp': DateTime.now().toIso8601String(),
        'user': user?.toMap(),
        'debts': debts.map((d) => d.toMap()).toList(),
        'repayments': allRepayments,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = utf8.encode(jsonString);

      await FileExportHelper.saveFile(
        bytes: bytes,
        fileName: 'Ironote_Backup_$dateStr.json',
        mimeType: 'application/json;charset=utf-8',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Import/Restore backup from raw JSON string
  static ImportResult importFromJsonString(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return ImportResult(success: false, message: "Noto'g'ri fayl formati!");
      }

      final db = DatabaseService();
      final currentUserId = db.currentUser?.id ?? 1001;

      final debtsList = decoded['debts'];
      if (debtsList is! List) {
        return ImportResult(success: false, message: "Faylda qarzlar ma'lumoti topilmadi!");
      }

      int importedDebts = 0;
      int importedRepayments = 0;

      // Mapping from old debt ID in backup to new debt ID in db
      final Map<int, int> debtIdMap = {};

      for (final item in debtsList) {
        if (item is Map<String, dynamic>) {
          final oldId = item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch;
          final newId = DateTime.now().millisecondsSinceEpoch + importedDebts + 10;
          debtIdMap[oldId] = newId;

          final debt = DebtModel(
            id: newId,
            userId: currentUserId,
            debtorName: item['debtor_name'] ?? item['debtorName'] ?? 'Qarzdor',
            amount: (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0,
            currency: item['currency'] ?? 'UZS',
            debtDate: item['debt_date'] != null ? DateTime.tryParse(item['debt_date']) ?? DateTime.now() : DateTime.now(),
            deadline: item['deadline'] != null ? DateTime.tryParse(item['deadline']) : null,
            phone: item['phone'] ?? '',
            secondPhone: item['second_phone'] ?? item['secondPhone'] ?? '',
            address: item['address'] ?? '',
            images: (item['images'] is List)
                ? List<String>.from(item['images'])
                : (item['images'] is String
                    ? List<String>.from(jsonDecode(item['images'] as String))
                    : []),
            type: item['type'] ?? 'given',
            notes: item['notes'] ?? '',
            status: item['status'] ?? 'active',
            createdAt: item['created_at'] != null ? DateTime.tryParse(item['created_at']) ?? DateTime.now() : DateTime.now(),
          );

          db.saveDebt(debt);
          importedDebts++;
        }
      }

      // Restore Repayments
      final repaymentsList = decoded['repayments'];
      if (repaymentsList is List) {
        for (final item in repaymentsList) {
          if (item is Map<String, dynamic>) {
            final oldDebtId = item['debt_id'] ?? item['debtId'];
            final targetDebtId = (oldDebtId != null && debtIdMap.containsKey(oldDebtId)) ? debtIdMap[oldDebtId]! : null;

            if (targetDebtId != null) {
              final repAmount = (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0;
              final repDate = item['date'] != null ? DateTime.tryParse(item['date']) ?? DateTime.now() : DateTime.now();
              final repNote = item['note'] ?? '';

              db.addRepayment(targetDebtId, repAmount, repDate, repNote);
              importedRepayments++;
            }
          }
        }
      }

      return ImportResult(
        success: true,
        importedDebtsCount: importedDebts,
        importedRepaymentsCount: importedRepayments,
        message: "$importedDebts ta qarz va $importedRepayments ta to'lovlar muvaffaqiyatli tiklandi!",
      );
    } catch (e) {
      return ImportResult(success: false, message: "Tiklashda xatolik yuz berdi: $e");
    }
  }

  /// Pick JSON file and restore
  static Future<ImportResult> pickAndRestoreBackup() async {
    try {
      final jsonContent = await FileExportHelper.pickJsonFile();
      if (jsonContent == null || jsonContent.trim().isEmpty) {
        return ImportResult(success: false, message: "Fayl tanlanmadi yoki bo'sh.");
      }
      return importFromJsonString(jsonContent);
    } catch (e) {
      return ImportResult(success: false, message: "Faylni o'qishda xatolik: $e");
    }
  }
}
