import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A horizontal progress bar with a target-position marker overlaid.
/// This is the standard budgeting-app pattern (Mint, YNAB, etc. all use
/// a version of this) for showing "here's where you are" vs.
/// "here's where you planned to be" on one bar. Port of the PWA's
/// `.track / .fill / .target` CSS pattern.
class BudgetProgressBar extends StatelessWidget {
  final double fillPercent; // 0-100, actual position
  final double targetPercent; // 0-100, target/plan marker position
  final Color fillColor;

  const BudgetProgressBar({
    super.key,
    required this.fillPercent,
    required this.targetPercent,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 10,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Track background
              Container(
                decoration: BoxDecoration(
                  color: LedgerColors.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: (fillPercent.clamp(0, 100)) / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Target marker - a small vertical line at the plan position
              Positioned(
                left: (width * (targetPercent.clamp(0, 100)) / 100) - 1,
                top: -2,
                bottom: -2,
                child: Container(width: 2, color: LedgerColors.text.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
      },
    );
  }
}
