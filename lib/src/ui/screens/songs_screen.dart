import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../widgets/mini_song_tile.dart';

enum SongSort { az, za }

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  SongSort _sort = SongSort.az;
  bool _loading = false;
  String? _error;

  Future<void> _ensureLoaded(AppState app) async {
    if (app.songsCache.isNotEmpty) return;
    await _refresh(app);
  }

  Future<void> _refresh(AppState app) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await app.refreshDeviceSongs();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Song> _sorted(List<Song> songs) {
    final copy = [...songs];
    copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (_sort == SongSort.za) {
      return copy.reversed.toList();
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return FutureBuilder<void>(
      future: _ensureLoaded(app),
      builder: (context, snap) {
        final songs = _sorted(app.songsCache);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${songs.length} songs',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  SegmentedButton<SongSort>(
                    segments: const [
                      ButtonSegment(value: SongSort.az, label: Text('A–Z')),
                      ButtonSegment(value: SongSort.za, label: Text('Z–A')),
                    ],
                    selected: {_sort},
                    onSelectionChanged: (s) =>
                        setState(() => _sort = s.first),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : () => _refresh(app),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: songs.isEmpty
                  ? const Center(
                      child: Text('No device songs found.'),
                    )
                  : ListView.separated(
                      itemCount: songs.length,
                      separatorBuilder: (context, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return MiniSongTile(
                          song: song,
                          trailing: IconButton(
                            tooltip: 'Play',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () async {
                              await app.player.setQueue(songs, startIndex: index);
                              await app.player.play();
                            },
                          ),
                          onTap: () async {
                            await app.player.setQueue(songs, startIndex: index);
                            await app.player.play();
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

