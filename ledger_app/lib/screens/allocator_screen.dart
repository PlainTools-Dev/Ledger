import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/ledger_app_state.dart';
import '../theme/app_theme.dart';
import '../models/budget_plan.dart';
import '../logic/month_utils.dart';

class AllocatorScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AllocatorScreen({super.key, required this.onBack});

  @override
  State<AllocatorScreen> createState() => _AllocatorScreenState();
}

class _AllocatorScreenState extends State<AllocatorScreen> {
  late TextEditingController _incomeController;
  final _backfillController = TextEditingController();
  late double _needs;
  late double _wants;
  late double _savings;

  @override
  void initState() {
    super.initState();
    final app = context.read<LedgerAppState>();
    _incomeController = TextEditingController(
      text: app.incomeThisMonth > 0 ? app.incomeThisMonth.toStringAsFixed(2) : '',
    );
    final plan = app.plan;
    _needs = plan.needsPct;
    _wants = plan.wantsPct;
    _savings = plan.savingsPct;
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _backfillController.dispose();
    super.dispose();
  }

  double get _total => _needs + _wants + _savings;

  Future<void> _saveIncome() async {
    final app = context.read<LedgerAppState>();
    final amount = double.tryParse(_incomeController.text);
    if (amount == null || amount < 0) return;
    final backfill = int.tryParse(_backfillController.text) ?? 0;
    await app.saveIncome(amount, forwardMonths: backfill.clamp(0, 36));
  }

  Future<void> _savePlan() async {
    final app = context.read<LedgerAppState>();
    await app.savePlan(BudgetPlan(needsPct: _needs, wantsPct: _wants, savingsPct: _savings));
    await _saveIncome();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<LedgerAppState>();
    final isValid = (_total - 100).abs() < 0.01;

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
                TextButton(onPressed: widget.onBack, child: const Text('‹ Back')),
                const SizedBox(width: 8),
                Text('Your plan', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),

            Text('Income for ${MonthUtils.label(app.viewMonth)}',
                style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
            const SizedBox(height: 6),
            TextField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00', prefixText: '\$ '),
            ),
            const SizedBox(height: 14),

            Text('Copy this income to earlier months', style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
            const SizedBox(height: 6),
            TextField(
              controller: _backfillController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
            ),
            const SizedBox(height: 6),
            Text(
              "Optional. Applies the same income to that many months before the selected one — useful if your pay's been steady. Leave at 0 to set only the selected month.",
              style: TextStyle(fontSize: 11, color: LedgerColors.faint),
            ),
            const SizedBox(height: 24),

            Text('TARGET SPLIT', style: TextStyle(fontSize: 12, color: LedgerColors.muted, letterSpacing: 1)),
            const SizedBox(height: 12),

            _PercentSlider(
              label: 'Needs',
              value: _needs,
              color: LedgerColors.needs,
              onChanged: (v) => setState(() => _needs = v),
            ),
            _PercentSlider(
              label: 'Wants',
              value: _wants,
              color: LedgerColors.wants,
              onChanged: (v) => setState(() => _wants = v),
            ),
            _PercentSlider(
              label: 'Savings',
              value: _savings,
              color: LedgerColors.savings,
              onChanged: (v) => setState(() => _savings = v),
            ),

            const SizedBox(height: 12),
            Text(
              isValid
                  ? 'Adds up to 100%. Good to go.'
                  : 'Currently ${_total.toStringAsFixed(0)}% — should add up to 100%.',
              style: TextStyle(
                fontSize: 12,
                color: isValid ? LedgerColors.savings : LedgerColors.over,
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _savePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: LedgerColors.accent,
                foregroundColor: LedgerColors.bg,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save plan'),
            ),
            const SizedBox(height: 14),
            Text(
              'Percentages should add up to 100. The classic starting point is 50 needs / 30 wants / 20 savings — adjust to whatever fits your life.',
              style: TextStyle(fontSize: 11, color: LedgerColors.faint),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PercentSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _PercentSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label %', style: TextStyle(fontSize: 13, color: LedgerColors.text)),
              Text('${value.round()}', style: LedgerTheme.numberStyle.copyWith(fontSize: 13, color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: color, thumbColor: color),
            child: Slider(
              value: value.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
