// logic/budget_calculations.dart
import '../models/transaction.dart';
import '../models/recurring_bill.dart';
import '../models/budget_plan.dart';
import '../models/enums.dart';
import '../models/category.dart';
import 'month_utils.dart';

/// Direct ports of the PWA's calculation functions. Kept as pure
/// functions (no state/storage dependency) so they're testable in
/// isolation and match the original's separation of calculation from
/// rendering.
class BudgetCalculations {
  /// Sums transactions into needs/wants/savings totals for one month.
  /// Port of JS `bucketTotals(k)`.
  static Map<BudgetBucket, double> bucketTotals(List<LedgerTransaction> monthTransactions) {
    final totals = {
      BudgetBucket.needs: 0.0,
      BudgetBucket.wants: 0.0,
      BudgetBucket.savings: 0.0,
    };
    for (final t in monthTransactions) {
      final bucket = bucketOf[t.category] ?? BudgetBucket.wants; // JS default fallback
      totals[bucket] = (totals[bucket] ?? 0) + t.amount;
    }
    return totals;
  }

  /// Sum of recurring bills not yet posted this month.
  /// Port of JS `unpaidBillsTotal(k)`.
  static double unpaidBillsTotal(
    List<RecurringBill> recurring,
    Set<String> appliedBillIdsThisMonth,
  ) {
    return recurring.fold(0.0, (sum, bill) {
      final alreadyApplied = appliedBillIdsThisMonth.contains(bill.id);
      return sum + (alreadyApplied ? 0 : bill.amount);
    });
  }

  /// "Safe to spend" — income minus what's already spent minus the
  /// remaining savings goal minus upcoming bills. Port of JS `safeToSpend(k)`.
  static SafeToSpendResult safeToSpend({
    required double income,
    required List<LedgerTransaction> monthTransactions,
    required BudgetPlan plan,
    required List<RecurringBill> recurring,
    required Set<String> appliedBillIdsThisMonth,
  }) {
    final totals = bucketTotals(monthTransactions);
    final expenses = (totals[BudgetBucket.needs] ?? 0) + (totals[BudgetBucket.wants] ?? 0);
    final savingsSoFar = totals[BudgetBucket.savings] ?? 0;
    final remainingSavings = (income * plan.savingsPct / 100 - savingsSoFar).clamp(0, double.infinity);
    final upcoming = unpaidBillsTotal(recurring, appliedBillIdsThisMonth);
    final safe = income - expenses - remainingSavings - upcoming;
    return SafeToSpendResult(
      income: income,
      expenses: expenses,
      remainingSavings: remainingSavings.toDouble(),
      upcoming: upcoming,
      safe: safe,
    );
  }

  /// Spending velocity/pace-of-month check. Port of JS `velocityBlock`
  /// logic (the message-generation part, separated from rendering).
  /// Only meaningful for the current month, matching the original's
  /// `if(k!==monthKey(new Date())) return ""` guard — caller decides
  /// whether to show this at all.
  static VelocityResult velocity({
    required DateTime now,
    required double income,
    required double spent,
    required BudgetPlan plan,
  }) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final day = now.day;
    final elapsedFraction = (day / daysInMonth).clamp(0, 1).toDouble();
    final budget = income * (plan.needsPct + plan.wantsPct) / 100;
    final expected = budget * elapsedFraction;

    VelocityPace pace;
    if (spent > expected * 1.05) {
      pace = VelocityPace.ahead;
    } else if (spent < expected * 0.95) {
      pace = VelocityPace.under;
    } else {
      pace = VelocityPace.onPace;
    }

