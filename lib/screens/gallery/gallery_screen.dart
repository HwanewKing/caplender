import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sample_data.dart';
import '../../theme/colors.dart';
import '../../widgets/photo_tile.dart';

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
                '사진',
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
    final items = galleryItems()
        .where((g) =>
            g.date.year == 2027 && g.date.month == 3)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2027년 3월',
            style: TextStyle(
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
            children: items.map((e) => _GalleryCard(ev: e)).toList(),
          ),
          const SizedBox(height: 22),
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
    return ClipRRect(
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
            PhotoTile(
              tone: ev.tone ?? PhotoTone.note,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
              elevated: false,
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xC71F1B16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '3.${ev.date.day}',
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
    );
  }
}

class _CategoryFolders extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _CategoryFolders({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
        children: sampleCategories
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
                  child: Container(
                    color: Color(cat.colorValue),
                    child: Stack(
                      children: [
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
                          child: Text(
                            '${cat.count}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppColors.ink.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final cat = sampleCategories.firstWhere((c) => c.id == catId);
    final items =
        galleryItems().where((g) => g.categoryId == catId).toList();
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
