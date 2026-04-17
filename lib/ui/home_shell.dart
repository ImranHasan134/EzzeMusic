import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../ui/screens/playlists_screen.dart';
import 'screens/songs_screen.dart';
import '../ui/screens/settings_screen.dart';
import 'screens/now_playing_screen.dart';
import '../ui/widgets/mini_player_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1;

  static const _bgDeep = Color(0xFF09090B);

  final _tabs = const <Widget>[
    NowPlayingScreen(),
    SongsScreen(),
    PlaylistsScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    (Icons.play_circle_rounded, Icons.play_circle_outline_rounded, 'Player'),
    (Icons.music_note_rounded, Icons.music_note_outlined, 'Songs'),
    (Icons.queue_music_rounded, Icons.queue_music_rounded, 'Playlists'),
    (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bgDeep,
      extendBody: true,
      body: Stack(
        children: [
          // ── 1. The Main Content (Now Static for stability) ──
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              children: _tabs,
            ),
          ),

          // ── 2. The Floating Mini Player (Animated instead of Conditional) ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 95 + (bottomPadding > 0 ? bottomPadding : 12),
            child: AnimatedOpacity(
              // Fades out instead of disappearing, keeping the layout stable
              opacity: _index == 0 ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: _index == 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MiniPlayerBar(
                    onTap: () => setState(() => _index = 0),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. The Sliding Floating Navigation Bar ──
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding > 0 ? bottomPadding : 20,
            child: _ThemedNavBar(
              selectedIndex: _index,
              destinations: _destinations,
              accentColor: accent,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Themed Sliding Nav Bar (Logic remains the same) ──────────────────────────

class _ThemedNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<(IconData, IconData, String)> destinations;
  final Color accentColor;
  final ValueChanged<int> onTap;

  const _ThemedNavBar({
    required this.selectedIndex,
    required this.destinations,
    required this.accentColor,
    required this.onTap,
  });

  static const _bgGlass = Color(0xFF18181B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: _bgGlass.withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(destinations.length, (i) {
          final (activeIcon, inactiveIcon, label) = destinations[i];
          final isSelected = selectedIndex == i;

          return _NavItem(
            activeIcon: activeIcon,
            inactiveIcon: inactiveIcon,
            label: label,
            isSelected: isSelected,
            accentColor: accentColor,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  static const _textMuted = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? accentColor : _textMuted,
              size: 24,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: isSelected
                  ? Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}