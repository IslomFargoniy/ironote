import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/debt_model.dart';
import '../../services/database_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class RepaymentDialog extends StatefulWidget {
  final DebtModel debt;
  final String currentLang;

  const RepaymentDialog({
    Key? key,
    required this.debt,
    required this.currentLang,
  }) : super(key: key);

  @override
  State<RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends State<RepaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _repayDate = DateTime.now();
  String? _errorMsg;

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handlePay() {
    final db = DatabaseService();
    final remaining = db.getRemainingForDebt(widget.debt.id);
    final amount = NumberFormatter.parse(_amountController.text);

    if (amount <= 0) {
      setState(() => _errorMsg = t('invalidAmount'));
      return;
    }

    if (amount > remaining) {
      setState(() => _errorMsg = "${t('excessAmount')} ${t('remaining')} ${NumberFormatter.formatCurrency(remaining, widget.debt.currency)}");
      return;
    }

    final ok = db.addRepayment(widget.debt.id, amount, _repayDate, _noteController.text.trim());
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('paymentSaved')), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final totalPaid = db.getTotalPaidForDebt(widget.debt.id);
    final remaining = db.getRemainingForDebt(widget.debt.id);
    final pastRepayments = db.getRepaymentsForDebt(widget.debt.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('repay'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Summary Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkInput : AppTheme.lightInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t('debtor'), style: const TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              widget.debt.debtorName,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t('principalDebt'), style: const TextStyle(fontSize: 13)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(NumberFormatter.formatCurrency(widget.debt.amount, widget.debt.currency)),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t('remainingDebt'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              NumberFormatter.formatCurrency(remaining, widget.debt.currency),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Amount Input (3-digit separator)
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  onChanged: (_) {
                    if (_errorMsg != null) setState(() => _errorMsg = null);
                  },
                  decoration: InputDecoration(
                    labelText: t('repayAmount'),
                    suffixText: widget.debt.currency,
                    prefixIcon: const Icon(Icons.payment_outlined),
                    suffixIcon: TextButton(
                      onPressed: () {
                        _amountController.text = NumberFormatter.format(remaining);
                        setState(() => _errorMsg = null);
                      },
                      child: Text(t('filterCompletedShort'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 4),
                  Text(_errorMsg!, style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: t('repayNote'),
                    prefixIcon: const Icon(Icons.comment_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // History list
                if (pastRepayments.isNotEmpty) ...[
                  Text(t('repayHistory'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 90),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: pastRepayments.length,
                      itemBuilder: (ctx, i) {
                        final r = pastRepayments[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd.MM.yyyy').format(r.date), style: const TextStyle(fontSize: 11)),
                              Text("+${NumberFormatter.formatCurrency(r.amount, widget.debt.currency)}", style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Actions
                ElevatedButton(
                  onPressed: _handlePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t('save'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
