import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/ledger_app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/budget_progress_bar.dart';
import '../models/enums.dart';
import '../logic/budget_calculations.dart';
import '../logic/month_utils.dart';

class GaugeScreen extends StatefulWidget {
  final VoidCallback onBack;
  const GaugeScreen({super.key, required this.onBack});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final app = context.read<LedgerAppState>();
    _noteController = TextEditingController(text: app.storage.getNote(app.viewMonth));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _money(double v) {
    final sign = v < 0 ? '-' : '';
    return '$sign\$${v.abs().toStringAsFixed(2)}';
  }

  String _nudgeText(BudgetBucket bucket, double actualPct, double targetPct, double income) {
    final result = BudgetCalculations.nudge(
      bucket: bucket,
      actualPct: actualPct,
      targetPct: targetPct,
      income: income,
    );
    final label = bucket.label;

    if (bucket == BudgetBucket.savings) {
      if (result.tone == NudgeTone.good) {
        return 'Nice. You\'re saving ${actualPct.toStringAsFixed(0)}% - at or above your ${targetPct.toStringAsFixed(0)}% goal.';
      }
      return 'You\'re saving ${actualPct.toStringAsFixed(0)}% (goal ${targetPct.toStringAsFixed(0)}%). Setting aside about ${_money(result.dollarsGap)} more this month closes the gap.';
    }

    switch (result.tone) {
      case NudgeTone.good:
        return 'Comfortable. $label is at ${actualPct.toStringAsFixed(0)}%, within your ${targetPct.toStringAsFixed(0)}% plan.';
      case NudgeTone.caution:
        return '$label is running a touch high at ${actualPct.toStringAsFixed(0)}% (plan ${targetPct.toStringAsFixed(0)}%). Trimming roughly ${_money(result.dollarsGap)} brings it in line.';
      case NudgeTone.warning:
        return '$label is your biggest stretch right now - ${actualPct.toStringAsFixed(0)}% vs a ${targetPct.toStringAsFixed(0)}% plan.';
      case NudgeTone.encourage:
        return '$label needs attention.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<LedgerAppState>();
    final income = app.incomeThisMonth;

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
                  TextButton(onPressed: widget.onBack, child: const Text('< Back')),
                  const SizedBox(width: 8),
                  Text("How you're doing", style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              if (income <= 0)
                GlassCard(
                  child: Text(
                    'Set your income for ${MonthUtils.label(app.viewMonth)} in Your plan to see how your spending compares.',
                    style: TextStyle(color: LedgerColors.muted),
                  ),
                )
              else ...[
                _buildBudgetUtilization(app),
                const SizedBox(height: 16),
                _buildVelocity(app),
                const SizedBox(height: 16),
                _buildSplitVsPlan(app),
                const SizedBox(height: 16),
                _buildCategoryBreakdown(app),
                const SizedBox(height: 16),
                _buildTopPlaces(app),
                const SizedBox(height: 16),
                _buildNotes(app),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetUtilization(LedgerAppState app) {
    final income = app.incomeThisMonth;
    final totals = app.bucketTotalsThisMonth;
    final spent = (totals['needs'] ?? 0) + (totals['wants'] ?? 0);
    final saved = totals['savings'] ?? 0;
    final usedPct = income > 0 ? (spent / income * 100).clamp(0, 100) : 0.0;
    final left = income - spent - saved;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget utilization', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 42,
                      sections: [
                        PieChartSectionData(value: usedPct.toDouble(), color: LedgerColors.accent, showTitle: false, radius: 18),
                        PieChartSectionData(value: (100 - usedPct).toDouble(), color: LedgerColors.surface2, showTitle: false, radius: 18),
                      ],
                    )),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${usedPct.round()}%', style: LedgerTheme.numberStyle.copyWith(fontSize: 20, color: LedgerColors.text)),
                        Text('of income used', style: TextStyle(fontSize: 9, color: LedgerColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kvRow('Income', _money(income)),
                    _kvRow('Spent', _money(spent)),
                    _kvRow('Saved', _money(saved)),
                    _kvRow('Left', _money(left), color: left >= 0 ? LedgerColors.savings : LedgerColors.over),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocity(LedgerAppState app) {
    final isCurrentMonth = app.viewMonth == MonthUtils.keyFor(DateTime.now());
    if (!isCurrentMonth) return const SizedBox.shrink();

    final income = app.incomeThisMonth;
    final totals = app.bucketTotalsThisMonth;
    final spent = (totals['needs'] ?? 0) + (totals['wants'] ?? 0);
    final result = BudgetCalculations.velocity(now: DateTime.now(), income: income, spent: spent, plan: app.plan);
    if (result.budget <= 0) return const SizedBox.shrink();

    String msg;
    switch (result.pace) {
      case VelocityPace.ahead:
        msg = 'Spending a little ahead of pace - easing off keeps you on plan.';
        break;
      case VelocityPace.under:
        msg = 'Comfortably under pace for the month.';
        break;
      case VelocityPace.onPace:
        msg = 'Right on pace.';
        break;
    }

    final fillPct = result.budget > 0 ? (result.spent / result.budget * 100).clamp(0, 100) : 0.0;
    final targetPct = result.budget > 0 ? (result.expected / result.budget * 100).clamp(0, 100) : 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending velocity', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
              Text('Day ${result.day} of ${result.daysInMonth}', style: LedgerTheme.numberStyle.copyWith(fontSize: 12, color: LedgerColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(msg, style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
          const SizedBox(height: 12),
          BudgetProgressBar(
            fillPercent: fillPct.toDouble(),
            targetPercent: targetPct.toDouble(),
            fillColor: result.pace == VelocityPace.ahead ? LedgerColors.over : LedgerColors.accent,
          ),
          const SizedBox(height: 10),
          _kvRow('Expected by now', _money(result.expected)),
          _kvRow('Actual so far', _money(result.spent)),
          _kvRow('Month budget', _money(result.budget)),
        ],
      ),
    );
  }

  Widget _buildSplitVsPlan(LedgerAppState app) {
    final income = app.incomeThisMonth;
    final totals = app.bucketTotalsThisMonth;
    final plan = app.plan;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your split vs plan', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          for (final bucket in BudgetBucket.values) ...[
            _buildBucketRow(bucket, totals[bucket.name] ?? 0, income, plan),
            if (bucket != BudgetBucket.values.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildBucketRow(BudgetBucket bucket, double actual, double income, dynamic plan) {
    final actualPct = income > 0 ? (actual / income * 100) : 0.0;
    final targetPct = bucket == BudgetBucket.needs
        ? plan.needsPct
        : bucket == BudgetBucket.wants
            ? plan.wantsPct
            : plan.savingsPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(bucket.label, style: TextStyle(fontSize: 13, color: LedgerColors.text)),
            Text(
              '${_money(actual)} - ${actualPct.toStringAsFixed(0)}% / ${targetPct.toStringAsFixed(0)}%',
              style: LedgerTheme.numberStyle.copyWith(fontSize: 12, color: LedgerColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        BudgetProgressBar(fillPercent: actualPct, targetPercent: targetPct, fillColor: bucket.color),
        const SizedBox(height: 6),
        Text(_nudgeText(bucket, actualPct, targetPct, income), style: TextStyle(fontSize: 11, color: LedgerColors.faint)),
      ],
    );
  }

  Widget _buildCategoryBreakdown(LedgerAppState app) {
    final items = app.categoryBreakdownThisMonth;
    if (items.isEmpty) return const SizedBox.shrink();
    final total = items.fold(0.0, (sum, i) => sum + i.amount);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by category', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      sectionsSpace: 1,
                      centerSpaceRadius: 42,
                      sections: items
                          .map((it) => PieChartSectionData(
                                value: it.amount,
                                color: CategoryColors.forCategory(it.category),
                                showTitle: false,
                                radius: 18,
                              ))
                          .toList(),
                    )),
                    Text(_money(total), style: LedgerTheme.numberStyle.copyWith(fontSize: 15, color: LedgerColors.text)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: CategoryColors.forCategory(it.category), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Expanded(child: Text(it.category, style: TextStyle(fontSize: 11, color: LedgerColors.text), overflow: TextOverflow.ellipsis)),
                                Text(_money(it.amount), style: LedgerTheme.numberStyle.copyWith(fontSize: 11, color: LedgerColors.muted)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlaces(LedgerAppState app) {
    final items = app.topPlacesThisMonth;
    if (items.isEmpty) return const SizedBox.shrink();
    final maxVal = items.map((i) => i.amount).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top spending', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
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
                      if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                      final name = items[idx].place;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          name.length > 8 ? '${name.substring(0, 7)}...' : name,
                          style: TextStyle(fontSize: 9, color: LedgerColors.muted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: item.amount, color: item.bucket.color, width: 28, borderRadius: BorderRadius.circular(4)),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(LedgerAppState app) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes for ${MonthUtils.label(app.viewMonth)}', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Anything unusual this month? A car repair, a trip, a big one-off - jot it here.',
            ),
            onChanged: (v) => app.storage.saveNote(app.viewMonth, v),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
          Text(value, style: LedgerTheme.numberStyle.copyWith(fontSize: 12, color: color ?? LedgerColors.text)),
        ],
      ),
    );
  }
}
