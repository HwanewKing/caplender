import 'package:flutter/widgets.dart';

import '../data/categories.dart';
import '../data/models.dart';
import 'memo_repository.dart';

/// In-memory cache of the current user's photo memos. Screens consume this
/// via [MemoStoreScope] so we don't re-query Supabase on every rebuild,
/// and so a save / edit / delete in one screen propagates everywhere.
///
/// On creation the store kicks off a background load. Listeners fire
/// from the initial load, from explicit [refresh] calls after a write,
/// and from on-demand signed-URL fetches for thumbnails.
class MemoStore extends ChangeNotifier {
  MemoStore({MemoRepository? repository})
      : _repo = repository ?? MemoRepository() {
    refresh();
  }

  final MemoRepository _repo;

  List<Event> _photoMemos = const [];
  bool _loading = false;
  Object? _error;

  bool get loading => _loading;
  Object? get error => _error;

  List<Event> eventsForDate(DateTime d) => _photoMemos
      .where((e) =>
          e.date.year == d.year &&
          e.date.month == d.month &&
          e.date.day == d.day)
      .toList();

  /// Photo memos captured on [d] — what the user wants to see as a photo
  /// thumbnail on the calendar (no bell decoration).
  List<Event> capturesOnDate(DateTime d) =>
      _photoMemos.where((e) => _sameDay(e.date, d)).toList();

  /// Photo memos whose reminder is scheduled to fire on [d], excluding the
  /// case where the memo was *also* captured that day (in which case
  /// [capturesOnDate] already covers it as a photo).
  List<Event> remindersOnDate(DateTime d) => _photoMemos.where((e) {
        if (!e.remind || e.remindAtTime == null) return false;
        if (_sameDay(e.date, d)) return false;
        return _sameDay(e.remindAtTime!, d);
      }).toList();

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Photo memos with reminders enabled.
  List<Event> remindersList() =>
      _photoMemos.where((e) => e.remind).toList();

  List<Event> galleryItems() => _photoMemos;

  /// Most recently captured memo in [categoryId], or null if the category
  /// has none yet. `_photoMemos` is already sorted by memo_date desc /
  /// created_at desc by the repo, so the first match is the freshest.
  Event? latestForCategory(String categoryId) {
    for (final e in _photoMemos) {
      if ((e.categoryId ?? 'memo') == categoryId) return e;
    }
    return null;
  }

  /// Category list with real counts derived from the DB rows.
  List<CategoryItem> categoriesWithCount() {
    final counts = <String, int>{};
    for (final e in _photoMemos) {
      final id = e.categoryId ?? 'memo';
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return [
      for (final c in appCategories)
        CategoryItem(
          id: c.id,
          name: c.name,
          colorValue: c.colorValue,
          count: counts[c.id] ?? 0,
        ),
    ];
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _photoMemos = await _repo.listPhotoMemos();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Lookup a photo memo by id. Returns null for memos that have been
  /// deleted since the last refresh.
  Event? findById(String id) {
    for (final e in _photoMemos) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> updatePhotoMemo({
    required String id,
    required String title,
    required String memo,
    required String categoryId,
    required bool remind,
    DateTime? remindAt,
  }) async {
    await _repo.updatePhotoMemo(
      id: id,
      title: title,
      memo: memo,
      categoryId: categoryId,
      remind: remind,
      remindAt: remindAt,
    );
    await refresh();
  }

  Future<void> deletePhotoMemo({
    required String id,
    String? photoPath,
  }) async {
    await _repo.deletePhotoMemo(id: id, photoPath: photoPath);
    if (photoPath != null) _urlCache.remove(photoPath);
    await refresh();
  }

  // ── Signed URL cache ──────────────────────────────────────────────────
  // Each call to createSignedUrl is a network round-trip. The cards in the
  // gallery render dozens of thumbnails at once, so we memoize per path
  // with a TTL just below Supabase's signing TTL.

  static const _urlTtl = Duration(minutes: 30);
  final Map<String, _CachedUrl> _urlCache = {};

  /// Returns a signed URL for [photoPath], using the cache when fresh.
  /// Throws on network failure — callers (e.g. FutureBuilder) should
  /// handle the error and fall back to a placeholder.
  Future<String> signedUrlFor(String photoPath) async {
    final cached = _urlCache[photoPath];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }
    final url = await _repo.signedUrlFor(photoPath, ttl: _urlTtl);
    _urlCache[photoPath] = _CachedUrl(
      url: url,
      expiresAt: DateTime.now().add(_urlTtl - const Duration(minutes: 1)),
    );
    return url;
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  const _CachedUrl({required this.url, required this.expiresAt});
}

/// InheritedNotifier so any descendant rebuilds when the store changes.
class MemoStoreScope extends InheritedNotifier<MemoStore> {
  const MemoStoreScope({
    super.key,
    required MemoStore store,
    required super.child,
  }) : super(notifier: store);

  static MemoStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MemoStoreScope>();
    assert(scope != null, 'MemoStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
