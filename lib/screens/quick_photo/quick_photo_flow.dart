import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../data/sample_data.dart';
import '../../services/memo_repository.dart';
import '../../services/photo_capture_service.dart';
import '../../theme/colors.dart';
import '../../widgets/app_toggle.dart';
import '../../widgets/photo_tile.dart';

enum _Step { camera, review, memo, done }

/// Full-screen capture flow modeled on the design's QuickPhotoModal but wired
/// up to real services: native camera/gallery (image_picker) → Supabase
/// Storage → OpenAI gpt-5.4-nano via the `classify-image` Edge Function →
/// photo_memos row insert.
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
      _step = _Step.review;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _step == _Step.memo || _step == _Step.done
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Material(
        color: const Color(0xFF0A0A0A),
        child: switch (_step) {
          _Step.camera => _CameraView(
              onCapture: _onCaptured,
              onClose: () => Navigator.of(context).pop(),
            ),
          _Step.review => _ReviewView(
              photo: _photo!,
              onRetake: () => setState(() => _step = _Step.camera),
              onNext: () => setState(() => _step = _Step.memo),
              onClose: () => Navigator.of(context).pop(),
            ),
          _Step.memo => _MemoEntryView(
              photo: _photo!,
              onBack: () => setState(() => _step = _Step.review),
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
                  _circleBtn(Icons.bolt, () {}),
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
                      _squareBtn(Icons.flip_camera_ios_outlined, () {}),
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
                        border:
                            Border.all(color: AppColors.coral, width: 2),
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
// Step 2 — review captured photo. AI processing happens on the next step
// (memo entry) so the user has time to look at the photo first.
// ─────────────────────────────────────────────────────────────

class _ReviewView extends StatelessWidget {
  final CapturedPhoto photo;
  final VoidCallback onRetake;
  final VoidCallback onNext;
  final VoidCallback onClose;
  const _ReviewView({
    required this.photo,
    required this.onRetake,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLabel =
        '${now.month}월 ${now.day}일 · ${now.hour < 12 ? "오전" : "오후"} ${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      color: const Color(0xFF1A1815),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onClose,
                  child: const Text('취소',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const Text(
                  '사진 확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhotoLarge(bytes: photo.bytes, label: timeLabel),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.coral.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 18, color: Color(0xFFFFB199)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '다음 단계에서 글씨를 읽고 자동으로 분류해 드릴게요.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFFFD9CC),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              36 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: onRetake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Color(0x4DFFFFFF), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '다시 찍기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '이 사진으로 기록하기',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Step 3 — memo entry. On entry: upload to Storage + classify via Edge Fn.
// On save: insert photo_memos row.
// ─────────────────────────────────────────────────────────────

class _MemoEntryView extends StatefulWidget {
  final CapturedPhoto photo;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  final VoidCallback onClose;
  const _MemoEntryView({
    required this.photo,
    required this.onBack,
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
  String _remindWhen = '내일 오전 9:00';

  bool _processing = true;
  String? _photoPath;
  ClassificationResult? _classification;
  String? _processingError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _process();
  }

  Future<void> _process() async {
    try {
      final path = await _repo.uploadPhoto(
        bytes: widget.photo.bytes,
        mimeType: widget.photo.mimeType,
        extension: widget.photo.extension,
      );
      if (!mounted) return;
      setState(() => _photoPath = path);

      final c = await _repo.classifyPhoto(path);
      if (!mounted) return;
      setState(() {
        _classification = c;
        _category = c.category;
        if (_titleCtrl.text.isEmpty) _titleCtrl.text = _defaultTitle(c.category);
        if (_memoCtrl.text.isEmpty) _memoCtrl.text = c.content;
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
    if (_saving) return;
    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 업로드가 완료되지 않았어요. 잠시만 기다려주세요.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.createPhotoMemo(
        photoPath: _photoPath!,
        title: _titleCtrl.text.trim(),
        memo: _memoCtrl.text.trim(),
        categoryId: _category,
        memoDate: DateTime.now(),
        ocrText: _classification?.content,
        classificationReason: _classification?.reason,
        remind: _remind,
        remindAt: _remind ? parseRemindPreset(_remindWhen) : null,
      );
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
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : widget.onBack,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left,
                            size: 20, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text(
                          '뒤로',
                          style: TextStyle(
                              color: AppColors.ink, fontSize: 16),
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
                  TextButton(
                    onPressed: _saving ? null : widget.onClose,
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                          color: AppColors.inkMuted, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhotoTile(
                        bytes: widget.photo.bytes,
                        width: 84,
                        height: 84,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _AutoDetectStatus(
                        processing: _processing,
                        error: _processingError,
                        classification: _classification,
                      )),
                    ],
                  ),
                  const SizedBox(height: 18),
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
                        for (final c in sampleCategories)
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
                                        ? '$_remindWhen에 알림'
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
                                for (final w in const [
                                  '1시간 후',
                                  '내일 오전 9:00',
                                  '3일 뒤',
                                  '1주일 뒤'
                                ])
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _remindWhen = w),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _remindWhen == w
                                            ? AppColors.coralSoft
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _remindWhen == w
                                              ? AppColors.coral
                                              : AppColors.border,
                                          width:
                                              _remindWhen == w ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        w,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _remindWhen == w
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: _remindWhen == w
                                              ? const Color(0xFF9C3F3A)
                                              : AppColors.inkSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
          const Icon(Icons.error_outline,
              size: 14, color: Color(0xFF9C3F3A)),
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

// ─────────────────────────────────────────────────────────────
// Step 4 — saved confirmation
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
    return Container(
      color: AppColors.cream,
      child: const Center(
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
