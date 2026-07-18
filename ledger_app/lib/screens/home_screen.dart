import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/ledger_app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../logic/month_utils.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String route) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  String _money(double v, {String symbol = '\$'}) {
    final sign = v < 0 ? '-' : '';
    return '$sign$symbol${v.abs().toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<LedgerAppState>();
    final safe = app.safeToSpendThisMonth;
    final isNegative = safe.safe < 0;
    final upcoming = app.upcomingBills30Days.take(3).toList();

    return Scaffold(
      backgroundColor: LedgerColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand + local-only lock, matches PWA header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ledger', style: Theme.of(context).textTheme.headlineSmall),
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: LedgerColors.faint),
                    const SizedBox(width: 4),
                    Text('Local only', style: TextStyle(fontSize: 12, color: LedgerColors.faint)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month navigation bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => app.shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  color: LedgerColors.text,
                ),
                Text(
                  MonthUtils.label(app.viewMonth),
                  style: LedgerTheme.numberStyle.copyWith(fontSize: 15, color: LedgerColors.text),
                ),
                IconButton(
                  onPressed: () => app.shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  color: LedgerColors.text,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero number — "Safe to spend"
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safe to spend', style: TextStyle(fontSize: 12, color: LedgerColors.muted, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(
                    _money(safe.safe),
                    style: LedgerTheme.numberStyle.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: isNegative ? LedgerColors.over : LedgerColors.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'after bills, savings, and spending this month · ${MonthUtils.label(app.viewMonth)}',
                    style: TextStyle(fontSize: 12, color: LedgerColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Upcoming bills (next 30 days, top 3) — only shows if any exist
            if (upcoming.isNotEmpty) ...[
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('📅 Upcoming bills', style: TextStyle(fontSize: 12, color: LedgerColors.muted)),
                        Text('next 30 days', style: TextStyle(fontSize: 10, color: LedgerColors.faint)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...upcoming.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${b.date.substring(5)} · ${b.bill.name}',
                                  style: TextStyle(fontSize: 12, color: LedgerColors.text)),
                              Text(_money(b.bill.amount), style: LedgerTheme.numberStyle.copyWith(fontSize: 12)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // First-run welcome — only shows if truly no data yet
            if (!app.hasAnyData) ...[
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text('Welcome to Ledger', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Set your income, log what you spend, and watch your plan come to life.\nYour data never leaves this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: LedgerColors.muted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => onNavigate('allocator'),
                      style: ElevatedButton.styleFrom(backgroundColor: LedgerColors.accent, foregroundColor: LedgerColors.bg),
                      child: const Text('Set up your plan'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Navigation grid — Log spending / Your plan / How you're doing / History / Bills
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _NavCard(icon: '✏️', title: 'Log spending', desc: 'Five seconds. We remember the rest.', onTap: () => onNavigate('logger')),
                _NavCard(icon: '📋', title: 'Your plan', desc: 'Set income and your split.', onTap: () => onNavigate('allocator')),
                _NavCard(icon: '📊', title: "How you're doing", desc: 'Real split vs. plan.', onTap: () => onNavigate('gauge')),
                _NavCard(icon: '📈', title: 'History', desc: 'Month by month.', onTap: () => onNavigate('history')),
                _NavCard(icon: '📅', title: 'Bills', desc: 'Recurring expenses.', onTap: () => onNavigate('bills')),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _NavCard({required this.icon, required this.title, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LedgerColors.text)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 11, color: LedgerColors.muted)),
        ],
      ),
    );
  }
}
