import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/colors.dart';
import 'stored_photo.dart';

/// One chip rendered inside a calendar day cell. For photoMemo events the
/// caller picks a view: `capture` (just the photo thumbnail, no border)
/// when the cell's date is the memo's capture day, or `reminder` (bell
/// emoji + title) when the cell's date is the memo's reminder day.
class EventChip extends StatelessWidget {
  final Event event;
  final bool reminderView;
  const EventChip({
    super.key,
    required this.event,
    this.reminderView = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (event.kind) {
      case EventKind.holiday:
        return _box(
          color: AppColors.peachSoft,
          textColor: const Color(0xFF7A4A24),
          text: event.title,
        );
      case EventKind.birthday:
        return _box(
          color: Colors.transparent,
          textColor: AppColors.ink,
          text: '${event.emoji ?? ''} ${event.title}',
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      case EventKind.schedule:
        final pink = event.color == ScheduleColor.pink;
        return _box(
          color: pink ? AppColors.pinkSoft : AppColors.mintSoft,
          textColor: pink ? const Color(0xFF9C3F3A) : const Color(0xFF2C5F62),
          text: event.title,
        );
      case EventKind.photoMemo:
        return reminderView
            ? _ReminderBellChip(event: event)
            : _CaptureThumb(event: event);
    }
  }

  Widget _box({
    required Color color,
    required Color textColor,
    required String text,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: padding,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

/// Capture-day view — just the photo thumbnail, no decoration. Falls back
/// to the tone-based placeholder when no path is set or while the signed
/// URL is being fetched.
class _CaptureThumb extends StatelessWidget {
  final Event event;
  const _CaptureThumb({required this.event});

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    return StoredPhoto(
      photoPath: event.photoPath,
      tone: event.tone ?? PhotoTone.note,
      width: _size,
      height: _size,
      borderRadius: BorderRadius.circular(4),
    );
  }
}

/// Reminder-day view — bell emoji + memo title on a soft coral pill. No
/// photo: the user already saw the photo on the capture day.
class _ReminderBellChip extends StatelessWidget {
  final Event event;
  const _ReminderBellChip({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9C3F3A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
