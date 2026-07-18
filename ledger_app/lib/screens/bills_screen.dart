import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/ledger_app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/category.dart';
import '../models/recurring_bill.dart';
import '../models/enums.dart';

class BillsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const BillsScreen({super.key, required this.onBack});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  Future<void> _saveBill() async {
    final app = context.read<LedgerAppState>();
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);
    final day = (int.tryParse(_dayController.text) ?? 1).clamp(1, 31);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name.')));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a category.')));
      return;
    }

    await app.saveRecurring(RecurringBill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: (amount * 100).round() / 100,
      day: day,
      category: _selectedCategory!,
    ));

    setState(() {
      _nameController.clear();
      _amountController.clear();
      _dayController.clear();
      _selectedCategory = null;
    });
  }

  Future<void> _addForThisMonth(RecurringBill bill) async {
    final app = context.read<LedgerAppState>();
    final applied = app.storage.getAppliedRecurring()[app.viewMonth] ?? {};
    final alreadyApplied = applied.contains(bill.id);
    await app.applyRecurringBill(bill);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(alreadyApplied ? 'Already added for this month.' : 'Added.')),
      );
    }
  }

  Future<void> _confirmDelete(RecurringBill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LedgerColors.surface,
        title: const Text('Delete this recurring expense?'),
        content: const Text('Existing transactions stay in history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: LedgerColors.over)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<LedgerAppState>().deleteRecurring(bill.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<LedgerAppState>();
    final upcoming = app.upcomingBills30Days;
    final allBills = app.storage.getRecurring()
      ..sort((a, b) {
        final dayCompare = a.day.compareTo(b.day);
        if (dayCompare != 0) return dayCompare;
        return a.name.compareTo(b.name);
      });

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
                  Text('Bills', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),

              // Upcoming bills box, matches renderBills' upcomingBox
              if (upcoming.isNotEmpty)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming bills · next 30 days',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LedgerColors.text)),
                      const SizedBox(height: 8),
                      ...upcoming.map((b) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${b.date} · ${b.bill.name}', style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
                                Text(_money(b.bill.amount), style: LedgerTheme.numberStyle.copyWith(fontSize: 12)),
                              ],
                            ),
                          )),
                    ],
                  ),
                )
              else
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No upcoming bills yet.', style: TextStyle(fontWeight: FontWeight.w600, color: LedgerColors.text)),
                      const SizedBox(height: 4),
                      Text('Add recurring expenses below and they will show here.',
                          style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Add recurring expense form
              Text('ADD RECURRING EXPENSE', style: TextStyle(fontSize: 12, color: LedgerColors.muted, letterSpacing: 1)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Rent, AT&T, Netflix'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _dayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Due day', hintText: '1-31'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Category'),
                items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _saveBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LedgerColors.accent,
                  foregroundColor: LedgerColors.bg,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Save recurring expense'),
              ),
              const SizedBox(height: 24),

              // List of all recurring bills
              if (allBills.isEmpty)
                Text('No recurring expenses saved yet.', style: TextStyle(fontSize: 13, color: LedgerColors.faint))
              else
                ...allBills.map((b) => _BillRow(
                      bill: b,
                      onAddThisMonth: () => _addForThisMonth(b),
                      onDelete: () => _confirmDelete(b),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final RecurringBill bill;
  final VoidCallback onAddThisMonth;
  final VoidCallback onDelete;

  const _BillRow({required this.bill, required this.onAddThisMonth, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bucket = bucketOf[bill.category] ?? BudgetBucket.wants;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(bill.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LedgerColors.text),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('\$${bill.amount.toStringAsFixed(2)}', style: LedgerTheme.numberStyle.copyWith(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bucket.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(bill.category, style: TextStyle(fontSize: 10, color: bucket.color)),
                ),
                const SizedBox(width: 8),
                Text('Due day ${bill.day} · monthly', style: TextStyle(fontSize: 11, color: LedgerColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(onPressed: onAddThisMonth, child: const Text('Add for this month')),
                const Spacer(),
                TextButton(
                  onPressed: onDelete,
                  child: Text('Delete', style: TextStyle(color: LedgerColors.over)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
