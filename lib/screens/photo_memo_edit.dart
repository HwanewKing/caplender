import 'package:flutter/material.dart';

import '../app.dart';
import '../data/categories.dart';
import '../data/models.dart';
import '../services/memo_repository.dart';
import '../services/memo_store.dart';
import '../theme/colors.dart';
import '../widgets/app_toggle.dart';
import '../widgets/datetime_pickers.dart';

/// In-place edit for an existing photo memo. Mirrors the QuickPhoto memo
/// entry form but pre-populated and without the photo upload step.
class PhotoMemoEditScreen extends StatefulWidget {
  final Event event;
  const PhotoMemoEditScreen({super.key, required this.event});

  static Route<bool> route(Event event) {
    return MaterialPageRoute<bool>(
      builder: (_) => PhotoMemoEditScreen(event: event),
    );
  }

  @override
  State<PhotoMemoEditScreen> createState() => _PhotoMemoEditScreenState();
}

class _PhotoMemoEditScreenState extends State<PhotoMemoEditScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  late String _category;
  late bool _remind;
  // Inline default so hot reload (which skips initState on existing
  // states) doesn't trip a LateInitializationError. The real value lands
  // in initState below.
  DateTime _remindAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _activePreset;
  bool _saving = false;

  static const _remindPresets = ['1시간 후', '내일 오전 9:00', '3일 뒤', '1주일 뒤'];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.event.title);
    _memoCtrl = TextEditingController(text: widget.event.memoBody ?? '');
    _category = widget.event.categoryId ?? 'memo';
    _remind = widget.event.remind;
    _remindAt = widget.event.remindAtTime ?? parseRemindPreset('내일 오전 9:00');
    _activePreset = widget.event.remindAtTime == null ? '내일 오전 9:00' : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await MemoStoreScope.of(context).updatePhotoMemo(
        id: widget.event.id,
        title: _titleCtrl.text.trim(),
        memo: _memoCtrl.text.trim(),
        categoryId: _category,
        remind: _remind,
        remindAt: _remind ? _remindAt : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left,
                            size: 20, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text(
                          '취소',
                          style: TextStyle(
                              color: AppColors.ink, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '메모 수정',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 64),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                children: [
                  _Field(
                    label: '제목',
                    child: TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration(),
                    ),
                  ),
                  _Field(
                    label: '메모',
                    child: TextField(
                      controller: _memoCtrl,
                      maxLines: 5,
                      minLines: 3,
                      style: gaeguStyle(size: 17),
                      decoration: _inputDecoration(
                        hint: '이 사진에 대해 기억하고 싶은 것을 적어주세요',
                      ),
                    ),
                  ),
                  _Field(
                    label: '분류',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in appCategories)
                          GestureDetector(
                            onTap: () => setState(() => _category = c.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _category == c.id
                                    ? Colors.white
                                    : const Color(0xFFFCFAF4),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _category == c.id
                                      ? AppColors.teal
                                      : AppColors.border,
                                  width: _category == c.id ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(c.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _category == c.id
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _category == c.id
                                          ? AppColors.teal
                                          : AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(top: 6),
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.coralSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.coral,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '잊지 않게 알려주기',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _remind
                                        ? '${formatRemindLabel(_remindAt)}에 알림'
                                        : '알림이 꺼져 있어요',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppToggle(
                              value: _remind,
                              onChanged: (v) =>
                                  setState(() => _remind = v),
                            ),
                          ],
                        ),
                        if (_remind) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(left: 52),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final w in _remindPresets)
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _remindAt = parseRemindPreset(w);
                                      _activePreset = w;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _activePreset == w
                                            ? AppColors.coralSoft
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _activePreset == w
                                              ? AppColors.coral
                                              : AppColors.border,
                                          width:
                                              _activePreset == w ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        w,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _activePreset == w
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _activePreset == w
                                              ? const Color(0xFF9C3F3A)
                                              : AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 52),
                            child: DateTimePickers(
                              value: _remindAt,
                              onChanged: (next) => setState(() {
                                _remindAt = next;
                                _activePreset = null;
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderSoft, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shadowColor: AppColors.teal.withValues(alpha: 0.32),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 20),
                            SizedBox(width: 6),
                            Text(
                              '수정 저장',
                              style: TextStyle(
                                fontSize: 17,
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
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.inkMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

