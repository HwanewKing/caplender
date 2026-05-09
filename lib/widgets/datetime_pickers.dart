import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../utils/date_format.dart';

/// Two side-by-side pill buttons that open the system date and time pickers.
/// Used by the memo entry / edit forms so the user can pin the reminder to
/// any year/month/day/hour/minute they want.
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
