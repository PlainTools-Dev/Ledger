import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/ledger_app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../logic/month_utils.dart';

class LoggerScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LoggerScreen({super.key, required this.onBack});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  final _amountController = TextEditingController();
  final _placeController = TextEditingController();
  String? _selectedCategory;
  late String _selectedDate;
  String? _editingTxId;

  @override
  void initState() {
    super.initState();
    final app = context.read<LedgerAppState>();
    // Matches JS defaultTxDate(): today if viewing current month, else 1st of viewed month
    final isCurrentMonth = app.viewMonth == MonthUtils.keyFor(DateTime.now());
    _selectedDate = isCurrentMonth ? MonthUtils.todayISO() : '${app.viewMonth}-01';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _onPlaceChanged(String value) {
    // Port of JS place-autosuggest: if this place was categorized before, prefill it.
    final app = context.read<LedgerAppState>();
    final suggested = app.storage.suggestedCategoryFor(value);
    if (suggested != null && _selectedCategory == null) {
      setState(() => _selectedCategory = suggested);
    }
  }

  Future<void> _addEntry() async {
    final app = context.read<LedgerAppState>();
    final amount = double.tryParse(_amountController.text);
    final place = _placeController.text.trim();

    if (amount == null || amount <= 0 || place.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount, place, and category.')),
      );
      return;
    }

    final tx = LedgerTransaction(
      id: _editingTxId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      place: place,
      amount: (amount * 100).round() / 100, // matches JS Math.round(amt*100)/100
      category: _selectedCategory!,
    );

    if (_editingTxId != null) {
      await app.updateTransaction(tx);
    } else {
      await app.addTransaction(tx);
    }

    setState(() {
      _amountController.clear();
      _placeController.clear();
      _selectedCategory = null;
      _editingTxId = null;
    });
  }

  void _startEdit(LedgerTransaction tx) {
    setState(() {
      _editingTxId = tx.id;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _placeController.text = tx.place;
      _selectedCategory = tx.category;
      _selectedDate = tx.date;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingTxId = null;
      _amountController.clear();
      _placeController.clear();
      _selectedCategory = null;
    });
  }

  Future<void> _pickDate() async {
    final parts = _selectedDate.split('-');
    final initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<LedgerAppState>();
    final monthTx = app.transactionsThisMonth..sort((a, b) => b.date.compareTo(a.date));

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
                Text('Log spending', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),

            _FieldLabel('Amount'),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00', prefixText: '\$ '),
            ),
            const SizedBox(height: 14),

            _FieldLabel('Place'),
            TextField(
              controller: _placeController,
              onChanged: _onPlaceChanged,
              decoration: const InputDecoration(hintText: 'e.g. grocery store'),
            ),
            const SizedBox(height: 14),

            _FieldLabel('Category'),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 14),

            _FieldLabel('Date'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Text(_selectedDate, style: LedgerTheme.numberStyle),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _addEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: LedgerColors.accent,
                foregroundColor: LedgerColors.bg,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_editingTxId != null ? 'Save changes' : 'Add entry'),
            ),
            if (_editingTxId != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Cancel edit'),
              ),
            ],

            const SizedBox(height: 24),
            Text('This month', style: TextStyle(fontSize: 13, color: LedgerColors.muted, letterSpacing: 0.5)),
            const SizedBox(height: 8),

            if (monthTx.isEmpty)
              Text('No entries yet.', style: TextStyle(fontSize: 13, color: LedgerColors.faint))
            else
              ...monthTx.map((t) => _TxRow(
                    tx: t,
                    onTap: () => _startEdit(t),
                    onDelete: () => app.deleteTransaction(t.id),
                  )),
          ],
        ),
      ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
    );
  }
}

class _TxRow extends StatelessWidget {
  final LedgerTransaction tx;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _TxRow({required this.tx, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.place, style: TextStyle(fontSize: 13, color: LedgerColors.text)),
                  Text('${tx.date.substring(5)} · ${tx.category}',
                      style: TextStyle(fontSize: 11, color: LedgerColors.faint)),
                ],
              ),
            ),
            Text('\$${tx.amount.toStringAsFixed(2)}', style: LedgerTheme.numberStyle.copyWith(fontSize: 13)),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: LedgerColors.faint),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
