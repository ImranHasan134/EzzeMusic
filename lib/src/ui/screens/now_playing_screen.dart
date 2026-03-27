import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../state/app_state.dart';
import '../../state/player_controller.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  double? _dragSeconds;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgDeep        = Color(0xFF09090B);
  static const _bgGlass       = Color(0xFF18181B);
  static const _accent        = Color(0xFF6366F1);
  static const _accentSoft    = Color(0xFF818CF8);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _divider       = Color(0xFF27272A);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return StreamBuilder(
      stream: app.player.currentSongStream,
      initialData: app.player.currentSong,
      builder: (context, snapSong) {
        final Song? song = snapSong.data;

        if (song == null) {
          return Scaffold(
            backgroundColor: _bgDeep,
            appBar: _buildAppBar(context),
            body: const Center(
              child: Text(
                'No song is playing',
                style: TextStyle(color: _textSecondary),
              ),
            ),
          );
        }

        // Responsive sizing
        final artSize   = (size.width * 0.75).clamp(200.0, 360.0);
        final isCompact = size.height < 680;

        return Scaffold(
          backgroundColor: _bgDeep,
          appBar: _buildAppBar(context),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.2,
                colors: [Color(0xFF18181B), _bgDeep],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.08,
                            vertical: isCompact ? 12 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isCompact ? 8 : 16),

                              // ── Album Artwork ──────────────
                              _buildArtwork(artSize, app, song),

                              const Spacer(),
                              SizedBox(height: isCompact ? 20 : 36),

                              // ── Song Info & Favorite ────────
                              _buildSongInfoRow(app, song, context),

                              SizedBox(height: isCompact ? 20 : 32),

                              // ── Progress Slider ────────────
                              _buildProgressSection(app, song),

                              SizedBox(height: isCompact ? 20 : 32),

                              // ── Controls ───────────────────
                              _buildControls(app, song, context),

                              SizedBox(height: isCompact ? 20 : 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary, size: 28),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'NOW PLAYING',
        style: TextStyle(
          color: _textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, color: _textSecondary),
          onPressed: () {}, // Future menu actions
        ),
      ],
    );
  }

  // ── Artwork (Modern Rounded Rectangle) ───────────────────────────
  Widget _buildArtwork(double size, AppState app, Song song) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _accentSoft.withOpacity(0.12 * _pulseAnimation.value),
                  blurRadius: 60 * _pulseAnimation.value,
                  spreadRadius: 8 * _pulseAnimation.value,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFF27272A), Color(0xFF18181B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.music_note_rounded,
              size: size * 0.35,
              color: _textMuted.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ── Song Info Row (Title, Artist, and Heart Icon) ────────────────
  // ── Song Info Row (Title, Artist, and Heart Icon) ────────────────
  Widget _buildSongInfoRow(AppState app, Song song, BuildContext context) {
    final isFav = app.isSongFavourited(song.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use our new Marquee widget for the Title
              _MarqueeText(
                text: song.title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Use our new Marquee widget for the Artist
              _MarqueeText(
                text: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Inline Favorite Button
        GestureDetector(
          onTap: () async {
            final wasFav = app.isSongFavourited(song.id);
            if (wasFav) {
              await context.read<AppState>().removeSongFromFavourites(song.id);
            } else {
              await context.read<AppState>().addCurrentSongToFavourites();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFav ? _accent.withOpacity(0.15) : Colors.transparent,
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? _accent : _textSecondary,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress Section ─────────────────────────────────────────────
  Widget _buildProgressSection(AppState app, Song song) {
    return StreamBuilder<Duration?>(
      stream: app.player.durationStream,
      initialData: null,
      builder: (context, snapDur) {
        final duration = snapDur.data ?? song.duration ?? Duration.zero;
        final totalSeconds = duration.inMilliseconds == 0
            ? 1.0
            : duration.inMilliseconds / 1000.0;

        return StreamBuilder<Duration>(
          stream: app.player.positionStream,
          initialData: Duration.zero,
          builder: (context, snapPos) {
            final pos = snapPos.data ?? Duration.zero;
            final posSeconds = _dragSeconds ??
                (pos.inMilliseconds / 1000.0).clamp(0.0, totalSeconds);

            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4, // Slightly thicker track
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5), // Smaller, sleeker thumb
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: _textPrimary, // White track for premium feel
                    inactiveTrackColor: _divider,
                    thumbColor: _textPrimary,
                    overlayColor: _textPrimary.withOpacity(0.1),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalSeconds,
                    value: posSeconds,
                    onChanged: (v) => setState(() => _dragSeconds = v),
                    onChangeEnd: (v) async {
                      setState(() => _dragSeconds = null);
                      await app.player.seek(
                        Duration(milliseconds: (v * 1000).round()),
                      );
                    },
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -6), // Pull text closer to the slider
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(Duration(milliseconds: (posSeconds * 1000).round())),
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Controls ─────────────────────────────────────────────────────
  Widget _buildControls(AppState app, Song song, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Shuffle
        StreamBuilder<bool>(
          stream: app.player.shuffleEnabledStream,
          initialData: app.player.shuffleEnabled,
          builder: (ctx, snap) {
            final enabled = snap.data ?? false;
            return _SecondaryButton(
              icon: Icons.shuffle_rounded,
              isActive: enabled,
              onTap: () => app.player.setShuffleEnabled(!enabled),
            );
          },
        ),

        // Previous
        _TransportButton(
          icon: Icons.skip_previous_rounded,
          size: 36,
          onTap: () => app.player.previous(),
        ),

        // Play / Pause
        StreamBuilder<PlayerState>(
          stream: app.player.playerStateStream,
          initialData: PlayerState(app.player.playing, ProcessingState.ready),
          builder: (ctx, snap) {
            final playing = snap.data?.playing ?? app.player.playing;
            return _PlayButton(
              isPlaying: playing,
              onTap: () => app.player.toggle(),
            );
          },
        ),

        // Next
        _TransportButton(
          icon: Icons.skip_next_rounded,
          size: 36,
          onTap: () => app.player.next(),
        ),

        // Repeat
        StreamBuilder<PlaybackRepeatMode>(
          stream: app.player.repeatModeStream,
          initialData: app.player.repeatMode,
          builder: (ctx, snap) {
            final mode = snap.data ?? PlaybackRepeatMode.off;
            final icon = mode == PlaybackRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded;
            return _SecondaryButton(
              icon: icon,
              isActive: mode != PlaybackRepeatMode.off,
              onTap: () => app.player.cycleRepeatMode(),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Reusable control widgets ──────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({required this.isPlaying, required this.onTap});

  static const _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 76, // Slightly larger for emphasis
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF818CF8), _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _TransportButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Expands tap target area
        child: Icon(
          icon,
          color: const Color(0xFFFAFAFA),
          size: size,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  static const _accent = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: isActive ? _accent : const Color(0xFF71717A),
          size: 24, // Slightly smaller than primary transport controls
        ),
      ),
    );
  }
}

// ── Auto-Scrolling Marquee Text ───────────────────────────────────────────────

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startScrolling();
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the song changes, reset the scroll position to the start immediately
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    while (mounted) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {

        final maxScroll = _scrollController.position.maxScrollExtent;
        // Calculate duration based on text length so speed is always consistent
        final duration = Duration(milliseconds: (maxScroll * 30).toInt());

        // Scroll to the end
        await _scrollController.animateTo(
          maxScroll,
          duration: duration,
          curve: Curves.linear,
        );

        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Scroll back to the start
        await _scrollController.animateTo(
          0,
          duration: duration,
          curve: Curves.linear,
        );

        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 1));
      } else {
        // If text is short and doesn't overflow, just wait and check again later
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Prevents user swiping it
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}