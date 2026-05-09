/// Shared date / time formatting helpers.
///
/// Lives in `utils` (no widget or service imports) so both the UI layer and
/// the repository can call it without creating a dependency cycle.
library;

/// "오전 9:00" / "오후 2:30".
String formatTimeOnly(DateTime t) {
  final h12 = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
  final ampm = t.hour < 12 ? '오전' : '오후';
  return '$ampm $h12:${t.minute.toString().padLeft(2, '0')}';
}

const _weekdayMonFirst = ['월', '화', '수', '목', '금', '토', '일'];
const _weekdaySunFirst = ['일', '월', '화', '수', '목', '금', '토'];

/// Dart weekday convention is Mon=1..Sun=7.
String koreanWeekdayShort(DateTime d) => _weekdayMonFirst[d.weekday - 1];

/// Same letters but indexed Sun=0..Sat=6 for callers that already lay out a
/// Sunday-first row (calendar day cells, day detail header).
String koreanWeekdaySunFirst(DateTime d) => _weekdaySunFirst[d.weekday % 7];

String formatDateLabel(DateTime t) =>
    '${t.year}년 ${t.month}월 ${t.day}일 (${koreanWeekdayShort(t)})';

/// Friendly summary used in the reminder toggle subtitle: "오늘 오전 9:00",
/// "내일 오후 2:30", or "5월 12일 오전 9:00" for further-out dates.
String formatRemindLabel(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(t.year, t.month, t.day);
  final diff = that.difference(today).inDays;
  final time = formatTimeOnly(t);
  if (diff == 0) return '오늘 $time';
  if (diff == 1) return '내일 $time';
  return '${t.month}월 ${t.day}일 $time';
}

/// Reminder preset chips offered in the memo entry / edit forms. A small
/// curated set — pickers cover the everything-else case.
const remindPresets = ['1시간 후', '내일 오전 9:00', '3일 뒤', '1주일 뒤'];

/// Convert a preset chip ("내일 오전 9:00", "3일 뒤" …) into an absolute
/// DateTime relative to `now`. Falls back to "1시간 후" for unknown values.
DateTime parseRemindPreset(String preset, {DateTime? now}) {
  final base = now ?? DateTime.now();
  switch (preset) {
    case '1시간 후':
      return base.add(const Duration(hours: 1));
    case '내일 오전 9:00':
      final tomorrow = base.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    case '3일 뒤':
      final d = base.add(const Duration(days: 3));
      return DateTime(d.year, d.month, d.day, 9, 0);
    case '1주일 뒤':
      final d = base.add(const Duration(days: 7));
      return DateTime(d.year, d.month, d.day, 9, 0);
    default:
      return base.add(const Duration(hours: 1));
  }
}
