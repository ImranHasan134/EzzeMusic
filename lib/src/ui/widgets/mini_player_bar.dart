import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class MiniPlayerBar extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayerBar({super.key, this.onTap});

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return StreamBuilder(
      stream: app.player.currentSongStream,
      initialData: app.player.currentSong,
      builder: (context, snapSong) {
        final song = snapSong.data;
        if (song == null) return const SizedBox.shrink();

        return Container(
          decoration: const BoxDecoration(
            color: _bgGlass,
            border: Border(
              top: BorderSide(color: _divider, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // ── Album icon ─────────────────────────
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent.withOpacity(0.12),
                            border: Border.all(
                              color: _accent.withOpacity(0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: _accent,
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ── Song info ──────────────────────────
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title.isEmpty
                                    ? 'Unknown Title'
                                    : song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist.isEmpty
                                    ? 'Unknown Artist'
                                    : song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Controls ───────────────────────────
                        StreamBuilder(
                          stream: app.player.playerStateStream,
                          initialData: app.player.playing
                              ? PlayerState(true, ProcessingState.ready)
                              : PlayerState(false, ProcessingState.idle),
                          builder: (context, snapState) {
                            final playing =
                                snapState.data?.playing ??
                                    app.player.playing;
                            return _ControlButton(
                              icon: playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              isAccent: true,
                              onTap: () => app.player.toggle(),
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          isAccent: false,
                          onTap: () => app.player.next(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Progress bar ───────────────────────────
                    _MiniProgressBar(app: app),
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

// ── Control Button ────────────────────────────────────────────────────────────

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final bool isAccent;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.isAccent,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  static const _accent   = Color(0xFFFF6B35);
  static const _textMuted = Color(0xFF4A4A5A);
  static const _divider  = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isAccent
              ? (_pressed
              ? _accent.withOpacity(0.35)
              : _accent.withOpacity(0.18))
              : (_pressed
              ? _divider
              : Colors.transparent),
          border: widget.isAccent
              ? Border.all(color: _accent.withOpacity(0.35))
              : null,
        ),
        child: Icon(
          widget.icon,
          color: widget.isAccent ? _accent : _textMuted,
          size: widget.isAccent ? 20 : 18,
        ),
      ),
    );
  }
}

// ── Mini Progress Bar ─────────────────────────────────────────────────────────

class _MiniProgressBar extends StatelessWidget {
  final AppState app;

  const _MiniProgressBar({required this.app});

  static const _accent  = Color(0xFFFF6B35);
  static const _divider = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: app.player.durationStream,
      initialData: null,
      builder: (context, snapDur) {
        final duration = snapDur.data ?? Duration.zero;
        final total = duration.inMilliseconds == 0
            ? 1
            : duration.inMilliseconds;

        return StreamBuilder<Duration>(
          stream: app.player.positionStream,
          initialData: Duration.zero,
          builder: (context, snapPos) {
            final pos     = snapPos.data ?? Duration.zero;
            final ratio   = (pos.inMilliseconds / total).clamp(0.0, 1.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: _divider,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            );
          },
        );
      },
    );
  }
}