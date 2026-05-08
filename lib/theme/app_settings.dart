import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import 'colors.dart';

/// Mutable global state for tweakable display options.
///
/// Persistence layers (most → least durable):
/// 1. SharedPreferences (this class) — survives app restart on the device.
/// 2. profiles.settings JSONB (next phase) — syncs across the user's devices
///    once they upgrade from anonymous to a permanent account.
///
/// [toJson] / [applyJson] are the contract for layer #2: when we add Supabase
/// sync, we just push [toJson] up after each change, and call [applyJson] on
/// fresh fetch. Local prefs are cache; the row in `profiles.settings` is truth
/// for permanent users.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  final SharedPreferences _prefs;

  static const _kFontScale = 'app.fontScale';
  static const _kAccent = 'app.accent';
  static const _kNotify = 'app.notifyEnabled';
  static const _kAutoOcr = 'app.autoOcrEnabled';
  static const _kAutoCat = 'app.autoCategorize';
  static const _kHolidays = 'app.showHolidays';

  FontScale _fontScale = FontScale.md;
  Color _accent = AppColors.teal;
  bool _notifyEnabled = true;
  bool _autoOcrEnabled = true;
  bool _autoCategorize = true;
  bool _showHolidays = true;

  static Future<AppSettings> create() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppSettings._(prefs);
    s._loadFromPrefs();
    return s;
  }

  void _loadFromPrefs() {
    final fsName = _prefs.getString(_kFontScale);
    if (fsName != null) {
      _fontScale = FontScale.values.firstWhere(
        (f) => f.name == fsName,
        orElse: () => FontScale.md,
      );
    }
    final accent = _prefs.getInt(_kAccent);
    if (accent != null) _accent = Color(accent);
    _notifyEnabled = _prefs.getBool(_kNotify) ?? true;
    _autoOcrEnabled = _prefs.getBool(_kAutoOcr) ?? true;
    _autoCategorize = _prefs.getBool(_kAutoCat) ?? true;
    _showHolidays = _prefs.getBool(_kHolidays) ?? true;
  }

  FontScale get fontScale => _fontScale;
  Color get accent => _accent;
  bool get notifyEnabled => _notifyEnabled;
  bool get autoOcrEnabled => _autoOcrEnabled;
  bool get autoCategorize => _autoCategorize;
  bool get showHolidays => _showHolidays;

  set fontScale(FontScale v) {
    if (v == _fontScale) return;
    _fontScale = v;
    _prefs.setString(_kFontScale, v.name);
    notifyListeners();
  }

  set accent(Color v) {
    if (v == _accent) return;
    _accent = v;
    _prefs.setInt(_kAccent, v.toARGB32());
    notifyListeners();
  }

  set notifyEnabled(bool v) {
    if (v == _notifyEnabled) return;
    _notifyEnabled = v;
    _prefs.setBool(_kNotify, v);
    notifyListeners();
  }

  set autoOcrEnabled(bool v) {
    if (v == _autoOcrEnabled) return;
    _autoOcrEnabled = v;
    _prefs.setBool(_kAutoOcr, v);
    notifyListeners();
  }

  set autoCategorize(bool v) {
    if (v == _autoCategorize) return;
    _autoCategorize = v;
    _prefs.setBool(_kAutoCat, v);
    notifyListeners();
  }

  set showHolidays(bool v) {
    if (v == _showHolidays) return;
    _showHolidays = v;
    _prefs.setBool(_kHolidays, v);
    notifyListeners();
  }

  /// Serialize to JSON for syncing into `profiles.settings` JSONB.
  Map<String, dynamic> toJson() => {
        'fontScale': _fontScale.name,
        'accent': _accent.toARGB32(),
        'notifyEnabled': _notifyEnabled,
        'autoOcrEnabled': _autoOcrEnabled,
        'autoCategorize': _autoCategorize,
        'showHolidays': _showHolidays,
      };

  /// Apply settings from a JSON map (e.g. fetched from `profiles.settings`).
  /// Each setter persists to SharedPreferences too, so the local cache stays
  /// in sync with the remote source of truth.
  void applyJson(Map<String, dynamic> json) {
    final fs = json['fontScale'];
    if (fs is String) {
      fontScale = FontScale.values.firstWhere(
        (f) => f.name == fs,
        orElse: () => FontScale.md,
      );
    }
    final ac = json['accent'];
    if (ac is int) accent = Color(ac);
    final ne = json['notifyEnabled'];
    if (ne is bool) notifyEnabled = ne;
    final oo = json['autoOcrEnabled'];
    if (oo is bool) autoOcrEnabled = oo;
    final ca = json['autoCategorize'];
    if (ca is bool) autoCategorize = ca;
    final sh = json['showHolidays'];
    if (sh is bool) showHolidays = sh;
  }
}

/// InheritedNotifier wrapper so descendants can listen with `AppSettingsScope.of(context)`.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in widget tree');
    return scope!.notifier!;
  }
}
