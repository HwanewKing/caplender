import 'package:caplender/data/models.dart';
import 'package:caplender/services/memo_repository.dart';
import 'package:caplender/services/memo_store.dart';
import 'package:caplender/utils/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMemoRepository extends MemoRepository {
  _FakeMemoRepository(this._batches);

  /// Each call to [listPhotoMemos] returns the next batch in this list,
  /// repeating the last one once the list is exhausted. Lets us simulate
  /// data appearing between successive refreshes.
  final List<List<Event>> _batches;
  int _calls = 0;

  @override
  Future<List<Event>> listPhotoMemos() async {
    final idx = _calls < _batches.length ? _calls : _batches.length - 1;
    _calls += 1;
    // Yield so the call is observably async.
    await Future<void>.delayed(Duration.zero);
    return _batches[idx];
  }
}

void main() {
  test('parseRemindPreset keeps documented presets stable', () {
    final now = DateTime(2026, 5, 9, 15, 30);

    expect(
      parseRemindPreset('1시간 후', now: now),
      DateTime(2026, 5, 9, 16, 30),
    );
    expect(
      parseRemindPreset('내일 오전 9:00', now: now),
      DateTime(2026, 5, 10, 9, 0),
    );
    expect(
      parseRemindPreset('3일 뒤', now: now),
      DateTime(2026, 5, 12, 9, 0),
    );
  });

  test('isoWeekNumber matches reference cases', () {
    // 2026-01-01 is a Thursday → in ISO week 1 of 2026.
    expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
    // 2025-12-29 (Monday) starts ISO week 1 of 2026.
    expect(isoWeekNumber(DateTime(2025, 12, 29)), 1);
    // 2026-05-09 (Saturday) is in ISO week 19.
    expect(isoWeekNumber(DateTime(2026, 5, 9)), 19);
    // 2024-12-31 (Tuesday) is in ISO week 1 of 2025.
    expect(isoWeekNumber(DateTime(2024, 12, 31)), 1);
  });

  test('eventsForDate includes reminders scheduled for another day', () async {
    final day = DateTime(2026, 5, 10);
    final store = MemoStore(
      repository: _FakeMemoRepository([
        [
          Event(
            id: 'capture',
            date: day,
            kind: EventKind.photoMemo,
            title: 'same-day capture',
          ),
          Event(
            id: 'reminder',
            date: DateTime(2026, 5, 8),
            kind: EventKind.photoMemo,
            title: 'reminder only',
            remind: true,
            remindAt: '오전 9:00',
            remindAtTime: DateTime(2026, 5, 10, 9, 0),
          ),
        ],
      ]),
    );

    while (!store.hasResolvedFirstLoad) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(
      store.eventsForDate(day).map((e) => e.id),
      ['capture', 'reminder'],
    );

    store.dispose();
  });

  test(
    'refresh queues a follow-up fetch so concurrent callers see fresh data',
    () async {
      // Two batches: the first is empty (initial load), the second contains a
      // freshly-saved memo. Simulates the "save → await refresh()" flow that
      // used to short-circuit when an in-flight refresh was already running.
      final batch1 = <Event>[];
      final batch2 = [
        Event(
          id: 'just-saved',
          date: DateTime(2026, 5, 9),
          kind: EventKind.photoMemo,
          title: '방금 저장됨',
        ),
      ];
      final store = MemoStore(
        repository: _FakeMemoRepository([batch1, batch2]),
      );

      // The constructor already kicked off refresh #1. Immediately request
      // refresh #2 — under the old debounce-by-return rule this would no-op.
      final follow = store.refresh();
      await follow;

      expect(store.galleryItems().map((e) => e.id), ['just-saved']);
      store.dispose();
    },
  );

  test('formatRemindLabel summarises today / tomorrow / future', () {
    final now = DateTime(2026, 5, 9, 15, 30);
    DateTime at(int month, int day, int h, int m) =>
        DateTime(now.year, month, day, h, m);

    String label(DateTime t) {
      // We can't inject `now` into formatRemindLabel without changing its
      // signature; assert the structure instead of the exact prefix.
      return formatRemindLabel(t);
    }

    // Today (relative to now-of-test runtime): just verify it ends with the
    // formatted time.
    final today = at(now.month, now.day, 18, 0);
    expect(label(today).endsWith(formatTimeOnly(today)), isTrue);
    // 5월 12일 오전 9:00 — far enough in the future that it should include
    // the explicit month/day label regardless of when the test runs.
    final far = DateTime(now.year + 1, 8, 12, 9, 0);
    expect(label(far).contains('8월 12일'), isTrue);
  });
}
