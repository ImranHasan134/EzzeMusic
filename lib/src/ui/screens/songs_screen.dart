import 'dart:async';
import 'dart:io';

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

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgDeep    = Color(0xFF0D0D14);
  static const _bgGlass   = Color(0xFF1E1E2A);
  static const _accent    = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  Future<void> _ensureLoaded(AppState app) async {
    if (app.songsCache.isNotEmpty) return;
    await _refresh(app);
  }

  Future<void> _refresh(AppState app) async {
    setState(() { _loading = true; _error = null; });
    try {
      await app.refreshLibrarySongs();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Song> _sorted(List<Song> songs) {
    final copy = [...songs];
    copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return _sort == SongSort.za ? copy.reversed.toList() : copy;
  }

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return FutureBuilder<void>(
      future: _ensureLoaded(app),
      builder: (context, snap) {
        final songs = _sorted(app.songsCache);

        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.1,
              colors: [Color(0xFF1A1020), _bgDeep],
            ),
          ),
          child: Column(
            children: [
              // ── Header bar ───────────────────────────────────────
              _buildHeader(context, app, songs),

              // ── Error banner ─────────────────────────────────────
              if (_error != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── List / Empty state ────────────────────────────────
              Expanded(
                child: songs.isEmpty
                    ? _buildEmptyState(context, app)
                    : _buildSongList(context, app, songs, size),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, AppState app, List<Song> songs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page label
          const Text(
            'SONGS',
            style: TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),

          // Title row + controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title + count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Tracks',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Sort toggle
              _SortToggle(
                current: _sort,
                onChanged: (s) => setState(() => _sort = s),
              ),

              const SizedBox(width: 8),

              // Refresh button
              _IconCircleButton(
                onTap: _loading ? null : () => _refresh(app),
                child: _loading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _textSecondary,
                  ),
                )
                    : const Icon(Icons.refresh_rounded,
                    color: _textSecondary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Song list ────────────────────────────────────────────────────
  Widget _buildSongList(BuildContext context, AppState app,
      List<Song> songs, Size size) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        size.width * 0.04,
        4,
        size.width * 0.04,
        120,
      ),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: _divider,
        indent: 64,
      ),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SongRow(
          song: song,
          index: index,
          onPlay: () async {
            await app.player.setQueue(songs, startIndex: index);
            await app.player.play();
          },
        );
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, AppState app) {
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
            Text(
              Platform.isIOS
                  ? 'No imported songs yet'
                  : 'No songs found',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isIOS
                  ? 'Use Import to add music from Files.'
                  : 'Grant permission and refresh to scan your library.',
              style: const TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 24),
              _AccentButton(
                icon: Icons.file_upload_rounded,
                label: 'Import Songs',
                onTap: () => context.read<AppState>().importSongs(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Song Row ─────────────────────────────────────────────────────────────────

class _SongRow extends StatefulWidget {
  final Song song;
  final int index;
  final VoidCallback onPlay;

  const _SongRow({
    required this.song,
    required this.index,
    required this.onPlay,
  });

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _pressed = false;

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onPlay(); },
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
            // Index badge
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
                    widget.song.title,
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
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Play icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pressed
                    ? _accent.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: _pressed ? _accent : _textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort Toggle ───────────────────────────────────────────────────────────────

class _SortToggle extends StatelessWidget {
  final SongSort current;
  final ValueChanged<SongSort> onChanged;

  const _SortToggle({required this.current, required this.onChanged});

  static const _bgGlass   = Color(0xFF1E1E2A);
  static const _accent    = Color(0xFFFF6B35);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _divider   = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: _bgGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggle('A–Z', SongSort.az),
          Container(width: 1, height: 18, color: _divider),
          _toggle('Z–A', SongSort.za),
        ],
      ),
    );
  }

  Widget _toggle(String label, SongSort value) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 34,
        decoration: BoxDecoration(
          color: active ? _accent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? _accent : _textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _IconCircleButton({required this.child, this.onTap});

  static const _bgGlass = Color(0xFF1E1E2A);
  static const _divider = Color(0xFF252530);

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

class _AccentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const _accent = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8C5A), _accent],
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}