import 'package:flutter/material.dart';

import '../services/memo_store.dart';
import '../theme/app_settings.dart';
import '../theme/colors.dart';
import 'calendar/calendar_screen.dart';
import 'calendar/day_detail_sheet.dart';
import 'gallery/gallery_screen.dart';
import 'quick_photo/quick_photo_flow.dart';
import 'quick_text/quick_text_flow.dart';
import 'reminders/reminders_screen.dart';
import 'settings/settings_screen.dart';

enum HomeTab { calendar, photo, reminders, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.calendar;
  bool _quickOpen = false;

  void _setQuickOpen(bool v) {
    if (_quickOpen == v) return;
    setState(() => _quickOpen = v);
  }

  void _toggleQuick() => _setQuickOpen(!_quickOpen);

  void _openQuickPhoto() {
    _setQuickOpen(false);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const QuickPhotoFlow(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openQuickText() {
    _setQuickOpen(false);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => const QuickTextFlow(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openDayDetail(DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x521F1B16),
      builder: (_) => DayDetailSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final store = MemoStoreScope.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final body = switch (_tab) {
      HomeTab.calendar => CalendarScreen(onDayTap: _openDayDetail),
      HomeTab.photo => const PhotoGalleryScreen(),
      HomeTab.reminders => const RemindersScreen(),
      HomeTab.settings => const SettingsScreen(),
    };
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      // The FAB lives in this Stack (rather than inside bottomNavigationBar)
      // so its expanded pills sit inside the body's hit-test region. When
      // they were nested in the nav bar's Stack, the pills overflowed the
      // parent bounds and clicks fell through to the calendar underneath.
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: !store.hasResolvedFirstLoad
                ? const _StoreLoadingView()
                : (store.error != null && store.isEmpty
                    ? _StoreErrorView(
                        error: store.error!,
                        onRetry: store.refresh,
                      )
                    : body),
          ),
          // Tap-catcher: tapping anywhere outside the dial closes it.
          if (_quickOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setQuickOpen(false),
              ),
            ),
          Positioned(
            right: 18,
            bottom: 84 + bottomPad,
            child: _QuickMemoFab(
              open: _quickOpen,
              onToggle: _toggleQuick,
              onText: _openQuickText,
              onCamera: _openQuickPhoto,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        tab: _tab,
        accent: settings.accent,
        onTab: (t) {
          _setQuickOpen(false);
          setState(() => _tab = t);
        },
      ),
    );
  }
}

class _StoreLoadingView extends StatelessWidget {
  const _StoreLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.teal),
          SizedBox(height: 14),
          Text(
            '기록을 불러오는 중이에요.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreErrorView extends StatelessWidget {
  final Object error;
  final Future<void> Function() onRetry;

  const _StoreErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 28,
                color: Color(0xFF9C3F3A),
              ),
              const SizedBox(height: 10),
              const Text(
                '기록을 불러오지 못했어요.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('다시 시도'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final HomeTab tab;
  final Color accent;
  final ValueChanged<HomeTab> onTab;

  const _BottomBar({
    required this.tab,
    required this.accent,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xEEFFFFFF),
        border: Border(
          top: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 8, 0, 8 + bottomPad),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _TabButton(
              active: tab == HomeTab.calendar,
              icon: Icons.calendar_today_outlined,
              label: '캘린더',
              accent: accent,
              onTap: () => onTab(HomeTab.calendar),
            ),
            _TabButton(
              active: tab == HomeTab.photo,
              icon: Icons.note_alt_outlined,
              label: '기록',
              accent: accent,
              onTap: () => onTab(HomeTab.photo),
            ),
            _TabButton(
              active: tab == HomeTab.reminders,
              icon: Icons.notifications_outlined,
              label: '리마인더',
              accent: accent,
              onTap: () => onTab(HomeTab.reminders),
            ),
            _TabButton(
              active: tab == HomeTab.settings,
              icon: Icons.settings_outlined,
              label: '설정',
              accent: accent,
              onTap: () => onTab(HomeTab.settings),
            ),
          ],
        ),
      ),
    );
  }
}

/// Speed-dial FAB. Closed: shows "QUICK MEMO" label + `+` icon. Tapping
/// flips it open: the label is replaced by Text/Camera pill buttons and the
/// icon morphs to `×`.
///
/// Layout uses a Column rather than a Stack with `Positioned` siblings —
/// otherwise the pill widgets render outside the parent's hit-test bounds
/// and taps fall through to the screen content beneath them.
class _QuickMemoFab extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onText;
  final VoidCallback onCamera;
  const _QuickMemoFab({
    required this.open,
    required this.onToggle,
    required this.onText,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    const animMs = Duration(milliseconds: 180);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pills appear above the FAB when open, and consume zero space when
        // closed. AnimatedSize provides the height transition; the children
        // animate their own opacity.
        AnimatedSize(
          duration: animMs,
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: animMs,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: open
                ? Padding(
                    key: const ValueKey('open'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QuickMemoPill(label: 'Text', onTap: onText),
                        const SizedBox(height: 8),
                        _QuickMemoPill(label: 'Camera', onTap: onCamera),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('closed'), height: 0),
          ),
        ),
        // QUICK MEMO label — only when collapsed.
        AnimatedSize(
          duration: animMs,
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: open
              ? const SizedBox.shrink()
              : const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'QUICK MEMO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.coral,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: Color(0xCCFFFFFF),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x66F57E58),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x4DF57E58),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: animMs,
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                open ? Icons.close : Icons.add,
                key: ValueKey(open),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickMemoPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickMemoPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _TabButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : AppColors.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                if (active)
                  Positioned(
                    bottom: -4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration:
                          BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
