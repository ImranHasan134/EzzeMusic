import 'package:flutter/material.dart';
import 'screens/playlists_screen.dart';
import 'screens/songs_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/mini_player_bar.dart';

enum HomeTab { player, songs, playlists, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgDeep        = Color(0xFF0D0D14);
  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  final _tabs = const <Widget>[
    NowPlayingScreen(),
    SongsScreen(),
    PlaylistsScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    (Icons.play_circle_rounded,     Icons.play_circle_outline_rounded, 'Player'),
    (Icons.music_note_rounded,      Icons.music_note_outlined,         'Songs'),
    (Icons.queue_music_rounded,     Icons.queue_music_rounded,         'Playlists'),
    (Icons.settings_rounded,        Icons.settings_outlined,           'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: _tabs,
              ),
            ),
            if (_index != 0)
              MiniPlayerBar(
                onTap: () => setState(() => _index = 0),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _ThemedNavBar(
        selectedIndex: _index,
        destinations: _destinations,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ── Themed Nav Bar ────────────────────────────────────────────────────────────

class _ThemedNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<(IconData, IconData, String)> destinations;
  final ValueChanged<int> onTap;

  const _ThemedNavBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onTap,
  });

  static const _bgGlass  = Color(0xFF1E1E2A);
  static const _accent   = Color(0xFFFF6B35);
  static const _textMuted = Color(0xFF4A4A5A);
  static const _divider  = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _bgGlass,
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 10,
          bottom: bottomPadding > 0 ? bottomPadding : 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(destinations.length, (i) {
            final (activeIcon, inactiveIcon, label) = destinations[i];
            final isSelected = selectedIndex == i;

            return _NavItem(
              activeIcon: activeIcon,
              inactiveIcon: inactiveIcon,
              label: label,
              isSelected: isSelected,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  static const _accent        = Color(0xFFFF6B35);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill indicator + icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? _accent.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  widget.isSelected
                      ? widget.activeIcon
                      : widget.inactiveIcon,
                  color: widget.isSelected ? _accent : _textMuted,
                  size: 24,
                ),
              ),

              const SizedBox(height: 3),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected ? _accent : _textMuted,
                  fontSize: 10,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}