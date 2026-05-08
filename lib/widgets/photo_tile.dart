import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/models.dart';

/// Stylised placeholder representing a captured photo. Replaces the design's
/// inline SVG `PhotoTile` — same 4 tones (note/receipt/card/product), drawn with
/// `CustomPaint` so they scale to any size and feel like real captures rather
/// than icons.
///
/// Pass [bytes] to render an actual captured image instead of the placeholder.
class PhotoTile extends StatelessWidget {
  final PhotoTone tone;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final double rotation;
  final bool elevated;
  final Uint8List? bytes;

  const PhotoTile({
    super.key,
    this.tone = PhotoTone.note,
    this.width = 36,
    this.height = 36,
    this.borderRadius,
    this.rotation = 0,
    this.elevated = true,
    this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(4);
    final palette = _palettes[tone]!;

    final tile = ClipRRect(
      borderRadius: radius,
      child: bytes != null
          ? Image.memory(
              bytes!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            )
          : CustomPaint(
              size: Size(width, height),
              painter: _PhotoTonePainter(tone: tone, palette: palette),
            ),
    );

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: elevated
            ? BoxDecoration(
                borderRadius: radius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 0,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              )
            : null,
        child: tile,
      ),
    );
  }
}

class _Palette {
  final Color bg;
  final Color stripe;
  final Color accent;
  const _Palette(this.bg, this.stripe, this.accent);
}

const Map<PhotoTone, _Palette> _palettes = {
  PhotoTone.note: _Palette(
    Color(0xFFEFE8D6),
    Color(0xFFD9CFB4),
    Color(0xFFA89A78),
  ),
  PhotoTone.receipt: _Palette(
    Color(0xFFF4EFE5),
    Color(0xFFE0D7C2),
    Color(0xFF8C8474),
  ),
  PhotoTone.card: _Palette(
    Color(0xFFD7E3E5),
    Color(0xFFB5C9CC),
    Color(0xFF5A7B7E),
  ),
  PhotoTone.product: _Palette(
    Color(0xFFF1D7C8),
    Color(0xFFE2B69E),
    Color(0xFF9C5A3F),
  ),
};

class _PhotoTonePainter extends CustomPainter {
  final PhotoTone tone;
  final _Palette palette;

  _PhotoTonePainter({required this.tone, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 36;
    final scaleY = size.height / 36;
    final bg = Paint()..color = palette.bg;
    canvas.drawRect(Offset.zero & size, bg);

    final stripe = Paint()
      ..color = palette.stripe
      ..strokeWidth = 0.8 * scaleY
      ..style = PaintingStyle.stroke;

    final accent = Paint()..color = palette.accent;

    Offset p(double x, double y) => Offset(x * scaleX, y * scaleY);

    switch (tone) {
      case PhotoTone.note:
        for (final y in [10.0, 16.0, 22.0, 28.0]) {
          canvas.drawLine(p(3, y), p(33, y), stripe);
        }
        canvas.drawRect(
          Rect.fromLTWH(0, 0, 36 * scaleX, 5 * scaleY),
          Paint()..color = palette.accent.withValues(alpha: 0.6),
        );
        break;
      case PhotoTone.receipt:
        // Scalloped bottom edge
        final path = Path()
          ..moveTo(0, 32 * scaleY)
          ..lineTo(4 * scaleX, 35 * scaleY)
          ..lineTo(8 * scaleX, 32 * scaleY)
          ..lineTo(12 * scaleX, 35 * scaleY)
          ..lineTo(16 * scaleX, 32 * scaleY)
          ..lineTo(20 * scaleX, 35 * scaleY)
          ..lineTo(24 * scaleX, 32 * scaleY)
          ..lineTo(28 * scaleX, 35 * scaleY)
          ..lineTo(32 * scaleX, 32 * scaleY)
          ..lineTo(36 * scaleX, 35 * scaleY)
          ..lineTo(36 * scaleX, 36 * scaleY)
          ..lineTo(0, 36 * scaleY)
          ..close();
        canvas.drawPath(path, Paint()..color = palette.bg);
        canvas.drawRect(
          Rect.fromLTWH(6 * scaleX, 6 * scaleY, 24 * scaleX, 2 * scaleY),
          Paint()..color = palette.accent.withValues(alpha: 0.5),
        );
        for (final entry in const [
          [6.0, 12.0, 30.0, 12.0],
          [6.0, 16.0, 26.0, 16.0],
          [6.0, 20.0, 28.0, 20.0],
          [6.0, 24.0, 22.0, 24.0],
        ]) {
          canvas.drawLine(
            p(entry[0], entry[1]),
            p(entry[2], entry[3]),
            stripe..strokeWidth = 0.6 * scaleY,
          );
        }
        break;
      case PhotoTone.card:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4 * scaleX, 8 * scaleY, 28 * scaleX, 20 * scaleY),
            Radius.circular(2 * scaleX),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
        canvas.drawCircle(
          p(10, 16),
          2.5 * scaleX,
          accent,
        );
        canvas.drawLine(p(15, 15), p(28, 15), Paint()
          ..color = palette.accent
          ..strokeWidth = 0.8 * scaleY
          ..style = PaintingStyle.stroke);
        canvas.drawLine(p(15, 18), p(25, 18), stripe);
        canvas.drawLine(p(6, 23), p(30, 23),
            stripe..strokeWidth = 0.6 * scaleY);
        break;
      case PhotoTone.product:
        canvas.drawCircle(
            p(11, 22), 6 * scaleX, Paint()..color = palette.accent.withValues(alpha: 0.55));
        canvas.drawCircle(
            p(22, 20), 7 * scaleX, Paint()..color = palette.accent.withValues(alpha: 0.7));
        canvas.drawCircle(
            p(14, 14), 4 * scaleX, Paint()..color = palette.accent.withValues(alpha: 0.45));
        final ground = Path()
          ..moveTo(0, 30 * scaleY)
          ..lineTo(36 * scaleX, 32 * scaleY)
          ..lineTo(36 * scaleX, 36 * scaleY)
          ..lineTo(0, 36 * scaleY)
          ..close();
        canvas.drawPath(ground, Paint()..color = palette.stripe);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoTonePainter old) =>
      old.tone != tone || old.palette != palette;
}

/// Larger framed photo used in QuickPhoto review. Adds a label pill overlay.
/// Pass [bytes] to render an actual captured image; otherwise the placeholder
/// painter for [tone] is shown.
class PhotoLarge extends StatelessWidget {
  final PhotoTone tone;
  final String? label;
  final Uint8List? bytes;

  const PhotoLarge(
      {super.key, this.tone = PhotoTone.note, this.label, this.bytes});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: const Color(0xFFE8E1CF),
          foregroundDecoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes!, fit: BoxFit.cover)
              else
                CustomPaint(
                  painter: _PhotoTonePainter(
                      tone: tone, palette: _palettes[tone]!),
                ),
              if (label != null)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xB31F1B16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
