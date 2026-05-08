import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/models.dart';
import 'screens/home_shell.dart';
import 'services/auth_service.dart';
import 'services/memo_store.dart';
import 'theme/app_settings.dart';
import 'theme/colors.dart';

/// Root application. Wraps the navigation shell in [AppSettingsScope] +
/// [AuthScope] so any descendant can listen to settings or auth state.
class CaplenderApp extends StatefulWidget {
  final AppSettings settings;
  const CaplenderApp({super.key, required this.settings});

  @override
  State<CaplenderApp> createState() => _CaplenderAppState();
}

class _CaplenderAppState extends State<CaplenderApp> {
  final AuthService _auth = AuthService();
  final MemoStore _memoStore = MemoStore();

  @override
  void dispose() {
    _auth.dispose();
    _memoStore.dispose();
    widget.settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: widget.settings,
      child: AuthScope(
        service: _auth,
        child: MemoStoreScope(
          store: _memoStore,
          child: AnimatedBuilder(
            animation: widget.settings,
            builder: (context, _) {
              return MaterialApp(
                title: 'caplender',
                debugShowCheckedModeBanner: false,
                theme: _buildTheme(widget.settings),
                // Scale all text via MediaQuery so we don't have to mutate
                // the TextTheme — some Material 3 styles legitimately have
                // null fontSize, and TextStyle.apply asserts when a null
                // fontSize is combined with a factor != 1.0.
                builder: (context, child) {
                  final scale = widget.settings.fontScale.multiplier;
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: child!,
                  );
                },
                home: const HomeShell(),
              );
            },
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(AppSettings s) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: s.accent,
        primary: s.accent,
        surface: AppColors.cream,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

/// Convenience getter — `Gaegu` is used for handwritten memo bodies. Loaded
/// lazily through google_fonts so we don't need to bundle TTFs in pubspec.
TextStyle gaeguStyle({
  double size = 17,
  Color color = AppColors.inkSoft,
  FontWeight weight = FontWeight.w400,
  double height = 1.35,
}) {
  return GoogleFonts.gaegu(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
  );
}
