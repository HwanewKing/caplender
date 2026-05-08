import 'package:flutter/material.dart';

import '../../data/sample_data.dart';
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
  int _year = kViewYear;
  int _month = kViewMonth;

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
              constraints: const BoxConstraints(minHeight: 92),
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
  final VoidCallback onTap;
  const _DayCell({
    required this.cell,
    required this.column,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final events = eventsForDate(cell.date);
    final isToday = cell.inMonth &&
        cell.year == kToday.year &&
        cell.month == kToday.month &&
        cell.day == kToday.day;
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
                    if (cell.lunar != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 2, top: 4),
                        child: Text(
                          cell.lunar!,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              for (final ev in events.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: EventChip(event: ev),
                ),
              if (events.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    '+${events.length - 3}',
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
