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
  static const _bgDeep        = Color(0xFF0D0D14);
  static const _bgCard        = Color(0xFF16161F);
  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _accentSoft    = Color(0xFF1103FA);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

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

    // ── Wrap entire screen in currentSongStream ──────────────────
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
        final artSize   = (size.width * 0.55).clamp(140.0, 260.0);
        final isCompact = size.height < 680;

        return Scaffold(
          backgroundColor: _bgDeep,
          appBar: _buildAppBar(context),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [Color(0xFF1A1020), _bgDeep],
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
                            horizontal: size.width * 0.07,
                            vertical: isCompact ? 12 : 20,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: isCompact ? 8 : 16),

                              // ── Album Artwork ──────────────
                              _buildArtwork(artSize, app, song),

                              SizedBox(height: isCompact ? 20 : 32),

                              // ── Song Info ──────────────────
                              _buildSongInfo(song),

                              SizedBox(height: isCompact ? 20 : 32),

                              // ── Progress Slider ────────────
                              _buildProgressSection(app, song),

                              SizedBox(height: isCompact ? 20 : 32),

                              // ── Controls ───────────────────
                              _buildControls(app, song, context),

                              SizedBox(height: isCompact ? 12 : 20),
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
      title: const Text(
        'NOW PLAYING',
        style: TextStyle(
          color: _textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
    );
  }

  // ── Artwork ──────────────────────────────────────────────────────
  Widget _buildArtwork(double size, AppState app, Song song) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: size + 32,
            height: size + 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accentSoft
                      .withOpacity(0.18 * _pulseAnimation.value),
                  blurRadius: 60 * _pulseAnimation.value,
                  spreadRadius: 8 * _pulseAnimation.value,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1F35), Color(0xFF1A1025)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _accent.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              Icon(
                Icons.music_note_rounded,
                size: size * 0.38,
                color: _accent.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Song Info ────────────────────────────────────────────────────
  Widget _buildSongInfo(Song song) {
    return Column(
      children: [
        Text(
          song.title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          song.artist.isEmpty ? 'Unknown Artist' : song.artist,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16),
                    activeTrackColor: _accent,
                    inactiveTrackColor: _divider,
                    thumbColor: _accent,
                    overlayColor: _accent.withOpacity(0.2),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(
                            milliseconds:
                            (posSeconds * 1000).round())),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
    return Column(
      children: [
        // ── Main transport row ──
        Row(
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
              size: 32,
              onTap: () => app.player.previous(),
            ),

            // Play / Pause
            StreamBuilder<PlayerState>(
              stream: app.player.playerStateStream,
              initialData: PlayerState(
                  app.player.playing, ProcessingState.ready),
              builder: (ctx, snap) {
                final playing =
                    snap.data?.playing ?? app.player.playing;
                return _PlayButton(
                  isPlaying: playing,
                  onTap: () => app.player.toggle(),
                );
              },
            ),

            // Next
            _TransportButton(
              icon: Icons.skip_next_rounded,
              size: 32,
              onTap: () => app.player.next(),
            ),

            // Repeat
            StreamBuilder<PlaybackRepeatMode>(
              stream: app.player.repeatModeStream,
              initialData: app.player.repeatMode,
              builder: (ctx, snap) {
                final mode =
                    snap.data ?? PlaybackRepeatMode.off;
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
        ),

        const SizedBox(height: 24),

        // ── Favourite pill ──
        _buildFavouritePill(app, song, context),
      ],
    );
  }

  // ── Favourite pill ───────────────────────────────────────────────
  Widget _buildFavouritePill(
      AppState app, Song song, BuildContext context) {
    final isFav = app.isSongFavourited(song.id);
    return GestureDetector(
      onTap: () async {
        final wasFav = app.isSongFavourited(song.id);
        if (wasFav) {
          await context.read<AppState>().removeSongFromFavourites(song.id);
        } else {
          await context.read<AppState>().addCurrentSongToFavourites();
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasFav ? 'Removed from Favourites' : 'Added to Favourites',
              style: const TextStyle(color: _textPrimary), // ← add this
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _bgGlass,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isFav ? _accent.withOpacity(0.15) : _bgGlass,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isFav ? _accent.withOpacity(0.4) : _divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFav ? _accent : _textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isFav ? 'In Favourites' : 'Add to Favourites',
              style: TextStyle(
                color: isFav ? _accent : _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
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

  static const _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8C5A), _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.45),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 34,
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
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E2A),
          border:
          Border.all(color: const Color(0xFF252530), width: 1),
        ),
        child: Icon(icon,
            color: const Color(0xFFF0F0F5), size: size),
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

  static const _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          color: isActive ? _accent : const Color(0xFF4A4A5A),
          size: 22,
        ),
      ),
    );
  }
}