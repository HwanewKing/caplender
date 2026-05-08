enum EventKind { schedule, holiday, birthday, photoMemo }

enum PhotoTone { note, receipt, card, product }

enum ScheduleColor { mint, pink }

class Event {
  final String id;
  final DateTime date;
  final EventKind kind;
  final String title;
  final String? photoLabel;
  final PhotoTone? tone;
  final ScheduleColor? color;
  final String? emoji;
  final bool remind;
  final String? remindAt;

  /// One of the 4 PRD categories: memo / receipt / business_card / other.
  /// Only meaningful for photoMemo events.
  final String? categoryId;

  /// Storage path of the captured photo (`{user_id}/{photo_id}.jpg`). Only
  /// set for photoMemo events that came from the DB; sample events leave it
  /// null and the UI falls back to the tone-based placeholder.
  final String? photoPath;

  /// Body of the memo as the user typed/dictated it.
  final String? memoBody;

  /// "내용" — text the gpt-5.4-nano classifier extracted from the photo.
  final String? ocrText;

  /// "근거" — short rationale the classifier returned alongside the category.
  final String? classificationReason;

  /// Raw reminder timestamp from the DB. [remindAt] is the human-readable
  /// "오전 9:00" string used in lists; this is the precise time the edit
  /// screen needs to repopulate its picker. Null for sample events.
  final DateTime? remindAtTime;

  const Event({
    required this.id,
    required this.date,
    required this.kind,
    required this.title,
    this.photoLabel,
    this.tone,
    this.color,
    this.emoji,
    this.remind = false,
    this.remindAt,
    this.categoryId,
    this.photoPath,
    this.memoBody,
    this.ocrText,
    this.classificationReason,
    this.remindAtTime,
  });
}

/// Fallback tone for a photoMemo whose category came from the classifier.
PhotoTone toneForCategory(String? categoryId) {
  switch (categoryId) {
    case 'receipt':
      return PhotoTone.receipt;
    case 'business_card':
      return PhotoTone.card;
    case 'other':
      return PhotoTone.product;
    case 'memo':
    default:
      return PhotoTone.note;
  }
}

class CategoryItem {
  final String id;
  final String name;
  final int count;
  final int colorValue;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.count,
    required this.colorValue,
  });
}

enum FontScale { sm, md, lg, xl }

extension FontScaleX on FontScale {
  double get multiplier => switch (this) {
        FontScale.sm => 0.92,
        FontScale.md => 1.0,
        FontScale.lg => 1.12,
        FontScale.xl => 1.24,
      };

  String get label => switch (this) {
        FontScale.sm => '작게',
        FontScale.md => '보통',
        FontScale.lg => '크게',
        FontScale.xl => '아주 크게',
      };

  double get sampleSize => switch (this) {
        FontScale.sm => 13,
        FontScale.md => 15,
        FontScale.lg => 18,
        FontScale.xl => 21,
      };
}
