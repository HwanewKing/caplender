import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/colors.dart';

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
    final palette = _palettes[tone] ?? _palettes[PhotoTone.note]!;

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
  PhotoTone.manual: _Palette(
    Color(0xFFE5D6C7),
    Color(0xFFCFBFA8),
    Color(0xFF7A6A55),
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
      case PhotoTone.manual:
        canvas.drawRect(
          Rect.fromLTWH(5 * scaleX, 6 * scaleY, 26 * scaleX, 24 * scaleY),
          Paint()..color = Colors.white.withValues(alpha: 0.6),
        );
        canvas.drawLine(p(18, 6), p(18, 30), Paint()
          ..color = palette.accent
          ..strokeWidth = 0.6 * scaleY
          ..style = PaintingStyle.stroke);
        for (final y in [10.0, 14.0, 18.0, 22.0, 26.0]) {
          canvas.drawLine(p(7, y), p(16, y), stripe);
          canvas.drawLine(p(20, y), p(29, y), stripe);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoTonePainter old) =>
      old.tone != tone || old.palette != palette;
}

/// Placeholder for a text-only memo — same tone palette as [PhotoTile] so
/// it sits comfortably alongside photo thumbnails. When [title] / [body]
/// are provided AND the tile is large enough, renders a post-it style
/// card with the memo's actual text. Otherwise falls back to the compact
/// "T" letter glyph used in small lists and chips.
class TextMemoTile extends StatelessWidget {
  final PhotoTone tone;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool elevated;
  final String? title;
  final String? body;

  /// When true, the post-it leaves room at the top for an overlaid badge
  /// (the gallery card's date pill). When false (folder covers, etc.), the
  /// title sits much closer to the top so the card doesn't look empty.
  final bool reserveTopBadgeArea;

  const TextMemoTile({
    super.key,
    this.tone = PhotoTone.note,
    this.width = 36,
    this.height = 36,
    this.borderRadius,
    this.elevated = true,
    this.title,
    this.body,
    this.reserveTopBadgeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(4);
    final palette = _palettes[tone] ?? _palettes[PhotoTone.note]!;
    final hasText = (title != null && title!.trim().isNotEmpty) ||
        (body != null && body!.trim().isNotEmpty);

    final tile = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: palette.bg),
          // Notepad-style top accent — only for the "T" glyph fallback;
          // when we render real text the date pill + bold title carry the
          // visual weight and the stripe would just clutter the layout.
          if (!hasText)
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.12,
                child: ColoredBox(color: palette.accent.withValues(alpha: 0.55)),
              ),
            ),
          // Two render modes, picked WITHOUT a LayoutBuilder so this widget
          // still supports dry layout / intrinsic sizing (the calendar wraps
          // each week row in IntrinsicHeight, which requires every descendant
          // to compute intrinsics — LayoutBuilder doesn't).
          //   - hasText → post-it layout (gallery cards, folder covers).
          //     Uses absolute font/padding sizes so it works at any rendered
          //     size from the parent's constraints.
          //   - else → compact "T" glyph (calendar chips, day sheets, etc.),
          //     where callers always pass a concrete finite `height`.
          if (hasText)
            _PostItContent(
              title: (title ?? '').trim(),
              body: (body ?? '').trim(),
              palette: palette,
              reserveTopBadgeArea: reserveTopBadgeArea,
            )
          else
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: (height.isFinite ? height : 36) * 0.04),
                  child: Text(
                    'T',
                    style: TextStyle(
                      fontSize: (height.isFinite ? height : 36) * 0.62,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Container(
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
    );
  }
}

/// Post-it style title + body laid out for [TextMemoTile]. Font sizes
/// scale with tile height so the same widget works for gallery cards
/// (~110px gallery cards, ~100-200px folder covers). Uses fixed font and
/// padding values so it supports dry layout (IntrinsicHeight / Wrap inside
/// the calendar week rows would break otherwise).
class _PostItContent extends StatelessWidget {
  final String title;
  final String body;
  final _Palette palette;
  final bool reserveTopBadgeArea;

  const _PostItContent({
    required this.title,
    required this.body,
    required this.palette,
    required this.reserveTopBadgeArea,
  });

  @override
  Widget build(BuildContext context) {
    // Top padding clears the date pill (top:6 + ~20px tall = ~26px) plus a
    // small breathing room when an overlaid badge is expected. Folder
    // covers have no overlay so they get a tighter top to avoid an empty
    // upper band. Divider sits between bold title and the body snippet,
    // which renders smaller/lighter and ellipsises on overflow.
    final topPad = reserveTopBadgeArea ? 32.0 : 12.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, topPad, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
                letterSpacing: -0.2,
              ),
            ),
          if (title.isNotEmpty && body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              height: 1,
              color: AppColors.ink.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 6),
          ],
          if (body.isNotEmpty)
            Flexible(
              child: Text(
                body,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.inkSoft,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
                      tone: tone,
                      palette: _palettes[tone] ?? _palettes[PhotoTone.note]!),
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
