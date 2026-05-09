import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../services/memo_store.dart';
import '../../theme/colors.dart';
import '../../widgets/stored_photo.dart';
import '../photo_memo_detail.dart';

/// When the alarm actually fires:
/// - photoMemo with a real `remindAtTime` → use that timestamp.
/// - sample photoMemo / birthday without one → fall back to that day's 8 AM.
DateTime _reminderMoment(Event r) {
  if (r.remindAtTime != null) return r.remindAtTime!;
  return DateTime(r.date.year, r.date.month, r.date.day, 8, 0);
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final all = MemoStoreScope.of(context).remindersList();
    final now = DateTime.now();
    bool isPast(Event r) => _reminderMoment(r).isBefore(now);
    final upcoming = all.where((r) => !isPast(r)).toList()
      ..sort((a, b) => _reminderMoment(a).compareTo(_reminderMoment(b)));
    final past = all.where(isPast).toList()
      ..sort((a, b) => _reminderMoment(b).compareTo(_reminderMoment(a)));
    final nextLabel = upcoming.isEmpty
        ? '예정된 알림이 없어요'
        : () {
            final m = _reminderMoment(upcoming.first);
            return '가장 가까운 알림: ${m.month}월 ${m.day}일';
          }();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '잊지 않게',
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
              SizedBox(height: 2),
              Text(
                '리마인더',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.coralSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '예정된 알림 ${upcoming.length}개',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _Section(title: '예정', items: upcoming, past: false),
        _Section(title: '지난 알림', items: past, past: true),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Event> items;
  final bool past;
  const _Section({required this.title, required this.items, required this.past});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          ...items.map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: _ReminderRow(r: r, past: past),
              )),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Event r;
  final bool past;
  const _ReminderRow({required this.r, required this.past});

  @override
  Widget build(BuildContext context) {
    final moment = _reminderMoment(r);
    final tappable = r.kind == EventKind.photoMemo;
    return Opacity(
      opacity: past ? 0.55 : 1,
      child: Material(
        color: Colors.white,
        // Use `shape` (which carries its own borderRadius) so we can also
        // paint the soft border in one go — Material rejects the
        // borderRadius+shape combo.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        child: InkWell(
          onTap: tappable
              ? () => Navigator.of(context).push(
                    PhotoMemoDetailScreen.route(r),
                  )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
          children: [
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: r.kind == EventKind.birthday
                    ? const Color(0xFFDCE7F4)
                    : AppColors.coralSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${moment.month}월',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: r.kind == EventKind.birthday
                          ? const Color(0xFF3D5C8A)
                          : const Color(0xFF9C3F3A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${moment.day}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: r.kind == EventKind.birthday
                          ? const Color(0xFF3D5C8A)
                          : const Color(0xFF9C3F3A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (r.kind == EventKind.photoMemo)
              StoredPhoto(
                photoPath: r.photoPath,
                tone: r.tone ?? toneForCategory(r.categoryId),
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(10),
              )
            else if (r.kind == EventKind.birthday)
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE7F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.emoji ?? '🎂',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        r.remindAt ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tappable
                    ? AppColors.coralSoft
                    : const Color(0xFFF4EFE3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: tappable
                    ? const Color(0xFF9C3F3A)
                    : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
