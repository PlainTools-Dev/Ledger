import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/hive_ledger_storage.dart';
import 'state/ledger_app_state.dart';
import 'theme/app_theme.dart';
import 'screens/ledger_shell.dart';

void main() {
  runApp(const LedgerApp());
}

class LedgerApp extends StatefulWidget {
  const LedgerApp({super.key});

  @override
  State<LedgerApp> createState() => _LedgerAppState();
}

class _LedgerAppState extends State<LedgerApp> {
  late final LedgerAppState _appState;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _appState = LedgerAppState(HiveLedgerStorage());
    _appState.init().then((_) => setState(() => _ready = true));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        theme: LedgerTheme.dark,
        home: Scaffold(
          backgroundColor: LedgerColors.bg,
          body: Center(child: CircularProgressIndicator(color: LedgerColors.accent)),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp(
        title: 'Ledger',
        debugShowCheckedModeBanner: false,
        theme: LedgerTheme.dark,
        home: const LedgerShell(),
      ),
    );
  }
}
