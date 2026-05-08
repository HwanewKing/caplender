import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap.dart';
import 'photo_capture_service.dart';

/// Server-side classification result from the `classify-image` Edge Function.
class ClassificationResult {
  final String category; // memo / receipt / business_card / other
  final String reason;
  final String content;
  final String raw;

  const ClassificationResult({
    required this.category,
    required this.reason,
    required this.content,
    required this.raw,
  });
}

/// Wraps Supabase Storage + photo_memos CRUD + the OpenAI classifier Edge
/// Function. Keeps screens clean of Supabase API specifics.
class MemoRepository {
  MemoRepository();

  static const _bucket = 'photo-memos';
  static const _classifyFn = 'classify-image';

  /// Upload bytes to `{user_id}/{photoId}.{ext}` in the photo-memos bucket.
  /// Returns the storage path of the uploaded object.
  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String mimeType,
    required String extension,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('No authenticated user — cannot upload.');
    }
    final photoId = newPhotoId();
    final path = '$userId/$photoId.$extension';

    await supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    return path;
  }

  /// Calls the Edge Function to classify a previously uploaded photo. The
  /// function downloads the file using its service-role key and forwards it
  /// to OpenAI gpt-5.4-nano. The OpenAI key never reaches the client.
  Future<ClassificationResult> classifyPhoto(String photoPath) async {
    final response = await supabase.functions.invoke(
      _classifyFn,
      body: {'photoPath': photoPath},
    );
    final data = response.data;
    debugPrint('[caplender] classify-image response status=${response.status}'
        ' data=$data');
    if (response.status != 200 || data is! Map<String, dynamic>) {
      throw Exception('Classification failed (${response.status}): $data');
    }
    return ClassificationResult(
      category: (data['category'] as String?) ?? 'other',
      reason: (data['reason'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      raw: (data['raw'] as String?) ?? '',
    );
  }

  /// Insert a row into photo_memos. Returns the new row id.
  Future<String> createPhotoMemo({
    required String photoPath,
    required String title,
    required String memo,
    required String categoryId,
    required DateTime memoDate,
    String? ocrText,
    String? classificationReason,
    bool remind = false,
    DateTime? remindAt,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('No authenticated user — cannot save memo.');
    }
    final inserted = await supabase
        .from('photo_memos')
        .insert({
          'user_id': userId,
          'memo_date':
              '${memoDate.year.toString().padLeft(4, '0')}-${memoDate.month.toString().padLeft(2, '0')}-${memoDate.day.toString().padLeft(2, '0')}',
          'title': title,
          'memo': memo,
          'category_id': categoryId,
          'photo_path': photoPath,
          'ocr_text': ocrText,
          'classification_reason': classificationReason,
          'remind': remind,
          'remind_at': remindAt?.toIso8601String(),
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }
}

/// Convert a remind-preset chip ("내일 오전 9:00", "3일 뒤" …) into an absolute
/// DateTime relative to `now`. Best-effort — used until we add a proper picker.
DateTime parseRemindPreset(String preset, {DateTime? now}) {
  final base = now ?? DateTime.now();
  switch (preset) {
    case '1시간 후':
      return base.add(const Duration(hours: 1));
    case '내일 오전 9:00':
      final tomorrow = base.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    case '3일 뒤':
      final d = base.add(const Duration(days: 3));
      return DateTime(d.year, d.month, d.day, 9, 0);
    case '1주일 뒤':
      final d = base.add(const Duration(days: 7));
      return DateTime(d.year, d.month, d.day, 9, 0);
    default:
      return base.add(const Duration(hours: 1));
  }
}
