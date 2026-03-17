import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart'; // for LoopMode

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../../state/player_controller.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  StreamSubscription<int?>? _idxSub;
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    final player = context.read<AppState>().player;

    _idxSub = player.currentIndexStream.listen((idx) {
      if (!mounted) return;
      setState(() => _currentIndex = idx);
    });
  }

  @override
  void dispose() {
    _idxSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final player = appState.player;
    final theme = Theme.of(context);

    final Song? song = (_currentIndex == null ||
        _currentIndex! < 0 ||
        _currentIndex! >= player.queue.length)
        ? null
        : player.queue[_currentIndex!];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.15),
            theme.colorScheme.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              AlbumArt(theme: theme),
              const SizedBox(height: 24),
              SongInfo(song: song, theme: theme),
              const SizedBox(height: 24),
              ProgressBar(player: player, song: song),
              const SizedBox(height: 20),
              PlayerControls(player: player, song: song, theme: theme),
              const SizedBox(height: 20),
              ShuffleRepeatRow(player: player, theme: theme),
              const Spacer(),
              if (appState.songsCache.isEmpty)
                ScanSongsButton(appState: appState, context: context),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }
}

/// 🎵 Album Art
class AlbumArt extends StatelessWidget {
  final ThemeData theme;
  const AlbumArt({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: const Icon(Icons.music_note, size: 80, color: Colors.white70),
    );
  }
}

/// 🎶 Song Title & Artist
class SongInfo extends StatelessWidget {
  final Song? song;
  final ThemeData theme;
  const SongInfo({super.key, this.song, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          song?.title ?? "No song selected",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          song?.artist ?? "Unknown Artist",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// ⏱ Progress Bar
class ProgressBar extends StatelessWidget {
  final PlayerController player;
  final Song? song;

  const ProgressBar({super.key, required this.player, this.song});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: player.durationStream,
          builder: (context, durSnap) {
            final duration = durSnap.data ?? Duration.zero;

            final maxMs = duration.inMilliseconds.toDouble();
            final posMs = position.inMilliseconds
                .clamp(0, maxMs.toInt())
                .toDouble();

            return Column(
              children: [
                Slider(
                  value: posMs,
                  max: maxMs > 0 ? maxMs : 1,
                  onChanged: (song == null)
                      ? null
                      : (v) => player.seek(Duration(milliseconds: v.toInt())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(position)),
                    Text(_fmt(duration)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }
}

/// 🎮 Play / Pause Controls
class PlayerControls extends StatelessWidget {
  final PlayerController player;
  final Song? song;
  final ThemeData theme;
  const PlayerControls({
    super.key,
    required this.player,
    this.song,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: player.previous,
          icon: const Icon(Icons.skip_previous, size: 32),
        ),
        StreamBuilder<bool>(
          stream: player.playerStateStream.map((s) => s?.playing ?? false),
          builder: (context, snap) {
            final playing = snap.data ?? false;
            return GestureDetector(
              onTap: (song == null) ? null : (playing ? player.pause : player.play),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            );
          },
        ),
        IconButton(
          onPressed: player.next,
          icon: const Icon(Icons.skip_next, size: 32),
        ),
      ],
    );
  }
}

/// 🔁 Shuffle & Repeat
class ShuffleRepeatRow extends StatelessWidget {
  final PlayerController player;
  final ThemeData theme;
  const ShuffleRepeatRow({super.key, required this.player, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<bool>(
          stream: player.shuffleModeEnabledStream,
          builder: (context, snap) {
            final enabled = snap.data ?? false;
            return IconButton(
              onPressed: player.toggleShuffle,
              icon: Icon(
                Icons.shuffle,
                color: enabled ? theme.colorScheme.primary : Colors.grey,
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        StreamBuilder<LoopMode>(
          stream: player.loopModeStream,
          builder: (context, snap) {
            final mode = snap.data ?? LoopMode.off;
            return IconButton(
              onPressed: player.cycleRepeatMode,
              icon: Icon(
                mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                color: mode != LoopMode.off ? theme.colorScheme.primary : Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 📱 Scan Songs Button
class ScanSongsButton extends StatelessWidget {
  final AppState appState;
  final BuildContext context;
  const ScanSongsButton({super.key, required this.appState, required this.context});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        await appState.refreshDeviceSongs();

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appState.songsCache.isEmpty
                  ? 'No songs found (or permission denied).'
                  : 'Found ${appState.songsCache.length} songs.',
            ),
          ),
        );
      },
      icon: const Icon(Icons.refresh),
      label: const Text("Scan Device Songs"),
    );
  }
}
