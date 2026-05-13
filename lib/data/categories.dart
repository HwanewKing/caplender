import 'models.dart';

/// The five buckets seeded into Supabase's `categories` table by the
/// initial migration plus 0003_add_manual_category. Source of truth for
/// the app side — counts are filled in at runtime by
/// `MemoStore.categoriesWithCount()`.
const List<CategoryItem> appCategories = [
  CategoryItem(id: 'memo', name: '메모', count: 0, colorValue: 0xFFF2C19F),
  CategoryItem(id: 'receipt', name: '영수증', count: 0, colorValue: 0xFFC7E0E2),
  CategoryItem(
      id: 'business_card', name: '명함', count: 0, colorValue: 0xFFD7E3E5),
  CategoryItem(id: 'manual', name: '설명서', count: 0, colorValue: 0xFFE5D6C7),
  CategoryItem(id: 'other', name: '기타', count: 0, colorValue: 0xFFE8E1CF),
];
