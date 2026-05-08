import 'models.dart';

/// Mock state assumed by the prototype: today is 2027-03-25.
final DateTime kToday = DateTime(2027, 3, 25);
const int kViewYear = 2027;
const int kViewMonth = 3; // 1-indexed (March)

/// Events copied verbatim from design `data.jsx` SAMPLE_EVENTS.
final List<Event> sampleEvents = [
  Event(
    id: 'e1',
    date: DateTime(2027, 2, 28),
    kind: EventKind.schedule,
    title: '가계부 마감',
    color: ScheduleColor.mint,
  ),
  Event(
    id: 'e2',
    date: DateTime(2027, 3, 1),
    kind: EventKind.holiday,
    title: '삼일절',
  ),
  Event(
    id: 'e3',
    date: DateTime(2027, 3, 3),
    kind: EventKind.birthday,
    title: '성미 생일',
    emoji: '💙',
  ),
  Event(
    id: 'e4',
    date: DateTime(2027, 3, 3),
    kind: EventKind.photoMemo,
    title: '약 이름 메모',
    photoLabel: '약봉투',
    tone: PhotoTone.note,
    categoryId: 'memo',
  ),
  Event(
    id: 'e5',
    date: DateTime(2027, 3, 6),
    kind: EventKind.holiday,
    title: '경칩',
  ),
  Event(
    id: 'e6',
    date: DateTime(2027, 3, 11),
    kind: EventKind.photoMemo,
    title: '병원 처방전',
    photoLabel: '처방전',
    tone: PhotoTone.receipt,
    categoryId: 'memo',
  ),
  Event(
    id: 'e7',
    date: DateTime(2027, 3, 14),
    kind: EventKind.photoMemo,
    title: '백화점 영수증',
    photoLabel: '영수증',
    tone: PhotoTone.receipt,
    categoryId: 'receipt',
  ),
  Event(
    id: 'e8',
    date: DateTime(2027, 3, 16),
    kind: EventKind.photoMemo,
    title: '병원 진료',
    photoLabel: '진료카드',
    tone: PhotoTone.card,
    remind: true,
    remindAt: '오전 9:00',
    categoryId: 'business_card',
  ),
  Event(
    id: 'e9',
    date: DateTime(2027, 3, 20),
    kind: EventKind.holiday,
    title: '춘분',
  ),
  Event(
    id: 'e10',
    date: DateTime(2027, 3, 21),
    kind: EventKind.schedule,
    title: '삼성카드 결제일',
    color: ScheduleColor.mint,
  ),
  Event(
    id: 'e11',
    date: DateTime(2027, 3, 23),
    kind: EventKind.schedule,
    title: '현대카드 결제일',
    color: ScheduleColor.mint,
  ),
  Event(
    id: 'e12',
    date: DateTime(2027, 3, 25),
    kind: EventKind.photoMemo,
    title: '딸기 한 박스',
    photoLabel: '딸기 박스',
    tone: PhotoTone.product,
    categoryId: 'other',
  ),
  Event(
    id: 'e13',
    date: DateTime(2027, 3, 25),
    kind: EventKind.schedule,
    title: '손주 어린이집 행사',
    color: ScheduleColor.pink,
  ),
  Event(
    id: 'e14',
    date: DateTime(2027, 3, 29),
    kind: EventKind.photoMemo,
    title: '관리비 고지서',
    photoLabel: '고지서',
    tone: PhotoTone.note,
    remind: true,
    remindAt: '오전 10:00',
    categoryId: 'receipt',
  ),
  Event(
    id: 'e15',
    date: DateTime(2027, 3, 31),
    kind: EventKind.schedule,
    title: '가계부 마감',
    color: ScheduleColor.mint,
  ),
];

/// PRD-defined categories. The OpenAI gpt-5.4-nano classifier outputs one of
/// `memo` / `receipt` / `business_card` / `other`; counts here are derived from
/// the sample dataset for now.
const List<CategoryItem> sampleCategories = [
  CategoryItem(id: 'memo', name: '메모', count: 2, colorValue: 0xFFF2C19F),
  CategoryItem(id: 'receipt', name: '영수증', count: 2, colorValue: 0xFFC7E0E2),
  CategoryItem(
      id: 'business_card', name: '명함', count: 1, colorValue: 0xFFD7E3E5),
  CategoryItem(id: 'other', name: '기타', count: 1, colorValue: 0xFFE8E1CF),
];

