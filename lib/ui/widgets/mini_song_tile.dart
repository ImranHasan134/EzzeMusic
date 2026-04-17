import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';

class MiniSongTile extends StatefulWidget {
  final Song song;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MiniSongTile({
    super.key,
    required this.song,
    this.onTap,
    this.trailing,
  });

  @override
  State<MiniSongTile> createState() => _MiniSongTileState();
}

class _MiniSongTileState extends State<MiniSongTile> {
  bool _pressed = false;

  // ── Static Design tokens ────────────────────────────────────────
  static const _bgGlass       = Color(0xFF18181B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _divider       = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    // 1. Get the global accent and current player state
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();

    // 2. Check if this specific tile is the one currently playing
    final isPlaying = app.player.currentSong?.id == widget.song.id;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          // Subtle background shift when playing or pressed
          color: isPlaying
              ? accent.withOpacity(0.05)
              : (_pressed ? _bgGlass.withOpacity(0.6) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // ── Icon Circle (Dynamic Glow) ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying ? accent.withOpacity(0.12) : _bgGlass,
                border: Border.all(
                  color: isPlaying ? accent.withOpacity(0.3) : _divider,
                ),
                // Add a very soft glow if playing
                boxShadow: isPlaying ? [
                  BoxShadow(
                    color: accent.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ] : [],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.music_note_rounded,
                color: isPlaying ? accent : _textMuted,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // ── Title + Artist ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.song.title.isEmpty ? 'Unknown Title' : widget.song.title,
                    style: TextStyle(
                      // Title turns accent color when playing
                      color: isPlaying ? accent : _textPrimary,
                      fontSize: 14,
                      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.song.artist.isEmpty ? 'Unknown Artist' : widget.song.artist,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Trailing widget (Play, Remove, Add, etc.) ──
            if (widget.trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme(
                data: IconThemeData(
                  // Trailing icons also respect the accent if active
                  color: isPlaying ? accent : _textMuted,
                  size: 20,
                ),
                child: widget.trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}