/// The user's target needs/wants/savings split. Matches the PWA's
/// `plan:{needs:50,wants:30,savings:20}` default — the classic
/// 50/30/20 starting point, adjustable by the user.
class BudgetPlan {
  final double needsPct;
  final double wantsPct;
  final double savingsPct;

  const BudgetPlan({
    this.needsPct = 50,
    this.wantsPct = 30,
    this.savingsPct = 20,
  });

  /// Matches the JS validation note: "Percentages should add up to 100."
  /// Not enforced strictly here (the original didn't hard-block saving
  /// either) — exposed so the UI can warn, same as the original's
  /// `planMsg` nudge text.
  double get total => needsPct + wantsPct + savingsPct;
  bool get isValid => (total - 100).abs() < 0.01;

  Map<String, dynamic> toMap() => {
        'needs': needsPct,
        'wants': wantsPct,
        'savings': savingsPct,
      };

  factory BudgetPlan.fromMap(Map<dynamic, dynamic> m) => BudgetPlan(
        needsPct: (m['needs'] as num).toDouble(),
        wantsPct: (m['wants'] as num).toDouble(),
        savingsPct: (m['savings'] as num).toDouble(),
      );
}
