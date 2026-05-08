import 'package:flutter/material.dart';

import '../theme/app_settings.dart';
import '../theme/colors.dart';
import 'calendar/calendar_screen.dart';
import 'calendar/day_detail_sheet.dart';
import 'gallery/gallery_screen.dart';
import 'quick_photo/quick_photo_flow.dart';
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

  void _openQuickPhoto() {
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

  void _openDayDetail(DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0x521F1B16),
      builder: (_) => DayDetailSheet(
        day: day,
        onAddPhoto: () {
          Navigator.of(context).pop();
          _openQuickPhoto();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: switch (_tab) {
          HomeTab.calendar => CalendarScreen(onDayTap: _openDayDetail),
          HomeTab.photo => const PhotoGalleryScreen(),
          HomeTab.reminders => const RemindersScreen(),
          HomeTab.settings => const SettingsScreen(),
        },
      ),
      bottomNavigationBar: _BottomBar(
        tab: _tab,
        accent: settings.accent,
        onTab: (t) => setState(() => _tab = t),
        onQuickPhoto: _openQuickPhoto,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final HomeTab tab;
  final Color accent;
  final ValueChanged<HomeTab> onTab;
  final VoidCallback onQuickPhoto;

  const _BottomBar({
    required this.tab,
    required this.accent,
    required this.onTab,
    required this.onQuickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 60 + bottomPad + 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
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
                      icon: Icons.photo_outlined,
                      label: '사진',
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
            ),
          ),
          // Floating Quick Photo
          Positioned(
            right: 18,
            top: -8,
            child: GestureDetector(
              onTap: onQuickPhoto,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      boxShadow: const [
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
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Positioned(
                    top: -22,
                    child: Text(
                      'QUICK',
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
                ],
              ),
            ),
          ),
        ],
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
