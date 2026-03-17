import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../widgets/mini_song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final playlist = app.playlists.firstWhere((p) => p.id == playlistId);

    final songsById = {for (final s in app.songsCache) s.id: s};
    final songs = playlist.songIds
        .map((id) => songsById[id])
        .whereType<Song>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            tooltip: 'Edit name',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ctrl = TextEditingController(text: playlist.name);
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Rename playlist'),
                  content: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Playlist name'),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                if (!context.mounted) return;
                await context
                    .read<AppState>()
                    .renamePlaylist(playlistId, ctrl.text);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add songs',
        onPressed: () => _openAddSongs(context),
        child: const Icon(Icons.add),
      ),
      body: songs.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('No songs in this playlist.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openAddSongs(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add songs'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = songs[index];
                return MiniSongTile(
                  song: s,
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => context.read<AppState>().removeSongFromPlaylist(
                          playlistId: playlistId,
                          songId: s.id,
                        ),
                  ),
                  onTap: () async {
                    await app.player.setQueue(songs, startIndex: index);
                    await app.player.play();
                  },
                );
              },
            ),
    );
  }

  Future<void> _openAddSongs(BuildContext context) async {
    final app = context.read<AppState>();
    if (app.songsCache.isEmpty) {
      await app.refreshDeviceSongs();
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final songs = context.watch<AppState>().songsCache;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add songs',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: songs.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = songs[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(
                          s.title.isEmpty ? 'Unknown title' : s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          s.artist.isEmpty ? 'Unknown artist' : s.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Add',
                          icon: const Icon(Icons.add),
                          onPressed: () => context.read<AppState>().addSongToPlaylist(
                                playlistId: playlistId,
                                songId: s.id,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

