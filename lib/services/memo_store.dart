import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/categories.dart';
import '../data/models.dart';
import 'memo_repository.dart';

/// In-memory cache of the current user's photo memos. Screens consume this
/// via [MemoStoreScope] so we don't re-query Supabase on every rebuild,
/// and so a save / edit / delete in one screen propagates everywhere.
///
/// On creation the store kicks off a background load. Listeners fire from
/// the initial load, from explicit [refresh] calls after a write, and from
/// async signed-URL fetches that populate the URL cache.
class MemoStore extends ChangeNotifier {
  MemoStore({MemoRepository? repository})
      : _repo = repository ?? MemoRepository() {
    refresh();
  }

  final MemoRepository _repo;

  List<Event> _photoMemos = const [];
  bool _loading = false;
  Object? _error;
  bool _hasResolvedFirstLoad = false;

  bool get loading => _loading;
  Object? get error => _error;
  bool get hasResolvedFirstLoad => _hasResolvedFirstLoad;
  bool get isEmpty => _photoMemos.isEmpty;

  /// Events the user expects to find on a specific day in the detail sheet:
  /// the photo captured that day plus any reminders scheduled for that day.
  List<Event> eventsForDate(DateTime d) {
    final events = <Event>[];
    final seenIds = <String>{};
    for (final e in _photoMemos) {
      final captureMatch = _sameDay(e.date, d);
      final reminderMatch =
          e.remind && e.remindAtTime != null && _sameDay(e.remindAtTime!, d);
      if ((captureMatch || reminderMatch) && seenIds.add(e.id)) {
        events.add(e);
      }
    }
    return events;
  }

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
  List<Event> remindersList() => _photoMemos.where((e) => e.remind).toList();

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

  // ── Refresh queue ─────────────────────────────────────────────────────
  // Callers (screen save / delete / edit) expect that `await refresh()` will
  // see their write reflected in the loaded list. A naive
  //   if (_loading) return;
  // returns early when an earlier refresh is still in flight, which means
  // the caller's write may not be loaded yet. We instead chain a single
  // queued refresh after the current one so concurrent callers all wait
  // on a fetch that started AFTER their write landed.
  Future<void>? _running;
  Future<void>? _queued;

  Future<void> refresh() {
    if (_running == null) {
      return _running = _runOnce();
    }
    return _queued ??= _running!.catchError((_) {}).then((_) {
      _queued = null;
      return refresh();
    });
  }

  Future<void> _runOnce() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _photoMemos = await _repo.listPhotoMemos();
    } catch (e) {
      _error = e;
    } finally {
      _hasResolvedFirstLoad = true;
      _loading = false;
      _running = null;
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
  // Each call to createSignedUrl is a network round-trip. The gallery
  // renders dozens of thumbnails at once, so we memoize per path with a TTL
  // just below Supabase's signing TTL.
  //
  // The API is deliberately split into a SYNC getter and a fire-and-forget
  // request so widgets don't have to use FutureBuilder. FutureBuilder
  // re-renders its placeholder every time it sees a new Future identity,
  // which made cached thumbnails flash on every store rebuild.

  static const _urlTtl = Duration(minutes: 30);
  final Map<String, _CachedUrl> _urlCache = {};
  final Set<String> _pendingFetches = {};

  /// Returns a cached signed URL for [photoPath] if one is fresh, otherwise
  /// null. Expired entries are cleared as a side effect so the cache doesn't
  /// grow unbounded across long sessions.
  String? cachedUrlFor(String photoPath) {
    final cached = _urlCache[photoPath];
    if (cached == null) return null;
    if (cached.expiresAt.isBefore(DateTime.now())) {
      _urlCache.remove(photoPath);
      return null;
    }
    return cached.url;
  }

  /// Kick off a signed-URL fetch for [photoPath] if none is in flight and
  /// no fresh entry exists. Listeners are notified once the URL is cached,
  /// so widgets that read [cachedUrlFor] in build will rebuild and pick it up.
  void requestSignedUrl(String photoPath) {
    if (cachedUrlFor(photoPath) != null) return;
    if (_pendingFetches.contains(photoPath)) return;
    _pendingFetches.add(photoPath);
    // Schedule on a microtask so callers can request mid-build safely.
    scheduleMicrotask(() => _fetchSignedUrl(photoPath));
  }

  Future<void> _fetchSignedUrl(String photoPath) async {
    try {
      final url = await _repo.signedUrlFor(photoPath, ttl: _urlTtl);
      _urlCache[photoPath] = _CachedUrl(
        url: url,
        // Renew shortly before the actual signed URL expires.
        expiresAt: DateTime.now().add(_urlTtl - const Duration(minutes: 1)),
      );
      notifyListeners();
    } catch (e) {
      if (!kReleaseMode) {
        debugPrint('[caplender] signed url fetch failed for $photoPath: $e');
      }
    } finally {
      _pendingFetches.remove(photoPath);
    }
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
    final scope = context.dependOnInheritedWidgetOfExactType<MemoStoreScope>();
    assert(scope != null, 'MemoStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
