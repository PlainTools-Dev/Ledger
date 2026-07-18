import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/ledger_app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../logic/budget_calculations.dart';
import '../models/enums.dart';

class HistoryScreen extends StatelessWidget {
  final VoidCallback onBack;
  const HistoryScreen({super.key, required this.onBack});

  String _money(double v) {
    final sign = v < 0 ? '-' : '';
    return '$sign\$${v.abs().toStringAsFixed(2)}';
  }

  String _shortMonth(String monthKey) {
    final month = int.parse(monthKey.substring(5, 7));
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<LedgerAppState>();
    final allKeys = app.allMonthKeysAscending;

    return Scaffold(
      backgroundColor: LedgerColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton(onPressed: onBack, child: const Text('< Back')),
                  const SizedBox(width: 8),
                  Text('History', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              if (allKeys.isEmpty)
                GlassCard(
                  child: Text(
                    'No history yet. Log across a month or two and your trends appear here.',
                    style: TextStyle(color: LedgerColors.muted),
                  ),
                )
              else ...[
                _buildIncomeVsExpenses(app, allKeys),
                const SizedBox(height: 16),
                _buildSavingsRate(app, allKeys),
                const SizedBox(height: 16),
                _buildCategoryTrends(app),
                const SizedBox(height: 16),
                _buildMonthByMonth(app),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpenses(LedgerAppState app, List<String> allKeys) {
    final recent = allKeys.length > 9 ? allKeys.sublist(allKeys.length - 9) : allKeys;
    final income = app.storage.getIncome();
    final points = recent.map((key) {
      final tx = app.storage.getTransactionsForMonth(key);
      final totals = BudgetCalculations.bucketTotals(tx);
      final expenses = (totals[BudgetBucket.needs] ?? 0) + (totals[BudgetBucket.wants] ?? 0);
      return (label: _shortMonth(key), income: income[key] ?? 0.0, expenses: expenses);
    }).toList();

    final maxY = points
        .map((p) => p.income > p.expenses ? p.income : p.expenses)
        .fold(0.0, (a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Income vs expenses', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 4),
          Text(
            'Connected month-to-month trend. The y-axis starts at \$0 so changes stay honest.',
            style: TextStyle(fontSize: 11, color: LedgerColors.faint),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: maxY * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(points[idx].label, style: TextStyle(fontSize: 9, color: LedgerColors.muted)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.income)).toList(),
                  color: LedgerColors.accent,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  isCurved: false,
                ),
                LineChartBarData(
                  spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.expenses)).toList(),
                  color: LedgerColors.over,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  isCurved: false,
                ),
              ],
            )),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(LedgerColors.accent, 'Income'),
              const SizedBox(width: 16),
              _legendDot(LedgerColors.over, 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRate(LedgerAppState app, List<String> allKeys) {
    final recent = allKeys.length > 9 ? allKeys.sublist(allKeys.length - 9) : allKeys;
    final income = app.storage.getIncome();
    final points = recent.map((key) {
      final tx = app.storage.getTransactionsForMonth(key);
      final totals = BudgetCalculations.bucketTotals(tx);
      final inc = income[key] ?? 0.0;
      final savingsPct = inc > 0 ? (totals[BudgetBucket.savings] ?? 0) / inc * 100 : 0.0;
      return (label: _shortMonth(key), pct: savingsPct);
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Savings rate', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(points[idx].label, style: TextStyle(fontSize: 9, color: LedgerColors.muted)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: points.asMap().entries.map((entry) {
                return BarChartGroupData(x: entry.key, barRods: [
                  BarChartRodData(toY: entry.value.pct, color: LedgerColors.savings, width: 20, borderRadius: BorderRadius.circular(4)),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTrends(LedgerAppState app) {
    final rows = app.categoryTrendsData;
    if (rows.isEmpty) return const SizedBox.shrink();
    final monthLabels = rows.first.months.map(_shortMonth).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category trends', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          Table(
            columnWidths: const {0: FlexColumnWidth(2)},
            children: [
              TableRow(children: [
                _tableHeader('Category'),
                ...monthLabels.map((m) => _tableHeader(m, alignEnd: true)),
                _tableHeader('Trend', alignEnd: true),
              ]),
              ...rows.map((row) => TableRow(children: [
                    _tableCell(row.category),
                    ...row.values.map((v) => _tableCell(_money(v), alignEnd: true)),
                    _trendCell(row.trend),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthByMonth(LedgerAppState app) {
    final summaries = app.monthlyHistorySummaries.reversed.toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Month by month', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          Table(
            children: [
              TableRow(children: [
                _tableHeader('Month'),
                _tableHeader('Income', alignEnd: true),
                _tableHeader('Expenses', alignEnd: true),
                _tableHeader('Saved%', alignEnd: true),
                _tableHeader('Net', alignEnd: true),
              ]),
              ...summaries.map((s) => TableRow(children: [
                    _tableCell(_shortMonth(s.monthKey)),
                    _tableCell(_money(s.income), alignEnd: true),
                    _tableCell(_money(s.expenses), alignEnd: true),
                    _tableCell(s.income > 0 ? '${s.savingsPct.toStringAsFixed(0)}%' : '-', alignEnd: true),
                    _netCell(s),
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(fontSize: 11, color: LedgerColors.muted, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _tableCell(String text, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: LedgerTheme.numberStyle.copyWith(fontSize: 12, color: LedgerColors.text),
      ),
    );
  }

  Widget _netCell(MonthSummary s) {
    final color = s.net >= 0 ? LedgerColors.savings : LedgerColors.over;
    final arrow = s.trend == MonthTrend.up ? ' \u25B2' : s.trend == MonthTrend.down ? ' \u25BC' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        '${_money(s.net)}$arrow',
        textAlign: TextAlign.right,
        style: LedgerTheme.numberStyle.copyWith(fontSize: 12, color: color),
      ),
    );
  }

  Widget _trendCell(MonthTrend trend) {
    String text;
    Color color;
    switch (trend) {
      case MonthTrend.up:
        text = '\u25B2 up';
        color = LedgerColors.over;
        break;
      case MonthTrend.down:
        text = '\u25BC down';
        color = LedgerColors.savings;
        break;
      case MonthTrend.flat:
        text = '-';
        color = LedgerColors.faint;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(text, textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: LedgerColors.muted)),
      ],
    );
  }
}
