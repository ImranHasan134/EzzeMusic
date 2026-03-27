import 'dart:ui';
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
    with TickerProviderStateMixin { // Updated to TickerProvider for multiple controllers
  double? _dragSeconds;

  // ── Animations ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationController;

  static const _bgDeep        = Color(0xFF09090B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);

  @override
  void initState() {
    super.initState();

    // 1. Pulse Animation (The Glow)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Rotation Animation (The Vinyl Spin)
    // 20 seconds per full rotation for a smooth, realistic feel
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app    = context.read<AppState>();
    final size   = MediaQuery.of(context).size;

    return StreamBuilder<PlayerState>(
      stream: app.player.playerStateStream,
      builder: (context, snapState) {
        // ── Rotation Logic ──
        // This ensures the record spins ONLY when music is actually playing
        final isPlaying = snapState.data?.playing ?? false;
        if (isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }

        return StreamBuilder<Song?>(
          stream: app.player.currentSongStream,
          initialData: app.player.currentSong,
          builder: (context, snapSong) {
            final Song? song = snapSong.data;
            if (song == null) return const Scaffold(backgroundColor: _bgDeep, body: Center(child: Text('No song')));

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
                          _buildProgressSection(app, song),
                          const SizedBox(height: 40),
                          _buildControls(app, song, accent),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
            turns: _rotationController, // The secret sauce
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipOval(
                  child: QueryArtworkWidget(
                    id: songId,
                    type: ArtworkType.AUDIO,
                    artworkHeight: size,
                    artworkWidth: size,
                    artworkFit: BoxFit.cover,
                    quality: 100,
                    nullArtworkWidget: _buildPlaceholder(accent, size),
                  ),
                ),
                // The Rim Overlay for perfect edges
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

  // ── Other UI Components (Background, Info, Progress, Controls) ──

  Widget _buildBlurredBackground(int songId) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          QueryArtworkWidget(
            id: songId,
            type: ArtworkType.AUDIO,
            artworkFit: BoxFit.cover,
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

  // ... (Keep your existing _buildAppBar, _buildSongInfoRow, _buildProgressSection, _buildControls)
  // Just make sure to include the helper classes below!

  Widget _buildPlaceholder(Color accent, double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [const Color(0xFF27272A), const Color(0xFF18181B)],
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
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary, size: 32),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text('NOW PLAYING', style: TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 4)),
      actions: [
        IconButton(icon: const Icon(Icons.more_vert_rounded, color: _textSecondary), onPressed: () {}),
      ],
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

  Widget _buildProgressSection(AppState app, Song song) {
    return StreamBuilder<Duration>(
      stream: app.player.positionStream,
      initialData: Duration.zero,
      builder: (context, snapPos) {
        final pos = snapPos.data ?? Duration.zero;
        final total = song.duration ?? Duration.zero;
        final totalSeconds = total.inSeconds == 0 ? 1.0 : total.inSeconds.toDouble();
        final currentSeconds = _dragSeconds ?? pos.inSeconds.toDouble().clamp(0.0, totalSeconds);

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: _textPrimary,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: _textPrimary,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                min: 0, max: totalSeconds, value: currentSeconds,
                onChanged: (v) => setState(() => _dragSeconds = v),
                onChangeEnd: (v) async {
                  setState(() => _dragSeconds = null);
                  await app.player.seek(Duration(seconds: v.round()));
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Shared UI Components (Keep these exactly as they are) ──────────

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
  Widget build(BuildContext context) { return IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white, size: size)); }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon; final bool isActive; final VoidCallback onTap; final Color accent;
  const _SecondaryButton({required this.icon, required this.isActive, required this.onTap, required this.accent});
  @override
  Widget build(BuildContext context) { return IconButton(onPressed: onTap, icon: Icon(icon, color: isActive ? accent : const Color(0xFF71717A), size: 26)); }
}