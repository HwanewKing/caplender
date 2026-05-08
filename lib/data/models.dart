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
  });
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
