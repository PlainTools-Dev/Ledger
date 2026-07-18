/// A single logged expense. Matches the PWA's transaction shape:
/// `{id, date, place, amount, category, recurringId?}`.
///
/// `date` is stored as an ISO date string (YYYY-MM-DD) to match the
/// original's `t.date.slice(0,7)` month-key pattern used throughout
/// the JS for grouping by month.
class LedgerTransaction {
  final String id;
  final String date; // YYYY-MM-DD
  final String place;
  final double amount;
  final String category;
  final String? recurringId; // set when auto-posted from a recurring bill

  const LedgerTransaction({
    required this.id,
    required this.date,
    required this.place,
    required this.amount,
    required this.category,
    this.recurringId,
  });

  /// The month key this transaction belongs to, e.g. "2026-07".
  /// Matches the JS pattern `t.date.slice(0,7)` used for grouping.
  String get monthKey => date.substring(0, 7);

  LedgerTransaction copyWith({
    String? date,
    String? place,
    double? amount,
    String? category,
  }) {
    return LedgerTransaction(
      id: id,
      date: date ?? this.date,
      place: place ?? this.place,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      recurringId: recurringId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'place': place,
        'amount': amount,
        'category': category,
        if (recurringId != null) 'recurringId': recurringId,
      };

  factory LedgerTransaction.fromMap(Map<dynamic, dynamic> m) => LedgerTransaction(
        id: m['id'] as String,
        date: m['date'] as String,
        place: m['place'] as String,
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] as String,
        recurringId: m['recurringId'] as String?,
      );
}
