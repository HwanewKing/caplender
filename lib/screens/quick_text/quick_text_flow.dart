import 'package:flutter/material.dart';

import '../../services/memo_repository.dart';
import '../../services/memo_store.dart';
import '../../theme/colors.dart';
import '../../utils/date_format.dart';
import '../../widgets/memo_form_fields.dart';

enum _Step { memo, done }

/// Text-only memo flow. Mirrors QuickPhotoFlow's memo-entry step but skips
/// the camera/upload/classify pipeline — `photo_path` ends up null in the
/// row and the gallery / calendar / reminders fall back to the tone-based
/// placeholder tile.
class QuickTextFlow extends StatefulWidget {
  const QuickTextFlow({super.key});

  @override
  State<QuickTextFlow> createState() => _QuickTextFlowState();
}

class _QuickTextFlowState extends State<QuickTextFlow> {
  _Step _step = _Step.memo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      child: switch (_step) {
        _Step.memo => _MemoEntryView(
            onSaved: () => setState(() => _step = _Step.done),
            onClose: () => Navigator.of(context).pop(),
          ),
        _Step.done => _SavedView(
            onClose: () => Navigator.of(context).pop(),
          ),
      },
    );
  }
}

class _MemoEntryView extends StatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onClose;
  const _MemoEntryView({required this.onSaved, required this.onClose});

  @override
  State<_MemoEntryView> createState() => _MemoEntryViewState();
}

class _MemoEntryViewState extends State<_MemoEntryView> {
  final MemoRepository _repo = MemoRepository();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _memoCtrl = TextEditingController();
  String _category = 'memo';
  bool _remind = false;
  // Inline default so hot reload doesn't trip LateInitializationError on
  // an existing state instance — initState replaces it with the real value.
  DateTime _remindAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _activePreset;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _remindAt = parseRemindPreset('내일 오전 9:00');
    _activePreset = '내일 오전 9:00';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_saving) return;
    if (_remind && _remindAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 시각이 이미 지났어요. 다시 선택해주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.createMemo(
        title: _titleCtrl.text.trim(),
        memo: _memoCtrl.text.trim(),
        categoryId: _category,
        memoDate: DateTime.now(),
        remind: _remind,
        remindAt: _remind ? _remindAt : null,
      );
      if (!mounted) return;
      await MemoStoreScope.of(context).refresh();
      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : widget.onClose,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left,
                          size: 20, color: AppColors.ink),
                      SizedBox(width: 4),
                      Text(
                        '취소',
                        style: TextStyle(color: AppColors.ink, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  '메모 작성',
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
                MemoFormFields(
                  titleCtrl: _titleCtrl,
                  memoCtrl: _memoCtrl,
                  category: _category,
                  onCategoryChanged: (v) => setState(() => _category = v),
                  remind: _remind,
                  onRemindChanged: (v) => setState(() => _remind = v),
                  remindAt: _remindAt,
                  onRemindAtChanged: (v) => setState(() => _remindAt = v),
                  activePreset: _activePreset,
                  onActivePresetChanged: (v) =>
                      setState(() => _activePreset = v),
                  memoHint: '기억하고 싶은 것을 적어주세요',
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
                onPressed: _saving ? null : _onSave,
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
                            '저장하기',
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
    );
  }
}

class _SavedView extends StatefulWidget {
  final VoidCallback onClose;
  const _SavedView({required this.onClose});

  @override
  State<_SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<_SavedView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CheckCircle(),
          SizedBox(height: 18),
          Text(
            '저장했어요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '갤러리와 캘린더에서 확인할 수 있어요',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.teal,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 42, color: Colors.white),
    );
  }
}
