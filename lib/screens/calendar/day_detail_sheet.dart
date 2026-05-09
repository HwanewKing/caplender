import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../services/memo_store.dart';
import '../../theme/colors.dart';
import '../../utils/date_format.dart';
import '../../widgets/stored_photo.dart';
import '../photo_memo_detail.dart';

/// Bottom sheet shown when tapping a day cell. Lists every event for that
/// day. Adding new memos is handled by the QUICK MEMO speed-dial in the
/// home shell — this sheet is read-only.
class DayDetailSheet extends StatelessWidget {
  final DateTime day;

  const DayDetailSheet({
    super.key,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final events = MemoStoreScope.of(context).eventsForDate(day);
    final weekday = koreanWeekdaySunFirst(day);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.78,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.year}년 ${day.month}월',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${day.day}일',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '$weekday요일',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkResponse(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  physics: const ClampingScrollPhysics(),
                  children: [
                    if (events.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '아직 기록이 없어요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final ev in events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EventCard(ev: ev),
                        ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event ev;
  const _EventCard({required this.ev});

  @override
  Widget build(BuildContext context) {
    switch (ev.kind) {
      case EventKind.photoMemo:
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          shadowColor: const Color(0x0A000000),
          elevation: 1,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              PhotoMemoDetailScreen.route(ev),
            ),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbOrPlaceholder(
                photoPath: ev.photoPath,
                tone: ev.tone ?? PhotoTone.note,
                width: 68,
                height: 68,
                radius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          ev.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        if (ev.remind)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coralSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_outlined,
                                    size: 11,
                                    color: Color(0xFF9C3F3A)),
                                const SizedBox(width: 3),
                                Text(
                                  ev.remindAt ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9C3F3A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (ev.memoBody?.trim().isNotEmpty ?? false)
                          ? ev.memoBody!
                          : ev.title,
                      style: gaeguStyle(
                        size: 17,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
        );
      case EventKind.schedule:
        final pink = ev.color == ScheduleColor.pink;
        final bg = pink ? AppColors.pinkSoft : AppColors.mintSoft;
        final fg = pink ? const Color(0xFF9C3F3A) : const Color(0xFF2C5F62);
        return _SimpleRow(
          leading: Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: ev.title,
          tagText: '일정',
          tagBg: bg,
          tagFg: fg,
        );
      case EventKind.holiday:
        return _SimpleRow(
          leading: const Icon(Icons.wb_sunny_outlined,
              size: 22, color: Color(0xFFC97B3D)),
          title: ev.title,
          tagText: '공휴일',
          tagBg: AppColors.peachSoft,
          tagFg: const Color(0xFF7A4A24),
        );
      case EventKind.birthday:
        return _SimpleRow(
          leading: Text(
            ev.emoji ?? '🎂',
            style: const TextStyle(fontSize: 22),
          ),
          title: ev.title,
          tagText: '기념일',
          tagBg: const Color(0xFFDCE7F4),
          tagFg: const Color(0xFF5C7AA0),
        );
    }
  }
}

/// Renders the actual photo via a signed URL when [photoPath] is provided,
/// otherwise falls back to the tone-based placeholder used by sample data.
class _ThumbOrPlaceholder extends StatelessWidget {
  final String? photoPath;
  final PhotoTone tone;
  final double width;
  final double height;
  final BorderRadius radius;
  const _ThumbOrPlaceholder({
    required this.photoPath,
    required this.tone,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return StoredPhoto(
      photoPath: photoPath,
      tone: tone,
      width: width,
      height: height,
      borderRadius: radius,
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String tagText;
  final Color tagBg;
  final Color tagFg;
  const _SimpleRow({
    required this.leading,
    required this.title,
    required this.tagText,
    required this.tagBg,
    required this.tagFg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tagText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tagFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
