import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/memo_store.dart';
import '../theme/colors.dart';
import '../utils/date_format.dart';
import '../widgets/memo_form_fields.dart';

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
    if (_remind && _remindAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 시각이 이미 지났어요. 다시 선택해주세요.')),
      );
      return;
    }
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
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left,
                            size: 20, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text(
                          '취소',
                          style:
                              TextStyle(color: AppColors.ink, fontSize: 16),
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
}
