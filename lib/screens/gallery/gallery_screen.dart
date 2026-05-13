import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../services/memo_store.dart';
import '../../theme/colors.dart';
import '../../widgets/stored_photo.dart';
import '../photo_memo_detail.dart';

/// Gallery view with date / category folder toggle.
/// In category mode, picking a folder pushes a detail screen.
class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

enum _Mode { date, category }

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  _Mode _mode = _Mode.date;
  String? _selectedCat;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '모아보기',
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
              SizedBox(height: 2),
              Text(
                '기록',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Row(
            children: [
              _Tab(
                active: _mode == _Mode.date,
                label: '날짜순',
                onTap: () => setState(() {
                  _mode = _Mode.date;
                  _selectedCat = null;
                }),
              ),
              const SizedBox(width: 8),
              _Tab(
                active: _mode == _Mode.category,
                label: '분류별 폴더',
                onTap: () => setState(() => _mode = _Mode.category),
              ),
            ],
          ),
        ),
        if (_mode == _Mode.date)
          const _DateGallery()
        else if (_selectedCat != null)
          _CategoryDetail(
            catId: _selectedCat!,
            onBack: () => setState(() => _selectedCat = null),
          )
        else
          _CategoryFolders(onPick: (id) => setState(() => _selectedCat = id)),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;
  const _Tab({required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: active ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateGallery extends StatelessWidget {
  const _DateGallery();

  @override
  Widget build(BuildContext context) {
    final items = MemoStoreScope.of(context).galleryItems();
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(22, 40, 22, 40),
        child: Center(
          child: Text(
            '아직 저장된 사진이 없어요.\nQUICK 버튼으로 첫 사진을 남겨보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    // Group by year-month, newest first.
    final groups = <String, List<Event>>{};
    for (final e in items) {
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(e);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final k in keys) ...[
            Text(
              '${k.split('-')[0]}년 ${int.parse(k.split('-')[1])}월',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children:
                  groups[k]!.map((e) => _GalleryCard(ev: e)).toList(),
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final Event ev;
  const _GalleryCard({required this.ev});

  @override
  Widget build(BuildContext context) {
    final isTextMemo = ev.photoPath == null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          PhotoMemoDetailScreen.route(ev),
        ),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEFE8D6),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CardThumb(
                  photoPath: ev.photoPath,
                  tone: ev.tone ?? PhotoTone.note,
                  memoTitle: ev.title,
                  memoBody: ev.memoBody,
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xC71F1B16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${ev.date.month}.${ev.date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                if (ev.remind)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Photo memos overlay the title on a dark gradient so it
                // sits on top of the image; text memos already render the
                // title prominently inside the post-it tile.
                if (!isTextMemo)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                        ),
                      ),
                      child: Text(
                        ev.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFolders extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _CategoryFolders({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cats = MemoStoreScope.of(context).categoriesWithCount();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
        children: cats
            .map((c) => _FolderCard(cat: c, onTap: () => onPick(c.id)))
            .toList(),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final CategoryItem cat;
  final VoidCallback onTap;
  const _FolderCard({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _FolderCover(cat: cat),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                cat.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${cat.count}개',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  final String catId;
  final VoidCallback onBack;
  const _CategoryDetail({required this.catId, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final store = MemoStoreScope.of(context);
    final cat = store.categoriesWithCount().firstWhere((c) => c.id == catId);
    final items =
        store.galleryItems().where((g) => g.categoryId == catId).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.chevron_left, size: 18, color: AppColors.inkSoft),
                  SizedBox(width: 4),
                  Text(
                    '폴더',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(cat.colorValue),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cat.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${items.length}개',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: items.map((e) => _GalleryCard(ev: e)).toList(),
          ),
        ],
      ),
    );
  }
}

/// Renders the actual photo when [photoPath] is provided (signed URL fetched
/// on demand and cached by [MemoStore]); otherwise falls back to a post-it
/// style text memo tile that shows the memo title and body snippet.
class _CardThumb extends StatelessWidget {
  final String? photoPath;
  final PhotoTone tone;
  final String? memoTitle;
  final String? memoBody;
  const _CardThumb({
    required this.photoPath,
    required this.tone,
    this.memoTitle,
    this.memoBody,
  });

  @override
  Widget build(BuildContext context) {
    return StoredPhoto(
      photoPath: photoPath,
      tone: tone,
      width: double.infinity,
      height: double.infinity,
      memoTitle: memoTitle,
      memoBody: memoBody,
    );
  }
}

/// Folder cover — uses the most recent memo in the category as the cover,
/// regardless of whether that memo is a photo or text-only. Falls back to
/// the category's solid swatch only when the folder is truly empty.
class _FolderCover extends StatelessWidget {
  final CategoryItem cat;
  const _FolderCover({required this.cat});

  @override
  Widget build(BuildContext context) {
    final latest = MemoStoreScope.of(context).latestForCategory(cat.id);
    final swatch = Color(cat.colorValue);
    // When the latest memo is text-only we render the post-it card directly
    // and drop the folder-tab strip so the cover reads as a memo card (clear
    // contrast against the strip-decorated swatch of empty folders).
    final isTextCover = latest != null && latest.photoPath == null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (latest != null)
          _CoverContent(
            event: latest,
            swatchColor: swatch,
          )
        else
          ColoredBox(color: swatch),
        // Folder-tab strip — kept for empty folders and photo covers so the
        // folder metaphor reads. Hidden for text-memo covers so the post-it
        // title isn't visually crowded by the strip.
        if (!isTextCover)
          Positioned(
            top: 8,
            left: 8,
            right: 32,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xC71F1B16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${cat.count}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders either the latest memo's photo or — for text-only memos — a
/// post-it tile carrying that memo's title/body. The swatch is used as
/// the still-loading placeholder for photo memos so the folder card
/// doesn't flash to a generic tone tile.
class _CoverContent extends StatelessWidget {
  final Event event;
  final Color swatchColor;
  const _CoverContent({required this.event, required this.swatchColor});

  @override
  Widget build(BuildContext context) {
    return StoredPhoto(
      photoPath: event.photoPath,
      tone: event.tone ?? PhotoTone.note,
      width: double.infinity,
      height: double.infinity,
      drawTonePlaceholder: false,
      placeholderColor: swatchColor,
      memoTitle: event.title,
      memoBody: event.memoBody,
      // Folder cover has no overlaid date pill — let the title sit near
      // the top edge instead of leaving a big empty band.
      reserveTopBadgeArea: false,
    );
  }
}
