import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../utils/date_format.dart';
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
  /// function downloads the file with its service-role key and forwards it
  /// to OpenAI. The OpenAI key never reaches the client.
  Future<ClassificationResult> classifyPhoto(String photoPath) async {
    final response = await supabase.functions.invoke(
      _classifyFn,
      body: {'photoPath': photoPath},
    );
    final data = response.data;
    if (!kReleaseMode) {
      debugPrint('[caplender] classify-image status=${response.status}');
    }
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

  /// Insert a row into photo_memos. Returns the new row id. [memoDate] is
  /// clamped to today so a clock-skewed device or a gallery-picked photo
  /// with a future EXIF can't put a memo on a future calendar day.
  ///
  /// [photoPath] is null for text-only memos — the column already accepts
  /// null and the UI falls back to a tone-based placeholder tile.
  Future<String> createMemo({
    String? photoPath,
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
    final today = DateTime.now();
    final clamped = memoDate.isAfter(today) ? today : memoDate;
    final dateStr = '${clamped.year.toString().padLeft(4, '0')}-'
        '${clamped.month.toString().padLeft(2, '0')}-'
        '${clamped.day.toString().padLeft(2, '0')}';

    final inserted = await supabase
        .from('photo_memos')
        .insert({
          'user_id': userId,
          'memo_date': dateStr,
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

  /// Fetch the current user's photo memos, newest first. Returns an empty
  /// list if no user is signed in (rather than throwing) so first-frame
  /// builders don't have to special-case bootstrap timing.
  Future<List<Event>> listPhotoMemos() async {
    final userId = currentUserId;
    if (userId == null) return const [];
    final rows = await supabase
        .from('photo_memos')
        .select(
            'id, memo_date, title, memo, category_id, photo_path, remind, remind_at, ocr_text, classification_reason')
        .eq('user_id', userId)
        .order('memo_date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _rowToEvent(r as Map<String, dynamic>))
        .toList();
  }

  /// Create a temporary signed download URL for a private storage object.
  /// Caller is responsible for caching — every call hits the API.
  Future<String> signedUrlFor(String photoPath,
      {Duration ttl = const Duration(minutes: 30)}) {
    return supabase.storage
        .from(_bucket)
        .createSignedUrl(photoPath, ttl.inSeconds);
  }

  /// Best-effort delete for an uploaded photo that never got attached to a
  /// memo row.
  Future<void> deletePhotoUpload(String photoPath) {
    return supabase.storage.from(_bucket).remove([photoPath]);
  }

  /// Update the editable text/category/reminder fields of an existing memo.
  /// The photo itself stays put — replacing the photo would be a separate
  /// flow.
  Future<void> updatePhotoMemo({
    required String id,
    required String title,
    required String memo,
    required String categoryId,
    required bool remind,
    DateTime? remindAt,
  }) async {
    await supabase.from('photo_memos').update({
      'title': title,
      'memo': memo,
      'category_id': categoryId,
      'remind': remind,
      'remind_at': remindAt?.toIso8601String(),
    }).eq('id', id);
  }

  /// Delete a memo row and best-effort delete its storage object too.
  /// Storage failures don't block the row delete — the row is the source
  /// of truth and an orphaned storage object can be cleaned up later.
  Future<void> deletePhotoMemo({
    required String id,
    String? photoPath,
  }) async {
    await supabase.from('photo_memos').delete().eq('id', id);
    if (photoPath != null) {
      try {
        await deletePhotoUpload(photoPath);
      } catch (e) {
        if (!kReleaseMode) {
          debugPrint('[caplender] storage remove failed for $photoPath: $e');
        }
      }
    }
  }
}

/// Map a `photo_memos` row to the UI's [Event] type. Reminder time is
/// formatted into the Korean "오전/오후 H:MM" string the existing widgets
/// expect; the raw timestamp stays in the DB.
Event _rowToEvent(Map<String, dynamic> r) {
  final id = r['id'] as String;
  final memoDate = DateTime.parse(r['memo_date'] as String);
  final title = (r['title'] as String?)?.trim() ?? '';
  final memo = (r['memo'] as String?) ?? '';
  final categoryId = (r['category_id'] as String?) ?? 'memo';
  final photoPath = r['photo_path'] as String?;
  final remind = (r['remind'] as bool?) ?? false;
  final remindAtRawString = r['remind_at'] as String?;
  final remindAtTime = remindAtRawString != null
      ? DateTime.parse(remindAtRawString).toLocal()
      : null;
  final remindAt = remindAtTime != null ? formatTimeOnly(remindAtTime) : null;

  return Event(
    id: id,
    date: DateTime(memoDate.year, memoDate.month, memoDate.day),
    kind: EventKind.photoMemo,
    title: title.isEmpty ? '메모' : title,
    tone: toneForCategory(categoryId),
    categoryId: categoryId,
    remind: remind,
    remindAt: remindAt,
    remindAtTime: remindAtTime,
    photoPath: photoPath,
    memoBody: memo,
    ocrText: r['ocr_text'] as String?,
    classificationReason: r['classification_reason'] as String?,
  );
}
