import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/memo_store.dart';
import 'photo_tile.dart';

/// Renders a stored photo via its signed URL with a tone-based placeholder
/// fallback. Reads the URL from the MemoStore's sync cache and triggers a
/// background fetch when needed — listeners on the store fire when the URL
/// lands, so this widget rebuilds and swaps the image in.
///
/// Using a sync API rather than `FutureBuilder` is deliberate: a FutureBuilder
/// re-renders its placeholder every time it is given a new Future identity,
/// which made cached thumbnails flash on every store rebuild.
class StoredPhoto extends StatelessWidget {
  final String? photoPath;
  final PhotoTone tone;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  /// When true, the placeholder for a still-loading photo draws the painted
  /// tone art used by sample data. When false, a flat [placeholderColor]
  /// (or transparent) is used — useful for folder covers where the swatch
  /// IS the placeholder. Does NOT affect text-only memo rendering — those
  /// always show the [TextMemoTile] because the tile itself is the content.
  final bool drawTonePlaceholder;
  final Color? placeholderColor;

  /// When [photoPath] is null, these populate the post-it style text memo
  /// placeholder. Optional: callers in small lists / chips can omit them
  /// and get the compact "T" glyph instead.
  final String? memoTitle;
  final String? memoBody;

  /// Forwarded to [TextMemoTile]. Default leaves room at the top for an
  /// overlaid date pill (gallery card); folder covers pass false so the
  /// post-it title sits closer to the top edge.
  final bool reserveTopBadgeArea;

  const StoredPhoto({
    super.key,
    required this.photoPath,
    required this.tone,
    required this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
    this.drawTonePlaceholder = true,
    this.placeholderColor,
    this.memoTitle,
    this.memoBody,
    this.reserveTopBadgeArea = true,
  });

  Widget _flatPlaceholder() {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: placeholderColor,
      ),
    );
  }

  /// Shown while a real photo's signed URL is being fetched — a
  /// tone-matched silhouette of the eventual image.
  Widget _photoPlaceholder() {
    if (!drawTonePlaceholder && placeholderColor != null) {
      return _flatPlaceholder();
    }
    return PhotoTile(
      tone: tone,
      width: width,
      height: height,
      borderRadius: borderRadius,
      elevated: false,
    );
  }

  /// Shown when the memo has no photo at all (text-only). The tile IS
  /// the content here, so [drawTonePlaceholder] is intentionally ignored.
  Widget _textMemoPlaceholder() {
    return TextMemoTile(
      tone: tone,
      width: width,
      height: height,
      borderRadius: borderRadius,
      elevated: false,
      title: memoTitle,
      body: memoBody,
      reserveTopBadgeArea: reserveTopBadgeArea,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photoPath == null) return _textMemoPlaceholder();
    final store = MemoStoreScope.of(context);
    final url = store.cachedUrlFor(photoPath!);
    if (url == null) {
      store.requestSignedUrl(photoPath!);
      return _photoPlaceholder();
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _photoPlaceholder(),
      ),
    );
  }
}
