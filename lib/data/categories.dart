import 'models.dart';

/// The four buckets defined by the PRD and seeded into Supabase's
/// `categories` table by the initial migration. Source of truth for the
/// app side — counts are filled in at runtime by `MemoStore.categoriesWithCount()`.
const List<CategoryItem> appCategories = [
  CategoryItem(id: 'memo', name: '메모', count: 0, colorValue: 0xFFF2C19F),
  CategoryItem(id: 'receipt', name: '영수증', count: 0, colorValue: 0xFFC7E0E2),
  CategoryItem(
      id: 'business_card', name: '명함', count: 0, colorValue: 0xFFD7E3E5),
  CategoryItem(id: 'other', name: '기타', count: 0, colorValue: 0xFFE8E1CF),
];
