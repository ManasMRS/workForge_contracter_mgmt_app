import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/repository.dart';
import 'services/connectivity_sync_listener.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ContractorApp());
}

class ContractorApp extends StatefulWidget {
  const ContractorApp({super.key});

  @override
  State<ContractorApp> createState() => _ContractorAppState();
}

class _ContractorAppState extends State<ContractorApp> {
  late final AuthService _auth;
  ConnectivitySyncListener? _syncListener;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_auth.isLoggedIn && _syncListener == null) {
      // Starts pushing any offline-queued changes as soon as a session
      // exists, and keeps syncing automatically whenever connectivity
      // comes back.
      _syncListener = ConnectivitySyncListener(Repository(_auth));
      _syncListener!.start();
    } else if (!_auth.isLoggedIn && _syncListener != null) {
      _syncListener!.stop();
      _syncListener = null;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _syncListener?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: MaterialApp(
        title: 'workForge ©mqub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeFor(AppMoods.all.first),
        home: const SplashScreen(),
      ),
    );
  }
}
