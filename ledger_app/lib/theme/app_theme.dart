import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Exact port of the PWA's `:root` CSS custom properties —
/// "Luxury Palette — Muted Gold + Deep Teal". Values copied directly
/// from index.html, not reinterpreted, since this palette already
/// tested well on mobile as a PWA.
class LedgerColors {
  static const bg = Color(0xFF0F1412);
  static const surface = Color(0xBF16201D); // rgba(22,32,29,0.75)
  static const surface2 = Color(0x991E2C28); // rgba(30,44,40,0.6)
  static const border = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const text = Color(0xFFECE8E0);
  static const muted = Color(0xFFA8B3AB);
  static const faint = Color(0xFF6F7D75);

  static const accent = Color(0xFFC9A86C); // muted gold
  static const accentDim = Color(0x26C9A86C); // rgba(201,168,108,0.15)
  static const accentGlow = Color(0x14C9A86C); // rgba(201,168,108,0.08)

  static const needs = Color(0xFF5A7D7A);
  static const wants = Color(0xFFB8877A);
  static const savings = Color(0xFFE8A0B4);
  static const over = Color(0xFFD97A7A); // over-budget warning color

  static const radius = 16.0;
}

extension BudgetBucketColor on BudgetBucket {
  Color get color {
    switch (this) {
      case BudgetBucket.needs:
        return LedgerColors.needs;
      case BudgetBucket.wants:
        return LedgerColors.wants;
      case BudgetBucket.savings:
        return LedgerColors.savings;
    }
  }
}

class LedgerTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: LedgerColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: LedgerColors.accent,
        surface: LedgerColors.surface,
        onSurface: LedgerColors.text,
        error: LedgerColors.over,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: LedgerColors.text,
        displayColor: LedgerColors.text,
        fontFamily: 'Inter', // matches PWA --sans, falls back to system if not bundled
      ),
      dividerColor: LedgerColors.border,
    );
  }

  /// Monospace style for numeric values — matches the PWA's `.num`
  /// class (`font-variant-numeric: tabular-nums`), used everywhere
  /// money/percentages are displayed so digits align in columns.
  static const numberStyle = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
    fontFamily: 'monospace',
  );
}
