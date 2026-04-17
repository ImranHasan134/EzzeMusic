import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart'; // ADDED FOR ARTWORK

import '../../state/app_state.dart';

class MiniPlayerBar extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayerBar({super.key, this.onTap});

  // ── Static Design tokens (Non-accent) ──────────────────────────
  static const _bgGlass       = Color(0xFF18181B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _divider       = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    // 1. Link to Dynamic Accent
    final accent = Theme.of(context).colorScheme.primary;
    final app = context.watch<AppState>();

    return StreamBuilder(
      stream: app.player.currentSongStream,
      initialData: app.player.currentSong,
      builder: (context, snapSong) {
        final song = snapSong.data;
        if (song == null) return const SizedBox.shrink();

        final int parsedSongId = int.tryParse(song.id.toString()) ?? 0;

        return Container(
          decoration: const BoxDecoration(
            color: _bgGlass,
            border: Border(top: BorderSide(color: _divider, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // ── Album icon (Artwork or Dynamic Glow Fallback) ──
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.12),
                            border: Border.all(color: accent.withOpacity(0.25)),
                          ),
                          child: ClipOval(
                            child: QueryArtworkWidget(
                              id: parsedSongId,
                              type: ArtworkType.AUDIO,
                              artworkHeight: 42,
                              artworkWidth: 42,
                              artworkFit: BoxFit.cover,
                              keepOldArtwork: true,
                              nullArtworkWidget: Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: accent, // DYNAMIC ACCENT FALLBACK
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ── Song info ──
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title.isEmpty ? 'Unknown Title' : song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist.isEmpty ? 'Unknown Artist' : song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        // ── Controls ──
                        _ControlButton(
                          icon: Icons.skip_previous_rounded,
                          isAccent: false,
                          accentColor: accent,
                          onTap: () => app.player.previous(),
                        ),

                        const SizedBox(width: 4),

                        StreamBuilder<PlayerState>(
                          stream: app.player.playerStateStream,
                          builder: (context, snapState) {
                            final playing = snapState.data?.playing ?? app.player.playing;
                            return _ControlButton(
                              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              isAccent: true,
                              accentColor: accent, // PASS DYNAMIC ACCENT
                              onTap: () => app.player.toggle(),
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          isAccent: false,
                          accentColor: accent,
                          onTap: () => app.player.next(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Progress bar (Dynamic Line) ──
                    _MiniProgressBar(app: app, accentColor: accent),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Control Button (Dynamic) ──────────────────────────────────────────────────

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final bool isAccent;
  final Color accentColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.isAccent,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  static const _textMuted = Color(0xFF71717A);
  static const _divider  = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isAccent
              ? (_pressed ? accent.withOpacity(0.35) : accent.withOpacity(0.18))
              : (_pressed ? _divider : Colors.transparent),
          border: widget.isAccent ? Border.all(color: accent.withOpacity(0.35)) : null,
        ),
        child: Icon(
          widget.icon,
          color: widget.isAccent ? accent : _textMuted, // DYNAMIC ACCENT
          size: widget.isAccent ? 20 : 18,
        ),
      ),
    );
  }
}

// ── Mini Progress Bar (Dynamic) ───────────────────────────────────────────────

class _MiniProgressBar extends StatelessWidget {
  final AppState app;
  final Color accentColor;

  const _MiniProgressBar({required this.app, required this.accentColor});

  static const _divider = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: app.player.durationStream,
      builder: (context, snapDur) {
        final duration = snapDur.data ?? Duration.zero;
        final total = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;

        return StreamBuilder<Duration>(
          stream: app.player.positionStream,
          initialData: Duration.zero,
          builder: (context, snapPos) {
            final pos   = snapPos.data ?? Duration.zero;
            final ratio = (pos.inMilliseconds / total).clamp(0.0, 1.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: _divider,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor), // DYNAMIC ACCENT
                ),
              ),
            );
          },
        );
      },
    );
  }
}