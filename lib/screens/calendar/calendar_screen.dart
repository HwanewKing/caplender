import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../services/memo_store.dart';
import '../../theme/colors.dart';
import '../../widgets/event_chip.dart';

/// Month grid matching the design's wireframe — week column on the left,
/// today highlighted with a teal pill, max 3 chips per cell + overflow `+N`.
class CalendarScreen extends StatefulWidget {
  final ValueChanged<DateTime> onDayTap;
  const CalendarScreen({super.key, required this.onDayTap});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  void _prev() {
    setState(() {
      if (_month == 1) {
        _year -= 1;
        _month = 12;
      } else {
        _month -= 1;
      }
    });
  }

  void _next() {
    setState(() {
      if (_month == 12) {
        _year += 1;
        _month = 1;
      } else {
        _month += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cells = buildMonthCells(_year, _month);
    final weeks = <List<CalendarCell>>[];
    for (int i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      children: [
        _Header(year: _year, month: _month, onPrev: _prev, onNext: _next),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: const _WeekHeader(),
        ),
        ...weeks.asMap().entries.map((entry) {
          final wi = entry.key;
          final week = entry.value;
          final isLast = wi == weeks.length - 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom:
                            BorderSide(color: AppColors.borderSoft, width: 1),
                      ),
              ),
              constraints: const BoxConstraints(minHeight: 124),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, right: 4),
                        child: Text(
                          '${week.first.weekNum}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ),
                    ),
                    for (int ci = 0; ci < week.length; ci++)
                      Expanded(
                        child: _DayCell(
                          cell: week[ci],
                          column: ci,
                          captures: MemoStoreScope.of(context)
                              .capturesOnDate(week[ci].date),
                          reminders: MemoStoreScope.of(context)
                              .remindersOnDate(week[ci].date),
                          onTap: () => widget.onDayTap(week[ci].date),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _Header({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
      child: Row(
        children: [
          _IconBtn(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$year년',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$month월',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          _IconBtn(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: AppColors.ink),
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: i == 0
                      ? AppColors.sun
                      : i == 6
                          ? AppColors.sat
                          : AppColors.inkSoft,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final CalendarCell cell;
  final int column;
  final List<Event> captures;
  final List<Event> reminders;
  final VoidCallback onTap;
  const _DayCell({
    required this.cell,
    required this.column,
    required this.captures,
    required this.reminders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = cell.inMonth &&
        cell.year == today.year &&
        cell.month == today.month &&
        cell.day == today.day;
    final dayColor = column == 0
        ? AppColors.sun
        : column == 6
            ? AppColors.sat
            : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: cell.inMonth ? 1 : 0.35,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 6, 3, 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isToday)
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cell.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 2),
                        child: Text(
                          '${cell.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: dayColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              if (captures.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      for (final ev in captures.take(4))
                        EventChip(event: ev),
                    ],
                  ),
                ),
              for (final ev in reminders.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: EventChip(event: ev, reminderView: true),
                ),
              if (captures.length > 4 || reminders.length > 2)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    '+${(captures.length - 4).clamp(0, captures.length) + (reminders.length - 2).clamp(0, reminders.length)}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One cell in the month grid. `inMonth` is false for the leading/trailing
/// padding cells from the previous and next months, so the screen can
/// render them dimmed.
class CalendarCell {
  final int year;
  final int month; // 1-indexed
  final int day;
  final bool inMonth;
  final int weekIdx;
  final int weekNum;

  const CalendarCell({
    required this.year,
    required this.month,
    required this.day,
    required this.inMonth,
    required this.weekIdx,
    required this.weekNum,
  });

  DateTime get date => DateTime(year, month, day);
}

/// Build a 7×N grid for the given (year, month). Leading days come from the
/// previous month and trailing days from the next month, so every row has
/// exactly 7 cells.
List<CalendarCell> buildMonthCells(int year, int month) {
  final first = DateTime(year, month, 1);
  // Dart: Monday = 1 .. Sunday = 7. Calendar header is Sunday-first.
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

  return List.generate(cells.length, (i) {
    final c = cells[i];
    final wIdx = i ~/ 7;
    return CalendarCell(
      year: c.year,
      month: c.month,
      day: c.day,
      inMonth: c.inMonth,
      weekIdx: wIdx,
      weekNum: 9 + wIdx,
    );
  });
}
