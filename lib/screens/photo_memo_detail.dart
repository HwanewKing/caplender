import 'package:flutter/material.dart';

import '../app.dart';
import '../data/categories.dart';
import '../data/models.dart';
import '../services/memo_store.dart';
import '../theme/colors.dart';
import '../widgets/datetime_pickers.dart';
import '../widgets/photo_tile.dart';
import 'photo_memo_edit.dart';

/// Read-only detail view for a single photo memo. Reachable from a tap on
/// a photoMemo card in the gallery, the calendar's day-detail sheet, or
/// the reminders list.
///
/// Re-reads its event from [MemoStore] on every build, so an edit made via
/// [PhotoMemoEditScreen] reflects immediately and a delete causes the
/// screen to dismiss itself.
class PhotoMemoDetailScreen extends StatefulWidget {
  final Event event;
  const PhotoMemoDetailScreen({super.key, required this.event});

  static Route<void> route(Event event) {
    return MaterialPageRoute(
      builder: (_) => PhotoMemoDetailScreen(event: event),
    );
  }

  @override
  State<PhotoMemoDetailScreen> createState() => _PhotoMemoDetailScreenState();
}

class _PhotoMemoDetailScreenState extends State<PhotoMemoDetailScreen> {
  /// Whether this event was originally backed by the DB. We capture this
  /// once so that a later "store says it's gone" reliably means *deleted*
  /// rather than "was never in the store" (which is true for sample data).
  bool? _wasDbEvent;
  bool _deleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wasDbEvent ??=
        MemoStoreScope.of(context).findById(widget.event.id) != null;
  }

  Future<void> _onEdit(Event ev) async {
    await Navigator.of(context).push(PhotoMemoEditScreen.route(ev));
    // Store has already been refreshed inside the edit screen on save.
    // The next build will pick up the fresh event.
  }

  Future<void> _onDelete(Event ev) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('이 메모를 삭제할까요?'),
        content: const Text(
          '삭제하면 사진과 메모를 다시 볼 수 없어요.',
          style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제',
                style: TextStyle(
                  color: Color(0xFF9C3F3A),
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await MemoStoreScope.of(context).deletePhotoMemo(
        id: ev.id,
        photoPath: ev.photoPath,
      );
      // The next build will see findById return null and pop, but in
      // practice we beat it to the punch so the user gets immediate
      // feedback rather than seeing the spinner blink.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MemoStoreScope.of(context);
    final fresh = store.findById(widget.event.id);

    // The event was a DB event but is no longer in the store → it was
    // deleted (probably by us). Pop after this frame.
    if ((_wasDbEvent ?? false) && fresh == null && !_deleting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: AppColors.cream);
    }

    final ev = fresh ?? widget.event;
    final cat = appCategories.firstWhere(
      (c) => c.id == (ev.categoryId ?? 'memo'),
      orElse: () => appCategories.first,
    );
    final body = (ev.memoBody?.trim().isNotEmpty ?? false)
        ? ev.memoBody!.trim()
        : '';
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][ev.date.weekday % 7];
    final dateLabel =
        '${ev.date.year}년 ${ev.date.month}월 ${ev.date.day}일 ($weekday)';
    final canEditOrDelete = (_wasDbEvent ?? false) && !_deleting;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: _PhotoView(
                      photoPath: ev.photoPath,
                      tone: ev.tone ?? PhotoTone.note,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryChip(category: cat),
                        const SizedBox(height: 10),
                        Text(
                          ev.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppColors.inkMuted),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (body.isNotEmpty)
                    _Section(
                      label: '메모',
                      child: Text(
                        body,
                        style: gaeguStyle(
                          size: 18,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  if (ev.ocrText?.trim().isNotEmpty ?? false)
                    _Section(
                      label: '자동 인식',
                      iconLeading: const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppColors.teal,
                      ),
                      child: Text(
                        ev.ocrText!.trim(),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  _Section(
                    label: '알림',
                    iconLeading: const Icon(
                      Icons.notifications_outlined,
                      size: 14,
                      color: AppColors.coral,
                    ),
                    child: Text(
                      ev.remind
                          ? (ev.remindAtTime != null
                              ? formatRemindLabel(ev.remindAtTime!)
                              : (ev.remindAt ?? '오전 9:00'))
                          : '알림이 꺼져 있어요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ev.remind
                            ? AppColors.ink
                            : AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (canEditOrDelete)
              _ActionBar(
                onEdit: () => _onEdit(ev),
                onDelete: () => _onDelete(ev),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.chevron_left, color: AppColors.ink),
            iconSize: 28,
          ),
          const Spacer(),
          const Text(
            '메모 상세',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PhotoView extends StatelessWidget {
  final String? photoPath;
  final PhotoTone tone;
  const _PhotoView({required this.photoPath, required this.tone});

  @override
  Widget build(BuildContext context) {
    final placeholder = AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PhotoTile(
          tone: tone,
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.zero,
          elevated: false,
        ),
      ),
    );
    if (photoPath == null) return placeholder;
    final store = MemoStoreScope.of(context);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FutureBuilder<String>(
          future: store.signedUrlFor(photoPath!),
          builder: (context, snap) {
            if (!snap.hasData) {
              return PhotoTile(
                tone: tone,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
                elevated: false,
              );
            }
            return Image.network(
              snap.data!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => PhotoTile(
                tone: tone,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
                elevated: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryItem category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(category.colorValue).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(category.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}


class _Section extends StatelessWidget {
  final String label;
  final Widget? iconLeading;
  final Widget child;
  const _Section({required this.label, required this.child, this.iconLeading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (iconLeading != null) ...[
                  iconLeading!,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ActionBar({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9C3F3A),
                  side: const BorderSide(color: Color(0x66C45A52)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '삭제',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '수정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
