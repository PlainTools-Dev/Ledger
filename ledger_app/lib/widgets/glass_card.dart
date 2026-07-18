import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of the PWA's shared surface styling (`.card, .chart, .sbox,
/// .gauge, .billrow, .firsthint, .notice, .mrow` all shared this look).
///
/// The original used `backdrop-filter: blur(16px)` for a glass effect.
/// Deliberately using a plain semi-transparent surface here instead of
/// Flutter's BackdropFilter — the PWA build notes flagged broad
/// backdrop-filter usage as a mobile performance concern even in the
/// browser; a real blur-behind-content effect is more expensive on
/// mobile GPUs than in a desktop browser, so this trades a small bit
/// of visual polish for guaranteed smooth scrolling on real devices.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LedgerColors.surface,
        borderRadius: BorderRadius.circular(LedgerColors.radius),
        border: Border.all(color: LedgerColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LedgerColors.radius),
      child: card,
    );
  }
}
