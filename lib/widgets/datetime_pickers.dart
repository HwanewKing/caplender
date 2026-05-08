import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Two side-by-side pill buttons that open the system date and time pickers.
/// Used by the QuickPhoto memo entry view and the photo memo edit screen so
/// the user can pin the reminder to any year/month/day/hour/minute they want.
class DateTimePickers extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const DateTimePickers({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value.isBefore(now) ? now : value,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: '알림 날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked == null) return;
    onChanged(DateTime(
      picked.year,
      picked.month,
      picked.day,
      value.hour,
      value.minute,
    ));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      helpText: '알림 시간 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked == null) return;
    onChanged(DateTime(
      value.year,
      value.month,
      value.day,
      picked.hour,
      picked.minute,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _PillButton(
            icon: Icons.calendar_today_outlined,
            label: formatDateLabel(value),
            onTap: () => _pickDate(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _PillButton(
            icon: Icons.access_time,
            label: formatTimeOnly(value),
            onTap: () => _pickTime(context),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
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

String formatDateLabel(DateTime t) {
  const wd = ['월', '화', '수', '목', '금', '토', '일'];
  return '${t.year}년 ${t.month}월 ${t.day}일 (${wd[t.weekday - 1]})';
}

String formatTimeOnly(DateTime t) {
  final h12 = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
  final ampm = t.hour < 12 ? '오전' : '오후';
  return '$ampm $h12:${t.minute.toString().padLeft(2, '0')}';
}

/// Friendly summary used in the toggle subtitle: "오늘 오전 9:00",
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
