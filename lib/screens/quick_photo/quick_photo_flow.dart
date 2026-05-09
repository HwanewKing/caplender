import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../data/categories.dart';
import '../../services/memo_repository.dart';
import '../../services/memo_store.dart';
import '../../services/photo_capture_service.dart';
import '../../theme/app_settings.dart';
import '../../theme/colors.dart';
import '../../utils/date_format.dart';
import '../../widgets/memo_form_fields.dart';
import '../../widgets/photo_tile.dart';

enum _Step { camera, memo, done }

/// Photo memo flow. Step 1 is the guidance / shutter screen; tapping the
/// shutter (or gallery) hands off to the system picker. Step 2 lands in
/// the memo entry form straight after capture — there's no separate review
/// step, since the OS camera UI already lets the user retake.
class QuickPhotoFlow extends StatefulWidget {
  const QuickPhotoFlow({super.key});

  @override
  State<QuickPhotoFlow> createState() => _QuickPhotoFlowState();
}

class _QuickPhotoFlowState extends State<QuickPhotoFlow> {
  _Step _step = _Step.camera;
  CapturedPhoto? _photo;

  void _onCaptured(CapturedPhoto p) {
    setState(() {
      _photo = p;
      _step = _Step.memo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _step == _Step.camera
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Material(
        color: _step == _Step.camera
            ? const Color(0xFF0A0A0A)
            : AppColors.cream,
        child: switch (_step) {
          _Step.camera => _CameraView(
              onCapture: _onCaptured,
              onClose: () => Navigator.of(context).pop(),
            ),
          _Step.memo => _MemoEntryView(
              photo: _photo!,
              autoOcrEnabled: settings.autoOcrEnabled,
              autoCategorize: settings.autoCategorize,
              onSaved: () => setState(() => _step = _Step.done),
              onClose: () => Navigator.of(context).pop(),
            ),
          _Step.done => _SavedView(
              onClose: () => Navigator.of(context).pop(),
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Step 1 — camera entry. Mock viewfinder is the entry point; tapping the big
// shutter or the gallery button hands off to the system picker.
// ─────────────────────────────────────────────────────────────

class _CameraView extends StatefulWidget {
  final ValueChanged<CapturedPhoto> onCapture;
  final VoidCallback onClose;
  const _CameraView({required this.onCapture, required this.onClose});

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  final PhotoCaptureService _capture = PhotoCaptureService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onShutter() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final p = await _capture.captureFromCamera();
      if (p != null && mounted) widget.onCapture(p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 열기 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final p = await _capture.pickFromGallery();
      if (p != null && mounted) widget.onCapture(p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 선택 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(Icons.close, widget.onClose),
                  const SizedBox(width: 38, height: 38),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Color(0xFF2A2620),
                            Color(0xFF3D352B),
                            Color(0xFF1F1B16),
                          ],
                          stops: const [0, 0.5, 1],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Transform.rotate(
                      angle: -0.05,
                      child: Container(
                        width: 220,
                        height: 270,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8D6),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80000000),
                              blurRadius: 60,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: DefaultTextStyle(
                          style: gaeguStyle(
                            size: 17,
                            color: const Color(0xFF2F2A22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '여기를 눌러 촬영',
                                style: gaeguStyle(
                                  size: 19,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF2F2A22),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('영수증, 메모, 명함을'),
                              const Text('사진으로 찍어보세요'),
                              const SizedBox(height: 8),
                              const Text('자동으로 분류해 드려요'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: CustomPaint(painter: _FrameGuidePainter()),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '글씨를 자동으로 읽어드려요',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_busy)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x80000000),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: Colors.black,
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, 36 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _squareBtn(Icons.photo_outlined, _onGallery),
                      _ShutterButton(
                        pulseAnim: _pulse,
                        onTap: _onShutter,
                      ),
                      const SizedBox(width: 56, height: 56),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '기록할 것을 화면 안에 두고 큰 버튼을 눌러주세요',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0x26FFFFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _squareBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  const _ShutterButton({required this.pulseAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, _) {
                final t = pulseAnim.value;
                final scale = 0.95 + 0.45 * t;
                final opacity = (0.7 - 0.7 * t).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.coral, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral,
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dashed = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dash = 6.0;
    const gap = 4.0;
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)));
    final dashedPath = _dash(path, dash, gap);
    canvas.drawPath(dashedPath, dashed);

    const armLen = 24.0;
    final corner = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(const Offset(-2, -2), const Offset(armLen, -2), corner);
    canvas.drawLine(const Offset(-2, -2), const Offset(-2, armLen), corner);
    canvas.drawLine(Offset(w + 2, -2), Offset(w - armLen, -2), corner);
    canvas.drawLine(Offset(w + 2, -2), Offset(w + 2, armLen), corner);
    canvas.drawLine(Offset(-2, h + 2), Offset(armLen, h + 2), corner);
    canvas.drawLine(Offset(-2, h + 2), Offset(-2, h - armLen), corner);
    canvas.drawLine(Offset(w + 2, h + 2), Offset(w - armLen, h + 2), corner);
    canvas.drawLine(Offset(w + 2, h + 2), Offset(w + 2, h - armLen), corner);
  }

  Path _dash(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = math.min(dist + dash, metric.length);
        out.addPath(metric.extractPath(dist, next), Offset.zero);
        dist = next + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Step 2 — memo entry. On entry: upload to Storage + classify via Edge Fn.
// On save: insert photo_memos row.
// ─────────────────────────────────────────────────────────────

class _MemoEntryView extends StatefulWidget {
  final CapturedPhoto photo;
  final bool autoOcrEnabled;
  final bool autoCategorize;
  final VoidCallback onSaved;
  final VoidCallback onClose;
  const _MemoEntryView({
    required this.photo,
    required this.autoOcrEnabled,
    required this.autoCategorize,
    required this.onSaved,
    required this.onClose,
  });

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

  bool _processing = true;
  String? _photoPath;
  ClassificationResult? _classification;
  String? _processingError;
  bool _saving = false;
  bool _saved = false;
  bool _uploadReleased = false;

  bool get _shouldClassify => widget.autoOcrEnabled || widget.autoCategorize;
  bool get _canSave => !_saving && !_processing && _photoPath != null;

  @override
  void initState() {
    super.initState();
    _remindAt = parseRemindPreset('내일 오전 9:00');
    _activePreset = '내일 오전 9:00';
    _process();
  }

  Future<void> _process() async {
    try {
      final path = await _repo.uploadPhoto(
        bytes: widget.photo.bytes,
        mimeType: widget.photo.mimeType,
        extension: widget.photo.extension,
      );
      if (!mounted) {
        await _releaseUploadPath(path);
        return;
      }
      setState(() => _photoPath = path);

      if (!_shouldClassify) {
        setState(() => _processing = false);
        return;
      }

      final c = await _repo.classifyPhoto(path);
      if (!mounted) {
        await _releaseUploadPath(path);
        return;
      }
      // Defense in depth: if the classifier returns a category that isn't
      // one of our four buckets, fall back to "other" rather than letting an
      // unknown id flow into the DB.
      final allowed = appCategories.map((c) => c.id).toSet();
      final resolvedCat = allowed.contains(c.category) ? c.category : 'other';
      setState(() {
        _classification = c;
        if (widget.autoCategorize) {
          _category = resolvedCat;
        }
        if (widget.autoCategorize && _titleCtrl.text.isEmpty) {
          _titleCtrl.text = _defaultTitle(resolvedCat);
        }
        if (widget.autoOcrEnabled && _memoCtrl.text.isEmpty) {
          _memoCtrl.text = c.content;
        }
        _processing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processingError = e.toString();
        _processing = false;
      });
    }
  }

  String _defaultTitle(String catId) {
    switch (catId) {
      case 'memo':
        return '메모';
      case 'receipt':
        return '영수증';
      case 'business_card':
        return '명함';
      default:
        return '';
    }
  }

  Future<void> _onSave() async {
    if (!_canSave) return;
    if (_remind && _remindAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 시각이 이미 지났어요. 다시 선택해주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.createMemo(
        photoPath: _photoPath!,
        title: _titleCtrl.text.trim(),
        memo: _memoCtrl.text.trim(),
        categoryId: _category,
        memoDate: widget.photo.capturedAt,
        ocrText: widget.autoOcrEnabled ? _classification?.content : null,
        classificationReason:
            widget.autoCategorize ? _classification?.reason : null,
        remind: _remind,
        remindAt: _remind ? _remindAt : null,
      );
      _saved = true;
      if (!mounted) return;
      // Pull the new row into the in-memory store so the calendar /
      // gallery / reminders rebuild before the "saved" view is dismissed.
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

  Future<void> _releaseUploadPath(String path) async {
    if (_saved || _uploadReleased) return;
    _uploadReleased = true;
    try {
      await _repo.deletePhotoUpload(path);
    } catch (e) {
      // Best-effort — orphaned uploads can be cleaned up by a server job.
      debugPrint('[caplender] temp upload cleanup failed for $path: $e');
    }
  }

  Future<void> _cleanupPendingUpload() async {
    final path = _photoPath;
    if (path == null) return;
    await _releaseUploadPath(path);
  }

  Future<void> _handleClose() async {
    await _cleanupPendingUpload();
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    unawaited(_cleanupPendingUpload());
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving) return;
        // Capture the navigator before awaiting so we don't reach back into
        // a stale BuildContext after the cleanup completes.
        final navigator = Navigator.of(context);
        await _cleanupPendingUpload();
        if (!mounted) return;
        navigator.pop();
      },
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 16),
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
                  TextButton(
                    onPressed: _saving ? null : _handleClose,
                    child: const Text(
                      '닫기',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 15),
                    ),
                  ),
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
                    leading: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhotoTile(
                          bytes: widget.photo.bytes,
                          width: 84,
                          height: 84,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AutoDetectStatus(
                            processing: _processing,
                            error: _processingError,
                            classification: _classification,
                          ),
                        ),
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
                  onPressed: _canSave ? _onSave : null,
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
      ),
    );
  }
}

class _AutoDetectStatus extends StatelessWidget {
  final bool processing;
  final String? error;
  final ClassificationResult? classification;
  const _AutoDetectStatus({
    required this.processing,
    required this.error,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    if (processing) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                color: AppColors.teal, strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '글씨를 읽는 중이에요…',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    }
    if (error != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFF9C3F3A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '자동 인식에 실패했어요. 직접 입력해주세요.\n($error)',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9C3F3A),
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }
    final c = classification;
    if (c == null) return const SizedBox.shrink();
    final preview = c.content.isEmpty
        ? c.reason
        : (c.content.length > 80
            ? '${c.content.substring(0, 80)}…'
            : c.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 14, color: AppColors.teal),
            SizedBox(width: 4),
            Text(
              '자동 인식',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          preview,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Saved confirmation
// ─────────────────────────────────────────────────────────────

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
