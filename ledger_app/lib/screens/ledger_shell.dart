import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'logger_screen.dart';
import 'allocator_screen.dart';

/// Simple route-switching shell, matching the PWA's `data-go` attribute
/// navigation between named views. Gauge/history/bills screens aren't
/// built yet (next phase) — navigating to them currently no-ops back
/// to home rather than crashing on a missing screen.
class LedgerShell extends StatefulWidget {
  const LedgerShell({super.key});

  @override
  State<LedgerShell> createState() => _LedgerShellState();
}

class _LedgerShellState extends State<LedgerShell> {
  String _route = 'home';

  void _goTo(String route) {
    const builtScreens = {'home', 'logger', 'allocator'};
    setState(() => _route = builtScreens.contains(route) ? route : 'home');
  }

  @override
  Widget build(BuildContext context) {
    switch (_route) {
      case 'logger':
        return LoggerScreen(onBack: () => _goTo('home'));
      case 'allocator':
        return AllocatorScreen(onBack: () => _goTo('home'));
      case 'home':
      default:
        return HomeScreen(onNavigate: _goTo);
    }
  }
}
