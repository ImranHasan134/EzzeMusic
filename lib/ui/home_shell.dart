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
  int _index = 1; // Default to Songs tab

  static const _bgDeep = Color(0xFF09090B);

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
    // Grab the dynamic accent from the theme we set in main.dart
    final accent = Theme.of(context).colorScheme.primary;

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
            // Show mini player only when not on the NowPlayingScreen (index 0)
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
        accentColor: accent,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ── Themed Nav Bar ────────────────────────────────────────────────────────────

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
  static const _divider = Color(0xFF27272A);

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
              accentColor: accentColor,
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

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  static const _textMuted = Color(0xFF71717A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    final accent = widget.accentColor;

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
              // Pill indicator + icon with Dynamic Glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? accent.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  // ADDED: Subtle glow for the luxury feel
                  boxShadow: widget.isSelected ? [
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                child: Icon(
                  widget.isSelected
                      ? widget.activeIcon
                      : widget.inactiveIcon,
                  color: widget.isSelected ? accent : _textMuted,
                  size: 24,
                ),
              ),

              const SizedBox(height: 4),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected ? accent : _textMuted,
                  fontSize: 10,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  letterSpacing: 0.2,
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