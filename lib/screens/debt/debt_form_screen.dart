import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/debt_model.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../utils/image_helper.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class DebtFormScreen extends StatefulWidget {
  final DebtModel? debt;
  final String currentLang;
  final String? initialType;

  const DebtFormScreen({
    super.key,
    this.debt,
    required this.currentLang,
    this.initialType,
  });

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _phoneController;
  late TextEditingController _secondPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  late String _type; // 'given' or 'taken'
  String _currency = 'UZS'; // 'UZS', 'USD', 'EUR', 'RUB'
  DateTime _debtDate = DateTime.now();
  DateTime? _deadline;
  List<String> _images = [];
  bool _isLoadingGps = false;

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _nameController = TextEditingController(text: d?.debtorName ?? '');
    _amountController = TextEditingController(
      text: d != null ? NumberFormatter.format(d.amount) : '',
    );
    _phoneController = TextEditingController(text: d?.phone ?? '+998 ');
    _secondPhoneController = TextEditingController(text: d?.secondPhone ?? '');
    _addressController = TextEditingController(text: d?.address ?? '');
    _notesController = TextEditingController(text: d?.notes ?? '');
    _type = d?.type ?? widget.initialType ?? 'given';
    _currency = d?.currency ?? 'UZS';
    _debtDate = d?.debtDate ?? DateTime.now();
    _deadline = d?.deadline;
    _images = d?.images != null ? List<String>.from(d!.images) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _secondPhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDeadline) async {
    final initialDate = isDeadline ? (_deadline ?? DateTime.now().add(const Duration(days: 30))) : _debtDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isDeadline) {
          _deadline = picked;
        } else {
          _debtDate = picked;
        }
      });
    }
  }

  Future<void> _fetchGpsLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (result != null) {
        setState(() {
          _addressController.text = result.formattedAddress;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("📍 GPS joylashuv aniqlandi: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}"),
              backgroundColor: AppTheme.neonGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("GPS ruxsati berilmadi yoki joylashuv aniqlanmadi. Iltimos brauzerda / telefonda GPS ruxsatini bering."),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("GPS error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _saveDebt() {
    if (!_formKey.currentState!.validate()) return;

    final amount = NumberFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Iltimos to'g'ri summa kiriting!")),
      );
      return;
    }

    final db = DatabaseService();
    final newDebt = DebtModel(
      id: widget.debt?.id ?? DateTime.now().millisecondsSinceEpoch,
      userId: db.currentUser?.id ?? 1001,
      debtorName: _nameController.text.trim(),
      amount: amount,
      currency: _currency,
      debtDate: _debtDate,
      deadline: _deadline,
      phone: _phoneController.text.trim(),
      secondPhone: _secondPhoneController.text.trim(),
      address: _addressController.text.trim(),
      images: _images,
      type: _type,
      notes: _notesController.text.trim(),
      status: widget.debt?.status ?? 'active',
      createdAt: widget.debt?.createdAt ?? DateTime.now(),
    );

    db.saveDebt(newDebt);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.debt != null ? "Qarz tahrirlandi!" : "Yangi qarz qo'shildi!"),
        backgroundColor: AppTheme.neonGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debt != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF071110), Color(0xFF091717), Color(0xFF050D0E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFE6F9F0), Color(0xFFDCFCE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    final cardBg = isDark ? const Color(0xFF0E1A1B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF064E3B);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isEdit ? t('editDebt') : t('addNewDebt'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 28.0 + MediaQuery.of(context).padding.bottom),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              // Debt Type Selector (Given vs Taken)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'given'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'given' ? AppTheme.neonGreen.withOpacity(0.15) : (isDark ? AppTheme.darkInput : AppTheme.lightInput),
                          border: Border.all(color: _type == 'given' ? AppTheme.neonGreen : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, color: _type == 'given' ? AppTheme.neonGreen : Colors.grey, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t('iGaveDebt'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _type == 'given' ? AppTheme.neonGreen : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'taken'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'taken' ? AppTheme.warning.withOpacity(0.15) : (isDark ? AppTheme.darkInput : AppTheme.lightInput),
                          border: Border.all(color: _type == 'taken' ? AppTheme.warning : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, color: _type == 'taken' ? AppTheme.warning : Colors.grey, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t('iTookDebt'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _type == 'taken' ? AppTheme.warning : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Currency Selector Chips (Multi-Currency)
              Text(t('currencyLabel'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCurrencyOption("UZS (so'm)", "UZS"),
                    const SizedBox(width: 8),
                    _buildCurrencyOption("\$ USD", "USD"),
                    const SizedBox(width: 8),
                    _buildCurrencyOption("₽ RUB", "RUB"),
                    const SizedBox(width: 8),
                    _buildCurrencyOption("€ EUR", "EUR"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Debtor Name
              TextFormField(
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Ism kiritilishi shart" : null,
                decoration: InputDecoration(
                  labelText: t('debtorName'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),

              // Debt Amount (with 3-digit separator input formatter)
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Summa kiritilishi shart" : null,
                decoration: InputDecoration(
                  labelText: t('amount'),
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  suffixText: _currency,
                  suffixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.neonGreen),
                ),
              ),
              if (_currency != 'UZS') ...[
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final db = DatabaseService();
                    final parsed = NumberFormatter.parse(_amountController.text);
                    final uzsVal = db.convertToUzs(parsed, _currency);
                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        "≈ ${NumberFormatter.format(uzsVal)} so'm (1 $_currency = ${NumberFormatter.format(db.getRate(_currency))} so'm)",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.neonGreen),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 14),

              // Phone numbers: Primary & Optional Secondary (Full width for mobile)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Telefon raqam shart" : null,
                decoration: InputDecoration(
                  labelText: t('phone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _secondPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t('secondPhone'),
                  prefixIcon: const Icon(Icons.phone_iphone_outlined),
                  hintText: "+998 ...",
                ),
              ),
              const SizedBox(height: 14),

              // 4. QARZ VAQTI VA QAYTARISH MUDDATI (Quick Duration Chips & Dual Date Cards)
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "QARZ VAQTI VA MUDDATI",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                      ),
                    ),
                  ),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.close_rounded, size: 12, color: AppTheme.danger),
                            SizedBox(width: 3),
                            Text(
                              "Tozalash",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.danger),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick Period Chips: [ 1 hafta ] [ 1 oy ] [ 3 oy ] [ 6 oy ] [ 1 yil ]
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildDurationChip("1 hafta", "1w", isDark, cardBg, cardBorder),
                    const SizedBox(width: 8),
                    _buildDurationChip("1 oy", "1m", isDark, cardBg, cardBorder),
                    const SizedBox(width: 8),
                    _buildDurationChip("3 oy", "3m", isDark, cardBg, cardBorder),
                    const SizedBox(width: 8),
                    _buildDurationChip("6 oy", "6m", isDark, cardBg, cardBorder),
                    const SizedBox(width: 8),
                    _buildDurationChip("1 yil", "1y", isDark, cardBg, cardBorder),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dual Date Cards: Berilgan sana & Qaytarish muddati
              Row(
                children: [
                  // Berilgan sana
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkInput : AppTheme.lightInput,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Berilgan sana *",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.neonGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(_debtDate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Qaytarish muddati
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkInput : AppTheme.lightInput,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _deadline != null ? AppTheme.neonGreen.withOpacity(0.6) : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Qaytarish muddati",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.darkTextSub : AppTheme.lightTextSub,
                                  ),
                                ),
                                if (_deadline != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _deadline = null),
                                    child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.danger),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  _deadline != null ? Icons.event_available_rounded : Icons.event_busy_outlined,
                                  size: 16,
                                  color: _deadline != null ? AppTheme.neonGreen : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _deadline != null ? DateFormat('dd.MM.yyyy').format(_deadline!) : "Tanlanmagan",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _deadline != null ? FontWeight.w800 : FontWeight.w500,
                                      color: _deadline != null ? textPrimary : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Address with GPS auto-detect button
              TextFormField(
                controller: _addressController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: t('address'),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _isLoadingGps
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonGreen),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: AppTheme.neonGreen),
                          tooltip: "Joriy GPS manzilni aniqlash",
                          onPressed: _fetchGpsLocation,
                        ),
                  hintText: "Shahar, tuman, ko'cha yoki GPS",
                ),
              ),
              if (_addressController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.neonGreen),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _addressController.text.startsWith('GPS:')
                            ? "GPS koordinata aniqlandi"
                            : "Kiritilgan manzil",
                        style: const TextStyle(fontSize: 11, color: AppTheme.neonGreen, fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      onTap: () => LocationService.openMap(_addressController.text),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: const [
                            Text(
                              "Xaritada ko'rish",
                              style: TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.w800),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF06B6D4)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // Notes / IOU details
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t('notes'),
                  hintText: "Qarz bo'yicha qo'shimcha kelishuvlar, tilxat tafsilotlari...",
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),

              // 7. Tilxat, Hujjat & Fotosuratlar (Image Attachments Section)
              _buildImageAttachmentsSection(isDark, cardBg, cardBorder, textPrimary),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: const Color(0xFF042F2E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text(
                  t('save'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
),
),
);
  }

  // --- PICK FROM DEVICE GALLERY ---
  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          final dataUrl = 'data:image/jpeg;base64,$base64String';
          setState(() => _images.add(dataUrl));
        }
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
  }

  // --- PICK FROM CAMERA ---
  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        setState(() => _images.add(dataUrl));
      }
    } catch (e) {
      debugPrint("Camera pick error: $e");
    }
  }

  // --- IMAGE ATTACHMENTS SECTION ---
  Widget _buildImageAttachmentsSection(bool isDark, Color cardBg, Color cardBorder, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.neonGreen),
                const SizedBox(width: 8),
                Text(
                  "Tilxat, Hujjat & Fotosuratlar",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
            if (_images.isNotEmpty)
              Text(
                "${_images.length} ta rasm",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.neonGreen),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_images.isEmpty)
          // Empty State Button
          InkWell(
            onTap: _openAddImageSheet,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.neonGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('imageAddButton'),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t('imageAddSub'),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Horizontal List of Images
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _images.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add More Button
                  return GestureDetector(
                    onTap: _openAddImageSheet,
                    child: Container(
                      width: 80,
                      height: 90,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_rounded, color: AppTheme.neonGreen, size: 26),
                          SizedBox(height: 4),
                          Text(
                            "+ Qo'shish",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.neonGreen),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final imgUrl = _images[index - 1];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImageView(imgUrl, index - 1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 85,
                          height: 90,
                          child: SmartImageHelper.buildImage(imgUrl, width: 85, height: 90, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    // Delete Button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(index - 1)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  // --- ADD IMAGE BOTTOM SHEET ---
  void _openAddImageSheet() {
    final customUrlController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presetPhotos = [
      {'title': 'Tilxat / Hujjat', 'url': 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=500'},
      {'title': 'Kvitansiya / Chek', 'url': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500'},
      {'title': 'Ko\'chmas mulk / Garov', 'url': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=500'},
      {'title': 'Avtomobil / Garov', 'url': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=500'},
      {'title': 'Naqd Pul / Valyuta', 'url': 'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?w=500'},
      {'title': 'Pasport / ID Karta', 'url': 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=500'},
      {'title': 'Tovarlar / Mahsulot', 'url': 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500'},
      {'title': 'Qurilish mollari', 'url': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C191A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: isDark ? const Color(0xFF1B3234) : const Color(0xFFD1FAE5)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Icon(Icons.add_photo_alternate_rounded, color: AppTheme.neonGreen),
                    SizedBox(width: 8),
                    Text(
                      "Rasm yoki Tilxat Biriktirish",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Primary Device Gallery & Camera Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickFromGallery();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.photo_library_rounded, color: AppTheme.neonGreen, size: 26),
                              SizedBox(height: 6),
                              Text(
                                "Galereyadan\ntanlash",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.neonGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _pickFromCamera();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF06B6D4), width: 1.5),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.camera_alt_rounded, color: Color(0xFF06B6D4), size: 26),
                              SizedBox(height: 6),
                              Text(
                                "Kameradan\nolish",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF06B6D4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. Preset Gallery
                const Text(
                  "Yoki namunaviy tilxatlardan tanlash:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: presetPhotos.length,
                  itemBuilder: (context, i) {
                    final item = presetPhotos[i];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _images.add(item['url']!));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(item['url']!, fit: BoxFit.cover),
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                alignment: Alignment.bottomCenter,
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  item['title']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. Custom URL Input
                const Text(
                  "Yoki Rasm Havolasini (URL) kiriting:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customUrlController,
                        decoration: InputDecoration(
                          hintText: "https://... rasm havolasi",
                          prefixIcon: const Icon(Icons.link_rounded),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final url = customUrlController.text.trim();
                        if (url.isNotEmpty) {
                          setState(() => _images.add(url));
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen,
                        foregroundColor: const Color(0xFF042F2E),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Qo'shish", style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FULL IMAGE VIEW DIALOG ---
  void _showFullImageView(String url, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 26),
                  onPressed: () {
                    setState(() => _images.removeAt(index));
                    Navigator.pop(ctx);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SmartImageHelper.buildImage(
                url,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String label, String value) {
    final isSelected = _currency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _currency = value),
      selectedColor: AppTheme.neonGreen,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF042F2E) : null,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        fontSize: 11,
      ),
    );
  }

  void _setDuration(String durationKey) {
    setState(() {
      switch (durationKey) {
        case '1w':
          _deadline = _debtDate.add(const Duration(days: 7));
          break;
        case '1m':
          _deadline = DateTime(_debtDate.year, _debtDate.month + 1, _debtDate.day);
          break;
        case '3m':
          _deadline = DateTime(_debtDate.year, _debtDate.month + 3, _debtDate.day);
          break;
        case '6m':
          _deadline = DateTime(_debtDate.year, _debtDate.month + 6, _debtDate.day);
          break;
        case '1y':
          _deadline = DateTime(_debtDate.year + 1, _debtDate.month, _debtDate.day);
          break;
      }
    });
  }

  bool _isDurationSelected(String durationKey) {
    if (_deadline == null) return false;
    final diffDays = _deadline!.difference(_debtDate).inDays;
    switch (durationKey) {
      case '1w':
        return diffDays >= 6 && diffDays <= 8;
      case '1m':
        return diffDays >= 27 && diffDays <= 32;
      case '3m':
        return diffDays >= 87 && diffDays <= 93;
      case '6m':
        return diffDays >= 178 && diffDays <= 186;
      case '1y':
        return diffDays >= 360 && diffDays <= 366;
      default:
        return false;
    }
  }

  Widget _buildDurationChip(String label, String key, bool isDark, Color cardBg, Color cardBorder) {
    final isSelected = _isDurationSelected(key);
    return InkWell(
      onTap: () => _setDuration(key),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonGreen
              : (isDark ? const Color(0xFF132324) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.neonGreen : cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.neonGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF042F2E)
                : (isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain),
          ),
        ),
      ),
    );
  }
}
