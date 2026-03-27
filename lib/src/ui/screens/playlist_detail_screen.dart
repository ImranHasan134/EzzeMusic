import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';
import '../widgets/mini_song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgDeep        = Color(0xFF09090B);
  static const _bgGlass       = Color(0xFF18181B);
  static const _accent        = Color(0xFF6366F1);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _divider       = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final app      = context.watch<AppState>();
    final playlist = app.playlists.firstWhere((p) => p.id == playlistId);
    final size     = MediaQuery.of(context).size;

    final songsById = {for (final s in app.songsCache) s.id: s};
    final songs     = playlist.songIds
        .map((id) => songsById[id])
        .whereType<Song>()
        .toList();

    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: _buildAppBar(context, playlist),
      floatingActionButton: _buildFAB(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.1,
            colors: [Color(0xFF18181B), _bgDeep],
          ),
        ),
        child: SafeArea(
          child: songs.isEmpty
              ? _buildEmptyState(context)
              : _buildSongList(context, app, songs, size),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, playlist) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: _textSecondary, size: 28),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        children: [
          const Text(
            'PLAYLIST',
            style: TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            playlist.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        // Edit name
        _IconCircleButton(
          onTap: () => _renameDialog(context, playlist),
          child: const Icon(Icons.drive_file_rename_outline_rounded,
              color: _textSecondary, size: 17),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddSongs(context),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF818CF8), _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  // ── Song list ────────────────────────────────────────────────────
  Widget _buildSongList(BuildContext context, AppState app,
      List<Song> songs, Size size) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          size.width * 0.04, 8, size.width * 0.04, 120),
      itemCount: songs.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 1, color: _divider, indent: 64),
      itemBuilder: (context, index) {
        final s = songs[index];
        return _DetailSongRow(
          song: s,
          index: index,
          onPlay: () async {
            await app.player.setQueue(songs, startIndex: index);
            await app.player.play();
            if (!context.mounted) return;
            _showSnack(context, 'Now Playing: ${s.title}');
          },
          onRemove: () => context.read<AppState>().removeSongFromPlaylist(
            playlistId: playlistId,
            songId: s.id,
          ),
        );
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bgGlass,
                border: Border.all(color: _divider),
              ),
              child: const Icon(Icons.library_music_rounded,
                  size: 36, color: _textMuted),
            ),
            const SizedBox(height: 20),
            const Text(
              'No songs yet',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add songs to this playlist to get started.',
              style: TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _openAddSongs(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Add Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rename dialog ────────────────────────────────────────────────
  Future<void> _renameDialog(BuildContext context, playlist) async {
    final ctrl = TextEditingController(text: playlist.name);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => _ThemedDialog(
        title: 'Rename Playlist',
        hint: 'Playlist name',
        confirmLabel: 'Save',
        controller: ctrl,
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AppState>().renamePlaylist(playlistId, ctrl.text);
  }

  // ── Add songs bottom sheet ───────────────────────────────────────
  Future<void> _openAddSongs(BuildContext context) async {
    final app = context.read<AppState>();
    if (app.songsCache.isEmpty) await app.refreshLibrarySongs();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _AddSongsSheet(playlistId: playlistId),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: _bgGlass,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Detail Song Row ───────────────────────────────────────────────────────────

class _DetailSongRow extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  const _DetailSongRow({
    required this.song,
    required this.index,
    required this.onPlay,
    required this.onRemove,
  });

  @override
  State<_DetailSongRow> createState() => _DetailSongRowState();
}

class _DetailSongRowState extends State<_DetailSongRow> {
  bool _pressed = false;

  static const _bgGlass       = Color(0xFF18181B);
  static const _accent        = Color(0xFF6366F1);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPlay();
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
            // Index
            SizedBox(
              width: 36,
              child: Text(
                '${widget.index + 1}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: 10),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Remove button
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: Colors.redAccent.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Songs Bottom Sheet ────────────────────────────────────────────────────

class _AddSongsSheet extends StatelessWidget {
  final String playlistId;

  const _AddSongsSheet({required this.playlistId});

  static const _bgGlass       = Color(0xFF18181B);
  static const _accent        = Color(0xFF6366F1);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _divider       = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final songs = context.watch<AppState>().songsCache;
    final size  = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ADD SONGS',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${songs.length} available',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgGlass,
                      border: Border.all(color: _divider),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: _textSecondary, size: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _divider),

          // List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  size.width * 0.04, 8, size.width * 0.04, 32),
              itemCount: songs.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: _divider, indent: 60),
              itemBuilder: (context, index) {
                final s = songs[index];
                return _AddSongRow(
                  song: s,
                  index: index,
                  onAdd: () => context.read<AppState>().addSongToPlaylist(
                    playlistId: playlistId,
                    songId: s.id,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Song Row ──────────────────────────────────────────────────────────────

class _AddSongRow extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onAdd;

  const _AddSongRow({
    required this.song,
    required this.index,
    required this.onAdd,
  });

  @override
  State<_AddSongRow> createState() => _AddSongRowState();
}

class _AddSongRowState extends State<_AddSongRow> {
  bool _added  = false;
  bool _pressed = false;

  static const _accent        = Color(0xFF6366F1);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _bgGlass       = Color(0xFF18181B);
  static const _divider       = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed ? _bgGlass.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 36,
              child: Text(
                '${widget.index + 1}'.padLeft(2, '0'),
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: 10),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: _textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Add / Added button
            GestureDetector(
              onTap: _added
                  ? null
                  : () {
                widget.onAdd();
                setState(() => _added = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _added
                      ? _accent.withOpacity(0.15)
                      : _bgGlass,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: _added
                        ? _accent.withOpacity(0.4)
                        : _divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _added
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      color: _added ? _accent : _textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _added ? 'Added' : 'Add',
                      style: TextStyle(
                        color: _added ? _accent : _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Themed Dialog (shared) ────────────────────────────────────────────────────

class _ThemedDialog extends StatelessWidget {
  final String title;
  final String hint;
  final String confirmLabel;
  final TextEditingController controller;

  const _ThemedDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.controller,
  });

  static const _bgGlass       = Color(0xFF18181B);
  static const _accent        = Color(0xFF6366F1);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _divider       = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _bgGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF09090B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                cursorColor: _accent,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                  const TextStyle(color: _textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09090B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _divider),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF818CF8), _accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon Circle Button (shared utility) ──────────────────────────────────────

class _IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _IconCircleButton({required this.child, this.onTap});

  static const _bgGlass = Color(0xFF18181B);
  static const _divider = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgGlass,
          border: Border.all(color: _divider),
        ),
        child: Center(child: child),
      ),
    );
  }
}