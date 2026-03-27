import 'package:flutter/material.dart';

import '../../models/song.dart';

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

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgGlass       = Color(0xFF18181B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed ? _bgGlass.withOpacity(0.6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bgGlass,
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: _textMuted,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.song.title.isEmpty
                        ? 'Unknown Title'
                        : widget.song.title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.song.artist.isEmpty
                        ? 'Unknown Artist'
                        : widget.song.artist,
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

            // Trailing widget (play, remove, add, etc.)
            if (widget.trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme(
                data: const IconThemeData(
                  color: _textMuted,
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