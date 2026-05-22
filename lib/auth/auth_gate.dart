import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// Central auth UI coordinator. Firebase can finish sign-in after the Google/Apple
/// sheet closes while [GoogleSignIn.authenticate] returns null on iOS — this gate
/// forces shell rebuilds when the session becomes available.
class AuthGate extends ChangeNotifier {
  AuthGate() {
    _subscription = FirebaseAuth.instance.userChanges().listen(_onFirebaseUser);
    _user = FirebaseAuth.instance.currentUser;
  }

  StreamSubscription<User?>? _subscription;
  User? _user;

  Future<Map<String, dynamic>> Function()? _accessStatusLoader;
  Future<Map<String, dynamic>>? _accessStatusFuture;
  bool _accessCheckReady = false;

  /// Bumped on sign-out so [AuthWrapper] mounts a fresh [SignInScreen].
  int signInScreenKey = 0;

  User? get user => _user ?? FirebaseAuth.instance.currentUser;

  bool get isSignedIn => user != null;

  /// True after [preloadAccessStatus] finishes — [AuthWrapper] opens the app then.
  bool get accessCheckReady => _accessCheckReady;

  void _onFirebaseUser(User? user) {
    _user = user;
    if (user == null) {
      _accessStatusFuture = null;
      _accessCheckReady = false;
      signInScreenKey++;
    }
    notifyListeners();
  }

  void registerAccessStatusLoader(
    Future<Map<String, dynamic>> Function() loader,
  ) {
    _accessStatusLoader = loader;
  }

  /// Clears cached session state after sign-out (called from settings, etc.).
  void clearSession() {
    _user = null;
    _accessStatusFuture = null;
    _accessCheckReady = false;
    signInScreenKey++;
    notifyListeners();
  }

  /// Starts a fresh post-sign-in access check (never reuses a prior session's future).
  Future<void> preloadAccessStatus() async {
    final loader = _accessStatusLoader;
    if (loader == null) return;
    _accessCheckReady = false;
    notifyListeners();
    _accessStatusFuture = loader();
    await _accessStatusFuture;
    _accessCheckReady = true;
    notifyListeners();
  }

  /// Future used by [_SignedInAccessChecker]; reuses preload when available.
  Future<Map<String, dynamic>> resolveAccessFuture(
    Future<Map<String, dynamic>> Function() fallback,
  ) {
    return _accessStatusFuture ??= fallback();
  }

  /// Call after OAuth completes so [AuthWrapper] rebuilds even if the plugin
  /// returned null/cancelled while Firebase already has a session.
  void notifySignedIn() {
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  /// Wait until Firebase reports a signed-in user (stream + poll).
  Future<bool> waitForSignedIn({
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) {
      _user = existing;
      notifyListeners();
      return true;
    }

    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .where((u) => u != null)
          .cast<User>()
          .first
          .timeout(timeout);
      _user = user;
      notifyListeners();
      return true;
    } catch (_) {
      // Fall through to polling (iOS can lag after the OAuth sheet closes).
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        _user = current;
        notifyListeners();
        return true;
      }
      await Future.delayed(interval);
    }
    return false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Signs out, resets [AuthGate], and pops pushed routes (e.g. Settings) so
/// [AuthWrapper] can show the Google/Apple sign-in screen.
Future<void> performAppSignOut(BuildContext context) async {
  await AuthService().signOut();
  if (!context.mounted) return;
  context.read<AuthGate>().clearSession();
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }
}
