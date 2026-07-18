import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/category.dart';

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

/// Per-category color shades, cycling within each bucket's color
/// family. Exact port of the PWA's FAMILY arrays + CAT_COLOR
/// assignment loop, so chart colors match the original design intent
/// (subtle variation within a bucket, not one flat color per category).
class CategoryColors {
  static const Map<BudgetBucket, List<Color>> _family = {
    BudgetBucket.needs: [Color(0xFF4A6D6A), Color(0xFF5A7D7A), Color(0xFF7A9D9A), Color(0xFF9ABDB8)],
    BudgetBucket.wants: [Color(0xFFA8776A), Color(0xFFB8877A), Color(0xFFD09F92), Color(0xFFE0B7AA)],
    BudgetBucket.savings: [Color(0xFFD98AA6), Color(0xFFE8A0B4), Color(0xFFF0B6C6), Color(0xFFF6CCD6)],
  };

  static final Map<String, Color> _byCategory = _build();

  static Map<String, Color> _build() {
    final result = <String, Color>{};
    final idx = {BudgetBucket.needs: 0, BudgetBucket.wants: 0, BudgetBucket.savings: 0};
    for (final cat in categories) {
      final shades = _family[cat.bucket]!;
      result[cat.name] = shades[idx[cat.bucket]! % shades.length];
      idx[cat.bucket] = idx[cat.bucket]! + 1;
    }
    return result;
  }

  static Color forCategory(String category) => _byCategory[category] ?? LedgerColors.faint;
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
