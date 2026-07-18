import 'enums.dart';

/// A spending category with its budget bucket assignment.
class LedgerCategory {
  final String name;
  final BudgetBucket bucket;
  const LedgerCategory(this.name, this.bucket);
}

/// Exact port of the PWA's `CATS` array (index.html) — 17 categories
/// across the three buckets. Order preserved to match the original UI.
const List<LedgerCategory> categories = [
  LedgerCategory('Rent / Mortgage', BudgetBucket.needs),
  LedgerCategory('Groceries', BudgetBucket.needs),
  LedgerCategory('Utilities', BudgetBucket.needs),
  LedgerCategory('Transport', BudgetBucket.needs),
  LedgerCategory('Phone / Internet', BudgetBucket.needs),
  LedgerCategory('Healthcare', BudgetBucket.needs),
  LedgerCategory('Insurance', BudgetBucket.needs),
  LedgerCategory('Dining / Fast food', BudgetBucket.wants),
  LedgerCategory('Coffee', BudgetBucket.wants),
  LedgerCategory('Entertainment', BudgetBucket.wants),
  LedgerCategory('Shopping', BudgetBucket.wants),
  LedgerCategory('Subscriptions', BudgetBucket.wants),
  LedgerCategory('Travel', BudgetBucket.wants),
  LedgerCategory('Savings', BudgetBucket.savings),
  LedgerCategory('Investments', BudgetBucket.savings),
  LedgerCategory('Debt payment', BudgetBucket.savings),
  LedgerCategory('Emergency fund', BudgetBucket.savings),
];

/// Fast lookup matching the JS `BUCKET_OF` object — category name to bucket.
final Map<String, BudgetBucket> bucketOf = {
  for (final c in categories) c.name: c.bucket,
};
