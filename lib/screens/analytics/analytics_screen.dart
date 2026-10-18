import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/theme.dart';
import '../../utils/translations.dart';

class AnalyticsScreen extends StatefulWidget {
  final String currentLang;
  final VoidCallback? onBackToHome;

  const AnalyticsScreen({
    super.key,
    required this.currentLang,
    this.onBackToHome,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Period: 0 = Haftalik (Weekly), 1 = Oylik (Monthly), 2 = Yillik (Yearly)
  int _selectedPeriod = 0;
  int _selectedChartIndex = 3; // Active bar index

  final List<String> _weekDays = ["Dush", "Sesh", "Chor", "Pay", "Jum", "Shan", "Yak"];
  final List<String> _months = ["Yan", "Fev", "Mar", "Apr", "May", "Iyun", "Iyul", "Avg", "Sen", "Okt", "Noy", "Dek"];

  String t(String key) => AppTranslations.get(key, widget.currentLang);

  @override
  void initState() {
    super.initState();
    DatabaseService().addListener(_onDataChanged);
  }

  @override
  void dispose() {
    DatabaseService().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = DatabaseService();
    final debts = db.debts;

    // Unified Emerald Palette
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
    final textSecondary = isDark ? const Color(0xFF7B9CA0) : const Color(0xFF059669);

    // Calculate real stats
    double totalKirim = 0;
    double totalChiqim = 0;
    double givenCollected = 0;
    double takenPaid = 0;

    for (var d in debts) {
      final paid = db.getTotalPaidForDebt(d.id);
      final amountInUzs = db.convertToUzs(d.amount, d.currency);
      final paidInUzs = db.convertToUzs(paid, d.currency);
      if (d.type == 'given') {
        totalKirim += amountInUzs;
        givenCollected += paidInUzs;
      } else {
        totalChiqim += amountInUzs;
        takenPaid += paidInUzs;
      }
    }

    final sofBalans = totalKirim - totalChiqim;
    final collectionRate = totalKirim > 0 ? (givenCollected / totalKirim) * 100 : 0.0;

    // Dynamic Period labels and sample/live distribution
    final isWeekly = _selectedPeriod == 0;
    final currentLabels = isWeekly ? _weekDays : (_selectedPeriod == 1 ? _months.take(6).toList() : ["2023", "2024", "2025", "2026"]);
    final length = currentLabels.length;
    final activeIdx = _selectedChartIndex.clamp(0, length - 1);

    // Generate balanced data based on actual database totals
    final kirimData = List.generate(length, (i) {
      final base = totalKirim > 0 ? totalKirim / length : 2500000.0;
      final factor = [0.8, 0.6, 1.1, 1.4, 0.9, 0.5, 0.7][i % 7];
      return base * factor;
    });

    final chiqimData = List.generate(length, (i) {
      final base = totalChiqim > 0 ? totalChiqim / length : 1500000.0;
      final factor = [0.6, 0.9, 0.7, 1.0, 1.2, 0.4, 0.8][i % 7];
      return base * factor;
    });

    final activeKirim = kirimData[activeIdx];
    final activeChiqim = chiqimData[activeIdx];
    final activeLabel = currentLabels[activeIdx];
    final activeSof = activeKirim - activeChiqim;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Bar: Back, "Statistika & Tahlil", Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSquircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: widget.onBackToHome ?? () => Navigator.maybePop(context),
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                    ),
                    Text(
                      t('analyticsTitle'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    _buildSquircleButton(
                      icon: Icons.refresh_rounded,
                      onTap: () => setState(() {}),
                      isDark: isDark,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. Period Switcher (Haftalik, Oylik, Yillik)
                _buildPeriodSwitcher(isDark, cardBg, cardBorder, textPrimary, textSecondary),
                const SizedBox(height: 18),

                // 3. Kirim vs Chiqim Summary Cards (Green Kirim, Red Chiqim as requested)
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryBox(
                        title: "Kirim",
                        amount: "${NumberFormatter.format(db.convertFromUzs(totalKirim, db.displayCurrency))} ${db.displayCurrency}",
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.neonGreen,
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryBox(
                        title: "Chiqim",
                        amount: "${NumberFormatter.format(db.convertFromUzs(totalChiqim, db.displayCurrency))} ${db.displayCurrency}",
                        icon: Icons.arrow_downward_rounded,
                        color: AppTheme.danger,
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. Interactive Kirim-Chiqim Double Bar Chart Hero Card
                _buildKirimChiqimBarChartCard(
                  labels: currentLabels,
                  kirimData: kirimData,
                  chiqimData: chiqimData,
                  activeIdx: activeIdx,
                  activeLabel: activeLabel,
                  activeKirim: activeKirim,
                  activeChiqim: activeChiqim,
                  activeSof: activeSof,
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 20),

                // 5. Performance Trends Multi-Line Spline Wave
                _buildPerformanceTrendsCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 20),

                // 6. Sof Balans & Qarz Undirish Ko'rsatkichlari
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.3) : AppTheme.neonGreen.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('netBalance'),
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "${sofBalans >= 0 ? '+' : ''}${NumberFormatter.format(db.convertFromUzs(sofBalans, db.displayCurrency))} ${db.displayCurrency}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: sofBalans >= 0 ? AppTheme.neonGreen : AppTheme.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: AppTheme.neonGreen, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "${collectionRate.toStringAsFixed(1)}% ${t('collectedRate')}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.neonGreen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (collectionRate / 100).clamp(0.0, 1.0),
                          color: AppTheme.neonGreen,
                          backgroundColor: isDark ? const Color(0xFF132324) : const Color(0xFFD1FAE5),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Top Faol Qarzdorlar Reytingi
                Text(
                  t('topDebtors'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                ...debts.take(4).map((d) {
                  final rem = db.getRemainingForDebt(d.id);
                  final isGiven = d.type == 'given';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (isGiven ? AppTheme.neonGreen : AppTheme.danger).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isGiven ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isGiven ? AppTheme.neonGreen : AppTheme.danger,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.debtorName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                isGiven ? t('lentDebt') : t('borrowedDebt'),
                                style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "${isGiven ? '+' : '-'}${NumberFormatter.format(rem)} ${d.currency}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isGiven ? AppTheme.neonGreen : AppTheme.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Floating bottom navigation bar space with clean spacing
                SizedBox(height: 84.0 + MediaQuery.of(context).padding.bottom + 12.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PERIOD SWITCHER ---
  Widget _buildPeriodSwitcher(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1B1C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          _buildPeriodTab(t('periodWeek'), 0, isDark),
          _buildPeriodTab(t('periodMonth'), 1, isDark),
          _buildPeriodTab(t('periodYear'), 2, isDark),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String title, int index, bool isDark) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedPeriod = index;
          _selectedChartIndex = 0;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.neonGreen.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF042F2E)
                  : (isDark ? const Color(0xFF7B9CA0) : const Color(0xFF059669)),
            ),
          ),
        ),
      ),
    );
  }

  // --- SUMMARY BOX (Kirim / Chiqim) ---
  Widget _buildSummaryBox({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERACTIVE KIRIM-CHIQIM BAR CHART CARD ---
  Widget _buildKirimChiqimBarChartCard({
    required List<String> labels,
    required List<double> kirimData,
    required List<double> chiqimData,
    required int activeIdx,
    required String activeLabel,
    required double activeKirim,
    required double activeChiqim,
    required double activeSof,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final db = DatabaseService();
    double maxVal = 1;
    for (var k in kirimData) {
      if (k > maxVal) maxVal = k;
    }
    for (var c in chiqimData) {
      if (c > maxVal) maxVal = c;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : AppTheme.neonGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Indicator: Selected Date / Amount (Overflow proof)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$activeLabel kungi tahlil",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            "${activeSof >= 0 ? '+' : ''}${NumberFormatter.format(db.convertFromUzs(activeSof, db.displayCurrency))}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: activeSof >= 0 ? AppTheme.neonGreen : AppTheme.danger,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${db.displayCurrency} sof",
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compact Stacked Legend (Kirim = Green, Chiqim = Red)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildLegendDot(AppTheme.neonGreen, "↑ Kirim"),
                  const SizedBox(height: 4),
                  _buildLegendDot(AppTheme.danger, "↓ Chiqim"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Double Bar Chart Columns
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(labels.length, (i) {
                final isSelected = activeIdx == i;
                final kHeight = maxVal > 0 ? (kirimData[i] / maxVal).clamp(0.1, 1.0) : 0.1;
                final cHeight = maxVal > 0 ? (chiqimData[i] / maxVal).clamp(0.1, 1.0) : 0.1;

                return GestureDetector(
                  onTap: () => setState(() => _selectedChartIndex = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Kirim Bar (Green)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            width: isSelected ? 14 : 10,
                            height: 110 * kHeight,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.neonGreen : AppTheme.neonGreen.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.neonGreen.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 3),
                          // Chiqim Bar (Rose/Red)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            width: isSelected ? 14 : 10,
                            height: 110 * cHeight,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.danger : AppTheme.danger.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.danger.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? AppTheme.neonGreen : textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Detail Row for the selected segment (Fully protected with Expanded & FittedBox)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132324) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 14, color: AppTheme.neonGreen),
                        const SizedBox(width: 4),
                        Text(
                          "Kirim: ${NumberFormatter.format(db.convertFromUzs(activeKirim, db.displayCurrency))} ${db.displayCurrency}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.neonGreen),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.arrow_downward_rounded, size: 14, color: AppTheme.danger),
                        const SizedBox(width: 4),
                        Text(
                          "Chiqim: ${NumberFormatter.format(db.convertFromUzs(activeChiqim, db.displayCurrency))} ${db.displayCurrency}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // --- PERFORMANCE TRENDS CARD ---
  Widget _buildPerformanceTrendsCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t('cashflowTrends'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(AppTheme.neonGreen, "↑ Kirim"),
                  const SizedBox(width: 8),
                  _buildLegendDot(AppTheme.danger, "↓ Chiqim"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _EmeraldKirimChiqimSplinePainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: textPrimary),
        ),
      ),
    );
  }
}

// --- EMERALD & DANGER SPLINE WAVE PAINTER ---
class _EmeraldKirimChiqimSplinePainter extends CustomPainter {
  final bool isDark;
  _EmeraldKirimChiqimSplinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid baseline
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), gridPaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), gridPaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), gridPaint);

    // Wave 1: Kirim Spline (Emerald Neon)
    final path1 = Path()
      ..moveTo(0, h * 0.8)
      ..cubicTo(w * 0.2, h * 0.5, w * 0.4, h * 0.65, w * 0.55, h * 0.3)
      ..cubicTo(w * 0.7, h * 0.15, w * 0.85, h * 0.4, w, h * 0.2);

    final paint1 = Paint()
      ..color = const Color(0xFF00E599)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawShadow(path1, const Color(0xFF00E599).withOpacity(0.5), 6, false);
    canvas.drawPath(path1, paint1);

    // Wave 2: Chiqim Spline (Rose / Coral)
    final path2 = Path()
      ..moveTo(0, h * 0.6)
      ..cubicTo(w * 0.25, h * 0.75, w * 0.45, h * 0.45, w * 0.6, h * 0.6)
      ..cubicTo(w * 0.75, h * 0.7, w * 0.88, h * 0.35, w, h * 0.5);

    final paint2 = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
