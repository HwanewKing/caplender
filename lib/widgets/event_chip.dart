import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/colors.dart';
import 'photo_tile.dart';

/// One chip rendered inside a calendar day cell. Mirrors the design's
/// EventChip — colour and content depend on the event kind.
class EventChip extends StatelessWidget {
  final Event event;
  const EventChip({super.key, required this.event});

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
        final reminding = event.remind;
        return Container(
          decoration: BoxDecoration(
            color: reminding ? AppColors.pinkSoft : const Color(0xFFEEE8DA),
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhotoTile(
                tone: event.tone ?? PhotoTone.note,
                width: 14,
                height: 14,
                borderRadius: BorderRadius.circular(2),
                elevated: false,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  reminding ? '리마인드' : event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: reminding
                        ? const Color(0xFF9C3F3A)
                        : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        );
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
