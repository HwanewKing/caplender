import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/models.dart';
import '../../data/sample_data.dart';
import '../../theme/colors.dart';
import '../../widgets/photo_tile.dart';

/// Bottom sheet shown when tapping a day cell. Lists every event for that day
/// with mocked handwritten memo bodies, plus two action buttons in the footer.
class DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final VoidCallback onAddPhoto;

  const DayDetailSheet({
    super.key,
    required this.day,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final events = eventsForDate(day);
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][day.weekday % 7];

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
                        child: const Column(
                          children: [
                            Text(
                              '아직 기록이 없어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.inkMuted,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '아래 버튼으로 추가해 보세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ],
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
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSoft, width: 1),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  22 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FooterBtn(
                        icon: Icons.camera_alt_outlined,
                        label: '사진으로 기록',
                        background: AppColors.coral,
                        foreground: Colors.white,
                        onTap: onAddPhoto,
                        shadow: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FooterBtn(
                        icon: Icons.add,
                        label: '일정 추가',
                        background: Colors.white,
                        foreground: AppColors.ink,
                        bordered: true,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool shadow;
  final bool bordered;

  const _FooterBtn({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.shadow = false,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: bordered
                ? Border.all(color: AppColors.border, width: 1)
                : null,
            boxShadow: shadow
                ? const [
                    BoxShadow(
                      color: Color(0x52F57E58),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
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
        return Container(
          padding: const EdgeInsets.all(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoTile(
                tone: ev.tone ?? PhotoTone.note,
                width: 68,
                height: 68,
                borderRadius: BorderRadius.circular(10),
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
                      memoBodies[ev.id] ?? ev.title,
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
