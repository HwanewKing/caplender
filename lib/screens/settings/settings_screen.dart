import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../services/memo_store.dart';
import '../../theme/app_settings.dart';
import '../../theme/colors.dart';
import '../../widgets/app_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSettingsScope.of(context);
    final auth = AuthScope.of(context);
    final store = MemoStoreScope.of(context);
    final memoCount = store.galleryItems().length;
    final reminderCount = store.remindersList().length;
    final displayName = auth.email ?? '내 기록';
    final displayInitial =
        displayName.isNotEmpty ? displayName.characters.first : '내';
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '나의',
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
              SizedBox(height: 2),
              Text(
                '설정',
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
        if (auth.isAnonymous)
          _AnonUpgradeBanner(
            onTap: () => _showUpgradeComingSoon(context),
          ),
        // Profile card
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.peach, AppColors.coral],
                    ),
                  ),
                  child: Text(
                    displayInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '사진 메모 $memoCount개 · 리마인더 $reminderCount개',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        _Group(title: '화면', children: [
          _SizePicker(
            value: s.fontScale,
            onChange: (v) => s.fontScale = v,
          ),
          _Row(
            icon: Icons.local_offer_outlined,
            title: '강조 색상',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in AppColors.accentChoices.take(3))
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => s.accent = c,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: s.accent == c ? AppColors.ink : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
        _Group(title: '알림', children: [
          _Row(
            icon: Icons.notifications_outlined,
            title: '알림 받기',
            trailing: MiniToggle(
              value: s.notifyEnabled,
              onChanged: (v) => s.notifyEnabled = v,
              activeColor: s.accent,
            ),
          ),
          // Local notification scheduling isn't implemented yet, so this row
          // is informational. We surface "준비 중" so users don't expect a
          // setting that does nothing.
          const _Row(
            icon: Icons.access_time,
            title: '기본 알림 시간',
            detail: '준비 중',
          ),
        ]),
        _Group(title: '자동 인식', children: [
          _Row(
            icon: Icons.auto_awesome,
            title: '사진에서 글자 읽기',
            trailing: MiniToggle(
              value: s.autoOcrEnabled,
              onChanged: (v) => s.autoOcrEnabled = v,
              activeColor: s.accent,
            ),
          ),
          _Row(
            icon: Icons.folder_outlined,
            title: '자동 분류',
            trailing: MiniToggle(
              value: s.autoCategorize,
              onChanged: (v) => s.autoCategorize = v,
              activeColor: s.accent,
            ),
          ),
        ]),
        _Group(title: '기타', children: [
          _Row(
            icon: Icons.location_on_outlined,
            title: '공휴일 표시',
            trailing: MiniToggle(
              value: s.showHolidays,
              onChanged: (v) => s.showHolidays = v,
              activeColor: s.accent,
            ),
          ),
          const _Row(title: '도움말'),
          const _Row(title: '버전 정보', detail: '1.0.0'),
        ]),
      ],
    );
  }
}

void _showUpgradeComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(
      content: Text('이메일/소셜 로그인은 곧 추가됩니다.'),
      duration: Duration(seconds: 2),
    ));
}

class _AnonUpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AnonUpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coralSoft,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    size: 22,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이메일을 추가해 보세요',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9C3F3A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '다른 기기에서도 그대로 볼 수 있어요',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A4A24),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF9C3F3A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 22, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                children: List.generate(children.length, (i) {
                  return Container(
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : const Border(
                              top: BorderSide(
                                color: AppColors.borderSoft,
                                width: 1,
                              ),
                            ),
                    ),
                    child: children[i],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? detail;
  final Widget? trailing;

  const _Row({this.icon, required this.title, this.detail, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.inkSoft),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else ...[
            if (detail != null && detail!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  detail!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.inkFaint),
          ],
        ],
      ),
    );
  }
}

class _SizePicker extends StatelessWidget {
  final FontScale value;
  final ValueChanged<FontScale> onChange;
  const _SizePicker({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '글자 크기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final fs in FontScale.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onChange(fs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 10),
                        decoration: BoxDecoration(
                          color: value == fs
                              ? const Color(0xFFF0F7F5)
                              : const Color(0xFFFCFAF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: value == fs
                                ? AppColors.teal
                                : AppColors.border,
                            width: value == fs ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '가',
                              style: TextStyle(
                                fontSize: fs.sampleSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              fs.label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
