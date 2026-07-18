import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'logger_screen.dart';
import 'allocator_screen.dart';
import 'bills_screen.dart';
import 'gauge_screen.dart';
import 'history_screen.dart';

class LedgerShell extends StatefulWidget {
  const LedgerShell({super.key});

  @override
  State<LedgerShell> createState() => _LedgerShellState();
}

class _LedgerShellState extends State<LedgerShell> {
  String _route = 'home';

  void _goTo(String route) {
    const builtScreens = {'home', 'logger', 'allocator', 'bills', 'gauge', 'history'};
    setState(() => _route = builtScreens.contains(route) ? route : 'home');
  }

  @override
  Widget build(BuildContext context) {
    switch (_route) {
      case 'logger':
        return LoggerScreen(onBack: () => _goTo('home'));
      case 'allocator':
        return AllocatorScreen(onBack: () => _goTo('home'));
      case 'bills':
        return BillsScreen(onBack: () => _goTo('home'));
      case 'gauge':
        return GaugeScreen(onBack: () => _goTo('home'));
      case 'history':
        return HistoryScreen(onBack: () => _goTo('home'));
      case 'home':
      default:
        return HomeScreen(onNavigate: _goTo);
    }
  }
}
