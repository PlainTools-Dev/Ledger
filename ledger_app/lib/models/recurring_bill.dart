/// A recurring monthly expense. Matches the PWA's recurring shape:
/// `{id, name, amount, day, category}`.
class RecurringBill {
  final String id;
  final String name;
  final double amount;
  final int day; // day of month (1-31) this bill posts on
  final String category;

  const RecurringBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.day,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'day': day,
        'category': category,
      };

  factory RecurringBill.fromMap(Map<dynamic, dynamic> m) => RecurringBill(
        id: m['id'] as String,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        day: m['day'] as int,
        category: m['category'] as String,
      );
}
