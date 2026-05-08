import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap.dart';

/// Reactive wrapper around Supabase auth.
///
/// Designed for the planned anonymous → permanent (email / OAuth) upgrade
/// path. Supabase keeps the same `user.id` UUID across the upgrade, and our
/// RLS + foreign keys are all scoped on that ID — so no data migration is
/// needed when a user adds an email or links a social provider later.
class AuthService extends ChangeNotifier {
  AuthService() {
    _sub = supabase.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  User? get currentUser => supabase.auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  bool get isAuthenticated => currentUser != null;
  String? get email => currentUser?.email;
  String? get userId => currentUser?.id;

  /// Future: upgrade an anonymous user by attaching an email. Supabase sends
  /// a confirmation link; once the user clicks it, `isAnonymous` flips to
  /// false. Data tied to the user's UUID is preserved.
  Future<void> linkEmail(String email) {
    return supabase.auth.updateUser(UserAttributes(email: email));
  }

  /// Future: link an OAuth identity (Google / Apple / Kakao via OIDC).
  /// Uncomment once the providers are configured in Supabase Dashboard.
  // Future<bool> linkOAuth(OAuthProvider provider) {
  //   return supabase.auth.linkIdentity(provider);
  // }

  /// Sign out and immediately sign back in as a fresh anonymous user. We
  /// always want a session so RLS-scoped queries don't fail.
  Future<void> signOutAndStartFresh() async {
    await supabase.auth.signOut();
    await supabase.auth.signInAnonymously();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// InheritedNotifier so any widget can react to auth changes via
/// `AuthScope.of(context)`.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService service,
    required super.child,
  }) : super(notifier: service);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.notifier!;
  }
}
