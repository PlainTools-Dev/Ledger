// data/hive_ledger_storage.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/recurring_bill.dart';
import '../models/budget_plan.dart';

/// Persists the full Ledger state locally via Hive. Structure mirrors
/// the PWA's `state` object as closely as possible so the data model
/// stays a faithful port, not a reinterpretation:
///
///   plan              -> BudgetPlan
///   income            -> Map<monthKey, double>
///   transactions      -> List<LedgerTransaction>
///   recurring         -> List<RecurringBill>
///   appliedRecurring  -> Map<monthKey, Map<billId, bool>>
///   placeMemory       -> Map<placeLowercase, categoryName>
///   notes             -> Map<monthKey, String>
class HiveLedgerStorage {
  static const String _boxName = 'ledger_state_v1';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // === Plan ===
  BudgetPlan getPlan() {
    final raw = _box.get('plan');
    if (raw == null) return const BudgetPlan(); // 50/30/20 default, matches PWA
    return BudgetPlan.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> savePlan(BudgetPlan plan) async {
    await _box.put('plan', plan.toMap());
  }

  // === Income (per month) ===
  Map<String, double> getIncome() {
    final raw = _box.get('income', defaultValue: <String, dynamic>{});
    return Map<String, dynamic>.from(raw).map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> setIncomeForMonth(String monthKey, double amount) async {
    final income = getIncome();
    income[monthKey] = amount;
    await _box.put('income', income);
  }

  /// Applies the same income to [monthsForward] months before [monthKey],
  /// matching the PWA's "Applies the same income to that many months
  /// before the selected one" feature.
  Future<void> setIncomeForwardFill(String monthKey, double amount, int monthsForward) async {
    final income = getIncome();
    income[monthKey] = amount;
    var year = int.parse(monthKey.substring(0, 4));
    var month = int.parse(monthKey.substring(5, 7));
    for (var i = 0; i < monthsForward; i++) {
      month -= 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
      final key = '$year-${month.toString().padLeft(2, '0')}';
      income[key] = amount;
    }
    await _box.put('income', income);
  }

  // === Transactions ===
  List<LedgerTransaction> getAllTransactions() {
    final raw = _box.get('transactions', defaultValue: <dynamic>[]) as List;
    return raw.map((m) => LedgerTransaction.fromMap(Map<dynamic, dynamic>.from(m))).toList();
  }

  List<LedgerTransaction> getTransactionsForMonth(String monthKey) {
    return getAllTransactions().where((t) => t.monthKey == monthKey).toList();
  }

  Future<void> addTransaction(LedgerTransaction tx) async {
    final all = getAllTransactions()..add(tx);
    await _box.put('transactions', all.map((t) => t.toMap()).toList());
    // Update place memory, matching JS: state.placeMemory[place.toLowerCase()] = category
    await _rememberPlace(tx.place, tx.category);
  }

  Future<void> updateTransaction(LedgerTransaction updated) async {
    final all = getAllTransactions();
    final idx = all.indexWhere((t) => t.id == updated.id);
    if (idx >= 0) all[idx] = updated;
    await _box.put('transactions', all.map((t) => t.toMap()).toList());
  }

  Future<void> deleteTransaction(String id) async {
    final all = getAllTransactions()..removeWhere((t) => t.id == id);
    await _box.put('transactions', all.map((t) => t.toMap()).toList());
  }

  // === Recurring bills ===
  List<RecurringBill> getRecurring() {
    final raw = _box.get('recurring', defaultValue: <dynamic>[]) as List;
    return raw.map((m) => RecurringBill.fromMap(Map<dynamic, dynamic>.from(m))).toList();
  }

  Future<void> saveRecurring(RecurringBill bill) async {
    final all = getRecurring();
    final idx = all.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) {
      all[idx] = bill;
    } else {
      all.add(bill);
    }
    await _box.put('recurring', all.map((b) => b.toMap()).toList());
  }

  Future<void> deleteRecurring(String id) async {
    final all = getRecurring()..removeWhere((b) => b.id == id);
    await _box.put('recurring', all.map((b) => b.toMap()).toList());
  }

  // === Applied recurring tracking (which bills already posted this month) ===
  Map<String, Set<String>> getAppliedRecurring() {
    final raw = _box.get('appliedRecurring', defaultValue: <String, dynamic>{});
    return Map<String, dynamic>.from(raw).map(
      (monthKey, billMap) => MapEntry(monthKey, Set<String>.from(Map<String, dynamic>.from(billMap).keys)),
    );
  }

  Future<void> markRecurringApplied(String monthKey, String billId) async {
    final raw = Map<String, dynamic>.from(_box.get('appliedRecurring', defaultValue: <String, dynamic>{}));
    final monthMap = Map<String, dynamic>.from(raw[monthKey] ?? {});
    monthMap[billId] = true;
    raw[monthKey] = monthMap;
    await _box.put('appliedRecurring', raw);
  }

  // === Place memory (autosuggest category from place name) ===
  Future<void> _rememberPlace(String place, String category) async {
    final raw = Map<String, dynamic>.from(_box.get('placeMemory', defaultValue: <String, dynamic>{}));
    raw[place.toLowerCase()] = category;
    await _box.put('placeMemory', raw);
  }

  String? suggestedCategoryFor(String place) {
    final raw = Map<String, dynamic>.from(_box.get('placeMemory', defaultValue: <String, dynamic>{}));
    return raw[place.toLowerCase()] as String?;
  }

  // === Notes (free text per month) ===
  String getNote(String monthKey) {
    final raw = Map<String, dynamic>.from(_box.get('notes', defaultValue: <String, dynamic>{}));
    return raw[monthKey] as String? ?? '';
  }

  Future<void> saveNote(String monthKey, String text) async {
    final raw = Map<String, dynamic>.from(_box.get('notes', defaultValue: <String, dynamic>{}));
    raw[monthKey] = text;
    await _box.put('notes', raw);
  }

  // === Currency (display-only unit label, not a converter — deliberate
  // product decision carried over from the PWA) ===
  String getCurrencySymbol() => _box.get('currencySymbol', defaultValue: '\$') as String;

  Future<void> setCurrencySymbol(String symbol) async {
    await _box.put('currencySymbol', symbol);
  }
}
