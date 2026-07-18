import 'package:flutter/foundation.dart';
import '../data/hive_ledger_storage.dart';
import '../models/transaction.dart';
import '../models/recurring_bill.dart';
import '../models/budget_plan.dart';
import '../logic/budget_calculations.dart';
import '../logic/month_utils.dart';

class LedgerAppState extends ChangeNotifier {
  final HiveLedgerStorage storage;
  String viewMonth = MonthUtils.keyFor(DateTime.now());

  LedgerAppState(this.storage);

  Future<void> init() async {
    await storage.init();
    notifyListeners();
  }

  void shiftMonth(int delta) {
    viewMonth = MonthUtils.shift(viewMonth, delta);
    notifyListeners();
  }

  double get incomeThisMonth => storage.getIncome()[viewMonth] ?? 0;
  List<LedgerTransaction> get transactionsThisMonth => storage.getTransactionsForMonth(viewMonth);
  BudgetPlan get plan => storage.getPlan();

  Map<String, double> get bucketTotalsThisMonth {
    final totals = BudgetCalculations.bucketTotals(transactionsThisMonth);
    return totals.map((k, v) => MapEntry(k.name, v));
  }

  SafeToSpendResult get safeToSpendThisMonth {
    final applied = storage.getAppliedRecurring()[viewMonth] ?? {};
    return BudgetCalculations.safeToSpend(
      income: incomeThisMonth,
      monthTransactions: transactionsThisMonth,
      plan: plan,
      recurring: storage.getRecurring(),
      appliedBillIdsThisMonth: applied,
    );
  }

  List<UpcomingBill> get upcomingBills30Days => BudgetCalculations.upcomingBills(
        recurring: storage.getRecurring(),
        limitDays: 30,
        today: DateTime.now(),
      );

  List<CategoryAmount> get categoryBreakdownThisMonth =>
      BudgetCalculations.categoryBreakdown(transactionsThisMonth);

  List<PlaceAmount> get topPlacesThisMonth => BudgetCalculations.topPlaces(transactionsThisMonth);

  bool get hasAnyData => storage.getAllTransactions().isNotEmpty || storage.getRecurring().isNotEmpty;

  List<String> get allMonthKeysAscending {
    final keys = storage.getAllTransactions().map((t) => t.monthKey).toSet().toList();
    keys.sort();
    return keys;
  }

  List<MonthSummary> get monthlyHistorySummaries => BudgetCalculations.monthlySummaries(
        sortedMonthKeys: allMonthKeysAscending,
        incomeByMonth: storage.getIncome(),
        allTransactions: storage.getAllTransactions(),
      );

  List<CategoryTrend> get categoryTrendsData =>
      BudgetCalculations.categoryTrends(storage.getAllTransactions());

  Future<void> addTransaction(LedgerTransaction tx) async {
    await storage.addTransaction(tx);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await storage.deleteTransaction(id);
    notifyListeners();
  }

  Future<void> updateTransaction(LedgerTransaction tx) async {
    await storage.updateTransaction(tx);
    notifyListeners();
  }

  Future<void> saveIncome(double amount, {int forwardMonths = 0}) async {
    if (forwardMonths > 0) {
      await storage.setIncomeForwardFill(viewMonth, amount, forwardMonths);
    } else {
      await storage.setIncomeForMonth(viewMonth, amount);
    }
    notifyListeners();
  }

  Future<void> savePlan(BudgetPlan plan) async {
    await storage.savePlan(plan);
    notifyListeners();
  }

  Future<void> saveRecurring(RecurringBill bill) async {
    await storage.saveRecurring(bill);
    notifyListeners();
  }

  Future<void> deleteRecurring(String id) async {
    await storage.deleteRecurring(id);
    notifyListeners();
  }

  Future<void> applyRecurringBill(RecurringBill bill) async {
    final applied = storage.getAppliedRecurring()[viewMonth] ?? {};
    if (applied.contains(bill.id)) return;
    final date = MonthUtils.billDateFor(viewMonth, bill.day);
    await storage.addTransaction(LedgerTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      place: bill.name,
      amount: bill.amount,
      category: bill.category,
      recurringId: bill.id,
    ));
    await storage.markRecurringApplied(viewMonth, bill.id);
    notifyListeners();
  }
}
