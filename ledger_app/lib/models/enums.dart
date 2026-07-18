/// The three budget buckets — ported directly from the PWA's
/// `BUCKETS = ["needs","wants","savings"]` constant.
enum BudgetBucket { needs, wants, savings }

extension BudgetBucketX on BudgetBucket {
  String get label {
    switch (this) {
      case BudgetBucket.needs:
        return 'Needs';
      case BudgetBucket.wants:
        return 'Wants';
      case BudgetBucket.savings:
        return 'Savings';
    }
  }
}
