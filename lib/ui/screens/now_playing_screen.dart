import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../../state/player_controller.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationController;
  StreamSubscription<PlayerState>? _playerStateSub;

  static const _bgDeep        = Color(0xFF09090B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);

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

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      _playerStateSub = app.player.playerStateStream.listen((state) {
        if (state.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app    = context.read<AppState>();
    final size   = MediaQuery.of(context).size;

    return StreamBuilder<Song?>(
      // 🚨 THE MAGIC FIX: Only rebuild the screen if the actual Song ID changes!
      // This stops play/pause/seek from flashing the artwork.
      stream: app.player.currentSongStream.distinct((prev, next) => prev?.id == next?.id),
      initialData: app.player.currentSong,
      builder: (context, snapSong) {
        final Song? song = snapSong.data;
        if (song == null) {
          return const Scaffold(
              backgroundColor: _bgDeep,
              body: Center(child: Text('No song', style: TextStyle(color: _textPrimary)))
          );
        }

        final artSize = (size.width * 0.78).clamp(200.0, 360.0);
        final int parsedSongId = int.tryParse(song.id.toString()) ?? 0;

        return Scaffold(
          backgroundColor: _bgDeep,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBlurredBackground(parsedSongId),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildRotatingArtwork(artSize, parsedSongId, accent),
                      const Spacer(),
                      _buildSongInfoRow(app, song, accent),
                      const SizedBox(height: 35),
                      // Isolated Progress Section
                      _ProgressSection(app: app, song: song),
                      const SizedBox(height: 40),
                      _buildControls(app, song, accent),
                      const SizedBox(height: 40),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── The Rotating Vinyl Artwork ──────────────────────────────────

  Widget _buildRotatingArtwork(double size, int songId, Color accent) {
    return Center(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12 * _pulseAnimation.value),
                    blurRadius: 60 * _pulseAnimation.value,
                    spreadRadius: 10 * _pulseAnimation.value,
                  ),
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 20)),
                ],
              ),
              child: child,
            );
          },
          child: RotationTransition(
            turns: _rotationController,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipOval(
                  child: QueryArtworkWidget(
                    key: ValueKey('main_art_$songId'), // Forces Flutter to cache the image
                    id: songId,
                    type: ArtworkType.AUDIO,
                    artworkHeight: size,
                    artworkWidth: size,
                    artworkFit: BoxFit.cover,
                    quality: 100,
                    keepOldArtwork: true, // Prevents flashing during transitions
                    nullArtworkWidget: _buildPlaceholder(accent, size),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Other UI Components ─────────────────────────────────────────

  Widget _buildBlurredBackground(int songId) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          QueryArtworkWidget(
            key: ValueKey('bg_art_$songId'), // Forces Flutter to cache the background
            id: songId,
            type: ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
            keepOldArtwork: true,
            nullArtworkWidget: Container(color: _bgDeep),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
            child: Container(color: _bgDeep.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Color accent, double size) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF27272A), Color(0xFF18181B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.music_note_rounded, size: size * 0.35, color: accent.withOpacity(0.2)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Extract the dynamic accent color from the current theme
    final accent = Theme.of(context).colorScheme.primary;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'NOW PLAYING',
        style: TextStyle(
          color: accent.withOpacity(0.7),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildSongInfoRow(AppState app, Song song, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 38,
                child: Marquee(
                  text: "${song.title}   •   ",
                  style: const TextStyle(color: _textPrimary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  velocity: 35.0,
                  blankSpace: 30.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist.isEmpty ? 'Unknown Artist' : song.artist,
                style: TextStyle(color: accent.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Consumer<AppState>(
          builder: (context, appState, _) {
            final isFav = appState.isSongFavourited(song.id);
            return GestureDetector(
              onTap: () => isFav ? appState.removeSongFromFavourites(song.id) : appState.addCurrentSongToFavourites(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: isFav ? accent.withOpacity(0.1) : Colors.transparent),
                child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? accent : _textSecondary, size: 28),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(AppState app, Song song, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        StreamBuilder<bool>(
          stream: app.player.shuffleEnabledStream,
          builder: (_, snap) => _SecondaryButton(
            icon: Icons.shuffle_rounded, isActive: snap.data ?? false, accent: accent,
            onTap: () => app.player.setShuffleEnabled(!(snap.data ?? false)),
          ),
        ),
        _TransportButton(icon: Icons.skip_previous_rounded, size: 42, onTap: () => app.player.previous()),
        StreamBuilder<PlayerState>(
          stream: app.player.playerStateStream,
          builder: (_, snap) => _PlayButton(
            isPlaying: snap.data?.playing ?? false, accent: accent,
            onTap: () => app.player.toggle(),
          ),
        ),
        _TransportButton(icon: Icons.skip_next_rounded, size: 42, onTap: () => app.player.next()),
        StreamBuilder<PlaybackRepeatMode>(
          stream: app.player.repeatModeStream,
          builder: (_, snap) {
            final mode = snap.data ?? PlaybackRepeatMode.off;
            return _SecondaryButton(
              icon: mode == PlaybackRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              isActive: mode != PlaybackRepeatMode.off, accent: accent,
              onTap: () => app.player.cycleRepeatMode(),
            );
          },
        ),
      ],
    );
  }
}

// ── ISOLATED PROGRESS SECTION ────────────────────────────────────────

class _ProgressSection extends StatefulWidget {
  final AppState app;
  final Song song;

  const _ProgressSection({required this.app, required this.song});

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  double? _dragSeconds;

  static const _textPrimary = Color(0xFFFAFAFA);
  static const _textMuted   = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    // 1. Grab the dynamic accent color from the theme
    final accent = Theme.of(context).colorScheme.primary;

    return StreamBuilder<Duration>(
      stream: widget.app.player.positionStream,
      initialData: Duration.zero,
      builder: (context, snapPos) {
        final pos = snapPos.data ?? Duration.zero;
        final total = widget.song.duration ?? Duration.zero;
        final totalSeconds = total.inSeconds == 0 ? 1.0 : total.inSeconds.toDouble();
        final currentSeconds = _dragSeconds ?? pos.inSeconds.toDouble().clamp(0.0, totalSeconds);

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                // 2. Track is now the dynamic accent color
                activeTrackColor: accent,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                // 3. The "Seekbar Circle" (Thumb) is now strictly White
                thumbColor: Colors.white,
                overlayColor: accent.withOpacity(0.12),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                  elevation: 4, // Added slight elevation to make the white thumb pop
                ),
              ),
              child: Slider(
                min: 0,
                max: totalSeconds,
                value: currentSeconds,
                onChanged: (v) => setState(() => _dragSeconds = v),
                onChangeEnd: (v) async {
                  setState(() => _dragSeconds = null);
                  await widget.app.player.seek(Duration(seconds: v.round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(Duration(seconds: currentSeconds.round())), style: const TextStyle(color: _textMuted, fontSize: 12)),
                  Text(_formatDuration(total), style: const TextStyle(color: _textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Shared UI Components ───────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final bool isPlaying; final VoidCallback onTap; final Color accent;
  const _PlayButton({required this.isPlaying, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82, height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [accent.withOpacity(0.8), accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  final IconData icon; final double size; final VoidCallback onTap;
  const _TransportButton({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white, size: size));
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon; final bool isActive; final VoidCallback onTap; final Color accent;
  const _SecondaryButton({required this.icon, required this.isActive, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onTap, icon: Icon(icon, color: isActive ? accent : const Color(0xFF71717A), size: 26));
  }
}