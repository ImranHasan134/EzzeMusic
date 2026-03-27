import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../state/app_state.dart';

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

  // ── Search Logic ──
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Design tokens ──
  static const _bgDeep        = Color(0xFF09090B);
  static const _bgGlass       = Color(0xFF18181B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);
  static const _divider       = Color(0xFF27272A);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded(AppState app) async {
    if (app.songsCache.isNotEmpty) return;
    await app.refreshLibrarySongs(forceRescan: false);
  }

  Future<void> _refresh(AppState app, {bool forceRescan = true}) async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      await app.refreshLibrarySongs(forceRescan: forceRescan);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Song> _getFilteredAndSorted(List<Song> songs) {
    // Filter based on search query
    List<Song> filtered = songs.where((song) {
      final title = song.title.toLowerCase();
      final artist = song.artist.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || artist.contains(query);
    }).toList();

    // Sort alphabetically
    filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return _sort == SongSort.za ? filtered.reversed.toList() : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final app    = context.watch<AppState>();
    final size   = MediaQuery.of(context).size;

    return FutureBuilder<void>(
      future: _ensureLoaded(app),
      builder: (context, snap) {
        final displaySongs = _getFilteredAndSorted(app.songsCache);

        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.1,
              colors: [Color(0xFF18181B), _bgDeep],
            ),
          ),
          child: Column(
            children: [
              // ── Header (Title + Search) ──
              _buildHeader(context, app, displaySongs, accent),

              if (_error != null) _buildErrorBanner(),

              // ── List Area ──
              Expanded(
                child: RefreshIndicator(
                  color: accent,
                  backgroundColor: _bgGlass,
                  strokeWidth: 2.5,
                  onRefresh: () => _refresh(app, forceRescan: true),
                  child: displaySongs.isEmpty && !_loading
                      ? _buildEmptyState(context, app, accent)
                      : _buildSongList(context, app, displaySongs, size, accent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppState app, List<Song> songs, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SONGS',
            style: TextStyle(
              color: accent.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),

          // ── Luxury Search Bar ──
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: _bgGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _divider),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'Search titles or artists...',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: accent.withOpacity(0.5), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchQuery.isEmpty ? 'Your Tracks' : 'Search Results',
                      style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${songs.length} songs',
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _SortToggle(
                current: _sort,
                accentColor: accent,
                onChanged: (s) => setState(() => _sort = s),
              ),
              const SizedBox(width: 8),
              _IconCircleButton(
                onTap: _loading ? null : () => _refresh(app, forceRescan: true),
                child: _loading
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                    : const Icon(Icons.refresh_rounded, color: _textSecondary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongList(BuildContext context, AppState app, List<Song> songs, Size size, Color accent) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(size.width * 0.04, 4, size.width * 0.04, 120),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _divider, indent: 64),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SongRow(
          song: song,
          index: index,
          accentColor: accent,
          onPlay: () async {
            await app.player.setQueue(songs, startIndex: index);
            await app.player.play();
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState app, Color accent) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.library_music_rounded : Icons.search_off_rounded,
                size: 64,
                color: _textMuted.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'No songs found' : 'No results for "$_searchQuery"',
                style: const TextStyle(color: _textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              if (Platform.isIOS && _searchQuery.isEmpty) ...[
                const SizedBox(height: 24),
                _AccentButton(
                  icon: Icons.file_upload_rounded,
                  label: 'Import Songs',
                  accentColor: accent,
                  onTap: () => app.importSongs(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ],
      ),
    );
  }
}

// ── Song Row ─────────────────────────────────────────────────────────────────

class _SongRow extends StatefulWidget {
  final Song song;
  final int index;
  final Color accentColor;
  final VoidCallback onPlay;

  const _SongRow({
    required this.song,
    required this.index,
    required this.accentColor,
    required this.onPlay,
  });

  @override
  State<_SongRow> createState() => _SongRowState();
}

class _SongRowState extends State<_SongRow> {
  bool _pressed = false;

  static const _bgGlass       = Color(0xFF18181B);
  static const _textPrimary   = Color(0xFFFAFAFA);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _textMuted     = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.watch<AppState>().player.currentSong?.id == widget.song.id;
    final accent = widget.accentColor;

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
          color: _pressed || isPlaying ? _bgGlass.withOpacity(0.6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${widget.index + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  color: isPlaying ? accent : _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: TextStyle(
                      color: isPlaying ? accent : _textPrimary,
                      fontSize: 14,
                      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.song.artist.isEmpty ? 'Unknown Artist' : widget.song.artist,
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying ? accent.withOpacity(0.15) : Colors.transparent,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? accent : _textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort Toggle ──────────────────────────────────────────────────────────────

class _SortToggle extends StatelessWidget {
  final SongSort current;
  final Color accentColor;
  final ValueChanged<SongSort> onChanged;

  const _SortToggle({
    required this.current,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggle('A–Z', SongSort.az),
          Container(width: 1, height: 18, color: const Color(0xFF27272A)),
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
          color: active ? accentColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? accentColor : const Color(0xFFA1A1AA),
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _IconCircleButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF18181B),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _AccentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _AccentButton({required this.icon, required this.label, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.8), accentColor],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}