    return VelocityResult(
      day: day,
      daysInMonth: daysInMonth,
      budget: budget,
      expected: expected,
      spent: spent,
      pace: pace,
    );
  }

  /// Generates the coaching "nudge" text per bucket. Direct port of
  /// JS `nudge(b,aPct,tPct,income)` — kept as data (NudgeResult) rather
  /// than pre-formatted text, so the UI layer controls exact phrasing/
  /// formatting instead of parsing HTML strings like the original did.
  static NudgeResult nudge({
    required BudgetBucket bucket,
    required double actualPct,
    required double targetPct,
    required double income,
  }) {
    final diff = actualPct - targetPct;
    final dollars = (diff.abs() / 100 * income);

    if (bucket == BudgetBucket.savings) {
      if (diff >= -1) {
        return NudgeResult(tone: NudgeTone.good, dollarsGap: 0, isAboveGoal: true);
      }
      return NudgeResult(tone: NudgeTone.encourage, dollarsGap: dollars, isAboveGoal: false);
    }

    if (diff <= 1) return NudgeResult(tone: NudgeTone.good, dollarsGap: 0, isAboveGoal: false);
    if (diff <= 5) return NudgeResult(tone: NudgeTone.caution, dollarsGap: dollars, isAboveGoal: false);
    return NudgeResult(tone: NudgeTone.warning, dollarsGap: dollars, isAboveGoal: false);
  }
  /// Bills due within [limitDays] days, across up to 3 months ahead.
  /// Port of JS `upcomingBills(limitDays)`.
  static List<UpcomingBill> upcomingBills({
    required List<RecurringBill> recurring,
    required int limitDays,
    required DateTime today,
  }) {
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: limitDays));
    final results = <UpcomingBill>[];

    for (final bill in recurring) {
      final startMonthKey = '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}';
      for (var i = 0; i < 3; i++) {
        final mk = MonthUtils.shift(startMonthKey, i);
        final iso = MonthUtils.billDateFor(mk, bill.day);
        final parts = iso.split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (!d.isBefore(start) && !d.isAfter(end)) {
          results.add(UpcomingBill(bill: bill, date: iso));
        }
      }
    }

    results.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.bill.name.compareTo(b.bill.name);
    });
    return results;
  }
  /// Category breakdown for the month, excluding savings (matches JS
  /// `categoryChart`, which filters out the savings bucket since this
  /// chart is about discretionary/needed spending, not saving).
  /// Collapses everything past the top 6 into "Other", same as original.
  static List<CategoryAmount> categoryBreakdown(List<LedgerTransaction> monthTransactions) {
    final spendOnly = monthTransactions.where((t) => (bucketOf[t.category] ?? BudgetBucket.wants) != BudgetBucket.savings);
    final byCategory = <String, double>{};
    for (final t in spendOnly) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    var items = byCategory.entries.map((e) => CategoryAmount(e.key, e.value)).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (items.length > 6) {
      final top = items.take(6).toList();
      final otherTotal = items.skip(6).fold(0.0, (sum, i) => sum + i.amount);
      top.add(CategoryAmount('Other', otherTotal));
      items = top;
    }
    return items;
  }

  /// Top 5 spending places for the month, excluding savings.
  /// Port of JS `topPlacesChart`.
  static List<PlaceAmount> topPlaces(List<LedgerTransaction> monthTransactions) {
    final spendOnly = monthTransactions.where((t) => (bucketOf[t.category] ?? BudgetBucket.wants) != BudgetBucket.savings);
    final byPlace = <String, double>{};
    final bucketByPlace = <String, BudgetBucket>{};
    for (final t in spendOnly) {
      byPlace[t.place] = (byPlace[t.place] ?? 0) + t.amount;
      bucketByPlace[t.place] = bucketOf[t.category] ?? BudgetBucket.wants;
    }
    final items = byPlace.entries
        .map((e) => PlaceAmount(e.key, e.value, bucketByPlace[e.key]!))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return items.take(5).toList();
  }
}

class CategoryAmount {
  final String category;
  final double amount;
  const CategoryAmount(this.category, this.amount);
}

class PlaceAmount {
  final String place;
  final double amount;
  final BudgetBucket bucket;
  const PlaceAmount(this.place, this.amount, this.bucket);
}

class UpcomingBill {
  final RecurringBill bill;
  final String date;
  const UpcomingBill({required this.bill, required this.date});
}

class SafeToSpendResult {
  final double income;
  final double expenses;
  final double remainingSavings;
  final double upcoming;
  final double safe;
  const SafeToSpendResult({
    required this.income,
    required this.expenses,
    required this.remainingSavings,
    required this.upcoming,
    required this.safe,
  });
}

enum VelocityPace { ahead, under, onPace }

class VelocityResult {
  final int day;
  final int daysInMonth;
  final double budget;
  final double expected;
  final double spent;
  final VelocityPace pace;
  const VelocityResult({
    required this.day,
    required this.daysInMonth,
    required this.budget,
    required this.expected,
    required this.spent,
    required this.pace,
  });
}

enum NudgeTone { good, encourage, caution, warning }

class NudgeResult {
  final NudgeTone tone;
  final double dollarsGap;
  final bool isAboveGoal;
  const NudgeResult({required this.tone, required this.dollarsGap, required this.isAboveGoal});
}
