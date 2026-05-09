import 'package:flutter/material.dart';

import '../app.dart' show gaeguStyle;
import '../data/categories.dart';
import '../theme/colors.dart';
import '../utils/date_format.dart';
import 'app_toggle.dart';
import 'datetime_pickers.dart';

/// Shared form body for the new-memo (QuickPhoto) and edit-memo screens.
/// Both screens were duplicating ~200 lines of identical markup; this
/// widget keeps them in sync by construction.
///
/// State (controllers, current category, reminder values) is owned by the
/// parent so each screen can decide when/how to validate and save. This
/// widget only renders and routes user changes back via callbacks.
class MemoFormFields extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController memoCtrl;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final bool remind;
  final ValueChanged<bool> onRemindChanged;
  final DateTime remindAt;
  final ValueChanged<DateTime> onRemindAtChanged;
  final String? activePreset;
  final ValueChanged<String?> onActivePresetChanged;

  /// Optional widget rendered above the title field — used by QuickPhoto
  /// to show the captured photo + auto-detect status side by side.
  final Widget? leading;

  /// Placeholder for the memo body field. Defaults to the photo-flow copy;
  /// the text-only flow overrides it since "이 사진에 대해…" reads odd when
  /// there is no photo.
  final String? memoHint;

  const MemoFormFields({
    super.key,
    required this.titleCtrl,
    required this.memoCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.remind,
    required this.onRemindChanged,
    required this.remindAt,
    required this.onRemindAtChanged,
    required this.activePreset,
    required this.onActivePresetChanged,
    this.leading,
    this.memoHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(height: 18),
        ],
        _Field(
          label: '제목',
          child: TextField(
            controller: titleCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: _inputDecoration(),
          ),
        ),
        _Field(
          label: '메모',
          child: TextField(
            controller: memoCtrl,
            maxLines: 5,
            minLines: 3,
            style: gaeguStyle(size: 17),
            decoration: _inputDecoration(
              hint: memoHint ?? '이 사진에 대해 기억하고 싶은 것을 적어주세요',
            ),
          ),
        ),
        _Field(
          label: '분류',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in appCategories)
                _CategoryChip(
                  category: c,
                  active: category == c.id,
                  onTap: () => onCategoryChanged(c.id),
                ),
            ],
          ),
        ),
        _ReminderSection(
          remind: remind,
          onRemindChanged: onRemindChanged,
          remindAt: remindAt,
          onRemindAtChanged: onRemindAtChanged,
          activePreset: activePreset,
          onActivePresetChanged: onActivePresetChanged,
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.inkMuted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final dynamic category; // CategoryItem; kept dynamic to avoid extra import.
  final bool active;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.category,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFFFCFAF4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.teal : AppColors.border,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(category.colorValue as int),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.name as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.teal : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSection extends StatelessWidget {
  final bool remind;
  final ValueChanged<bool> onRemindChanged;
  final DateTime remindAt;
  final ValueChanged<DateTime> onRemindAtChanged;
  final String? activePreset;
  final ValueChanged<String?> onActivePresetChanged;

  const _ReminderSection({
    required this.remind,
    required this.onRemindChanged,
    required this.remindAt,
    required this.onRemindAtChanged,
    required this.activePreset,
    required this.onActivePresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.coralSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.coral,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '잊지 않게 알려주기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remind
                          ? '${formatRemindLabel(remindAt)}에 알림'
                          : '알림이 꺼져 있어요',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AppToggle(value: remind, onChanged: onRemindChanged),
            ],
          ),
          if (remind) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final w in remindPresets)
                    _PresetChip(
                      label: w,
                      active: activePreset == w,
                      onTap: () {
                        onRemindAtChanged(parseRemindPreset(w));
                        onActivePresetChanged(w);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: DateTimePickers(
                value: remindAt,
                onChanged: (next) {
                  onRemindAtChanged(next);
                  onActivePresetChanged(null);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.coralSoft : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.coral : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? const Color(0xFF9C3F3A) : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