List<Event> eventsForDate(DateTime d) => sampleEvents
    .where((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
    .toList();

/// All events with reminders, plus all birthdays (per design rule).
List<Event> remindersList() => sampleEvents
    .where((e) => e.remind || e.kind == EventKind.birthday)
    .map((e) => Event(
          id: e.id,
          date: e.date,
          kind: e.kind,
          title: e.title,
          photoLabel: e.photoLabel,
          tone: e.tone,
          color: e.color,
          emoji: e.emoji,
          remind: e.remind,
          remindAt: e.remindAt ?? '오전 8:00',
        ))
    .toList();

List<Event> galleryItems() =>
    sampleEvents.where((e) => e.kind == EventKind.photoMemo).toList();

/// Hand-mocked memo bodies referenced by id (matches design `memoBody` map).
const Map<String, String> memoBodies = {
  'e4': '약 이름 — 타이레놀 ER\n하루 두 번, 식후 30분',
  'e6': '내일 약국 가서 처방받기\n환자번호 챙기기',
  'e7': '다음 주 정산해야 함\n총 47,800원',
  'e8': '진료 예약 확인\n9시 30분 도착',
  'e12': '냉장고 가운데 칸에 있음\n다음 주까지 다 먹기',
  'e14': '관리비 18만 8천원\n26일까지 납부',
};

/// Lunar overlay used by the design — first sunday of each row gets a small label.
/// Indexed by week index in the rendered grid (0..n).
const Map<int, String> lunarFirstSunday = {
  0: '1.22',
  1: '1.29',
  2: '2.7',
  3: '2.14',
  4: '2.21',
};

class CalendarCell {
  final int year;
  final int month; // 1-indexed
  final int day;
  final bool inMonth;
  final int weekIdx;
  final int weekNum;
  final String? lunar;

  const CalendarCell({
    required this.year,
    required this.month,
    required this.day,
    required this.inMonth,
    required this.weekIdx,
    required this.weekNum,
    this.lunar,
  });

  DateTime get date => DateTime(year, month, day);
}

/// Build a 7×N grid for the given (year, month). Month is 1-indexed here.
/// Mirrors `buildMonthCells` in design `data.jsx`.
List<CalendarCell> buildMonthCells(int year, int month) {
  final first = DateTime(year, month, 1);
  // Dart: Monday = 1 .. Sunday = 7. Design uses Sunday = 0.
  final startDay = first.weekday % 7;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final prevMonthDays = DateTime(year, month, 0).day;

  final cells = <CalendarCell>[];

  for (int i = startDay - 1; i >= 0; i--) {
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    cells.add(CalendarCell(
      year: prevYear,
      month: prevMonth,
      day: prevMonthDays - i,
      inMonth: false,
      weekIdx: 0,
      weekNum: 0,
    ));
  }
  for (int d = 1; d <= daysInMonth; d++) {
    cells.add(CalendarCell(
      year: year,
      month: month,
      day: d,
      inMonth: true,
      weekIdx: 0,
      weekNum: 0,
    ));
  }
  while (cells.length % 7 != 0) {
    final last = cells.last;
    final nextDay = last.inMonth ? 1 : last.day + 1;
    final nextMonth = last.inMonth ? (month == 12 ? 1 : month + 1) : last.month;
    final nextYear = last.inMonth && month == 12 ? year + 1 : last.year;
    cells.add(CalendarCell(
      year: nextYear,
      month: nextMonth,
      day: nextDay,
      inMonth: false,
      weekIdx: 0,
      weekNum: 0,
    ));
  }

  // Decorate with weekIdx + weekNum + lunar (only for first sunday of each row).
  return List.generate(cells.length, (i) {
    final c = cells[i];
    final wIdx = i ~/ 7;
    final isFirstSundayOfRow = i % 7 == 0;
    return CalendarCell(
      year: c.year,
      month: c.month,
      day: c.day,
      inMonth: c.inMonth,
      weekIdx: wIdx,
      weekNum: 9 + wIdx,
      lunar: c.inMonth && isFirstSundayOfRow ? lunarFirstSunday[wIdx] : null,
    );
  });
}
