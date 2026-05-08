import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Secrets are injected at build/run time via `--dart-define` (or
/// `--dart-define-from-file=env.json`). Nothing is bundled in assets.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Initializes Supabase and ensures an anonymous session exists.
///
/// Anonymous sign-in keeps the 40-50대 onboarding friction at zero — the user
/// just opens the app and starts capturing. The anonymous user can later be
/// upgraded to email/social without losing data.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Run with:\n'
      '  flutter run --dart-define-from-file=env.json\n'
      'or pass them with --dart-define=KEY=VALUE.',
    );
  }

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  final auth = Supabase.instance.client.auth;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
}

/// Convenience accessor used throughout the app.
SupabaseClient get supabase => Supabase.instance.client;

/// `null` only during the very first frame (before bootstrap) — afterwards an
/// anonymous user is always present.
String? get currentUserId => supabase.auth.currentUser?.id;
