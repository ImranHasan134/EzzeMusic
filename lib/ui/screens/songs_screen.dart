import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // ── Search & Scroll Logic ──
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  // ── High Performance Caching (Fixes App Freezing) ──
  List<Song>? _lastCache;
  String _lastQuery = '';
  SongSort _lastSort = SongSort.az;
  List<Song> _cachedDisplaySongs = [];

  // ── Bulk Selection State ──
  final Set<int> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  // ── Alphabet Scrollbar State ──
  bool _isDraggingAlpha = false;
  String _currentAlpha = '';
  final List<String> _alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#".split('');

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
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color accent) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 14)),
          backgroundColor: _bgGlass,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: accent.withOpacity(0.3))),
          elevation: 8,
        )
    );
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

  // Blazing fast memoized sorting to prevent main thread ANR crashes
  List<Song> _getFilteredAndSorted(List<Song> masterList) {
    if (_lastCache == masterList && _lastQuery == _searchQuery && _lastSort == _sort) {
      return _cachedDisplaySongs; // Return instantly if nothing changed
    }

    List<Song> filtered = masterList;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q)).toList();
    } else {
      filtered = List.of(masterList);
    }

    filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (_sort == SongSort.za) filtered = filtered.reversed.toList();

    _lastCache = masterList;
    _lastQuery = _searchQuery;
    _lastSort = _sort;
    _cachedDisplaySongs = filtered;

    return _cachedDisplaySongs;
  }

  void _toggleSelection(int songId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(songId)) _selectedIds.remove(songId);
      else _selectedIds.add(songId);
    });
  }

  void _selectAll(List<Song> displaySongs) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIds.length == displaySongs.length) _selectedIds.clear();
      else _selectedIds.addAll(displaySongs.map((s) => s.id));
    });
  }

  Future<void> _addToFavourites(List<Song> songsToAdd, AppState app, Color accent) async {
    // Calls the newly added function in AppState
    await app.addSongsToFavourites(songsToAdd.map((s) => s.id).toList());
    setState(() => _selectedIds.clear());
    _showSnack('Added to Favourites', accent);
  }

  void _addToPlaylist(List<Song> songsToAdd, AppState app, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SelectPlaylistSheet(
        app: app,
        accentColor: accent,
        onSelect: (playlistId) async {
          for (var s in songsToAdd) await app.addSongToPlaylist(playlistId: playlistId, songId: s.id);
          if (mounted) {
            setState(() => _selectedIds.clear());
            Navigator.pop(context);
            _showSnack('Added to playlist', accent);
          }
        },
      ),
    );
  }


  void _showDetails(Song song, Color accent) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => _SongDetailsDialog(song: song, accentColor: accent),
    );
  }

  void _scrollToLetter(String letter, List<Song> displaySongs) {
    if (displaySongs.isEmpty) return;
    int index = displaySongs.indexWhere((s) {
      final firstChar = s.title.trim().toUpperCase();
      if (firstChar.isEmpty) return false;
      if (letter == '#') return !RegExp(r'[A-Z]').hasMatch(firstChar[0]);
      return firstChar.startsWith(letter);
    });

    if (index != -1) {
      final offset = index * 65.0;
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    }
  }

  void _handleAlphaDrag(double dy, double maxHeight, List<Song> displaySongs) {
    if (dy < 0 || dy > maxHeight) return;
    int index = (dy / maxHeight * _alphabet.length).floor();
    index = index.clamp(0, _alphabet.length - 1);
    final letter = _alphabet[index];

    if (_currentAlpha != letter) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentAlpha = letter;
        _isDraggingAlpha = true;
      });
      _scrollToLetter(letter, displaySongs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    // We strictly select songsCache so the whole screen doesn't rebuild randomly
    final songsCache = context.select<AppState, List<Song>>((a) => a.songsCache);
    final app = context.read<AppState>();

    return FutureBuilder<void>(
      future: _ensureLoaded(app),
      builder: (context, snap) {
        final displaySongs = _getFilteredAndSorted(songsCache);

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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, child: child)),
                child: _isSelectionMode
                    ? _buildSelectionHeader(context, app, displaySongs, accent)
                    : _buildNormalHeader(context, app, displaySongs, accent),
              ),

              if (_error != null) _buildErrorBanner(),

              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: displaySongs.isEmpty && !_loading
                          ? _buildEmptyState(context, app, accent)
                          : RefreshIndicator(
                        color: accent,
                        backgroundColor: _bgGlass,
                        strokeWidth: 2.5,
                        onRefresh: () => _refresh(app, forceRescan: true),
                        child: _buildSongList(context, app, displaySongs, accent),
                      ),
                    ),

                    if (displaySongs.isNotEmpty && _searchQuery.isEmpty && !_isSelectionMode)
                      Positioned(
                        left: 4,
                        top: 10, bottom: 10,
                        child: _buildAlphabetScrollbar(accent, displaySongs),
                      ),

                    if (_isDraggingAlpha && !_isSelectionMode)
                      Center(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _isDraggingAlpha ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: AnimatedScale(
                              scale: _isDraggingAlpha ? 1.0 : 0.5,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: 86, height: 86,
                                decoration: BoxDecoration(
                                  color: _bgGlass.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: accent.withOpacity(0.5), width: 2),
                                  boxShadow: [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 24, spreadRadius: 8)],
                                ),
                                alignment: Alignment.center,
                                child: Text(_currentAlpha, style: TextStyle(color: accent, fontSize: 40, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionHeader(BuildContext context, AppState app, List<Song> displaySongs, Color accent) {
    final allSelected = _selectedIds.length == displaySongs.length;

    return Container(
      key: const ValueKey('selection_header'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: const BoxDecoration(color: _bgGlass, border: Border(bottom: BorderSide(color: _divider))),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close_rounded, color: _textPrimary), onPressed: () => setState(() => _selectedIds.clear())),
          const SizedBox(width: 8),
          Text('${_selectedIds.length} Selected', style: const TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () => _selectAll(displaySongs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24, height: 24,
              decoration: BoxDecoration(color: allSelected ? accent : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: allSelected ? accent : _textMuted, width: 2)),
              child: allSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
          ),
          const SizedBox(width: 16),
          _buildBulkMenu(app, displaySongs, accent),
        ],
      ),
    );
  }

  Widget _buildBulkMenu(AppState app, List<Song> displaySongs, Color accent) {
    return _ThemedMenu(
      onSelected: (val) {
        final selectedSongs = displaySongs.where((s) => _selectedIds.contains(s.id)).toList();
        if (val == 'fav') _addToFavourites(selectedSongs, app, accent);
        if (val == 'playlist') _addToPlaylist(selectedSongs, app, accent);
        },
      items: const [
        PopupMenuItem(value: 'fav', child: _MenuItem(icon: Icons.favorite_border_rounded, label: 'Add to Favourite')),
        PopupMenuItem(value: 'playlist', child: _MenuItem(icon: Icons.playlist_add_rounded, label: 'Add to Playlist')),

        ],
    );
  }

  Widget _buildNormalHeader(BuildContext context, AppState app, List<Song> songs, Color accent) {
    return Container(
      key: const ValueKey('normal_header'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SONGS', style: TextStyle(color: accent.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3)),
          const SizedBox(height: 12),
          Container(
            height: 46,
            decoration: BoxDecoration(color: _bgGlass, borderRadius: BorderRadius.circular(14), border: Border.all(color: _divider)),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}), // Let rebuild trigger filter
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'Search titles or artists...', hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: accent.withOpacity(0.5), size: 20),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close_rounded, color: _textMuted, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                    Text(_searchQuery.isEmpty ? 'Your Tracks' : 'Search Results', style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${songs.length} songs', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              _SortToggle(current: _sort, accentColor: accent, onChanged: (s) => setState(() => _sort = s)),
              const SizedBox(width: 8),
              _IconCircleButton(
                onTap: _loading ? null : () => _refresh(app, forceRescan: true),
                child: _loading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent)) : const Icon(Icons.refresh_rounded, color: _textSecondary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlphabetScrollbar(Color accent, List<Song> displaySongs) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragDown: (details) => _handleAlphaDrag(details.localPosition.dy, constraints.maxHeight, displaySongs),
            onVerticalDragUpdate: (details) => _handleAlphaDrag(details.localPosition.dy, constraints.maxHeight, displaySongs),
            onVerticalDragEnd: (_) => setState(() => _isDraggingAlpha = false),
            onVerticalDragCancel: () => setState(() => _isDraggingAlpha = false),
            child: SizedBox(
              width: 32,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _alphabet.map((l) {
                  final isSelected = _isDraggingAlpha && _currentAlpha == l;
                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      color: isSelected ? accent : _textMuted.withOpacity(0.5),
                      fontSize: isSelected ? 15 : 10,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    ),
                    child: Text(l),
                  );
                }).toList(),
              ),
            ),
          );
        }
    );
  }

  Widget _buildSongList(BuildContext context, AppState app, List<Song> songs, Color accent) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      // MATH FIX: Reduced left padding by 12, added 12 inside the row padding. Keeps text perfectly aligned.
      padding: EdgeInsets.fromLTRB(_isSelectionMode ? 12 : 48, 8, 8, 120),
      itemCount: songs.length,
      itemExtent: 65.0,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isSelected = _selectedIds.contains(song.id);

        return _SongRow(
          song: song,
          index: index,
          accentColor: accent,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: () async {
            if (_isSelectionMode) {
              _toggleSelection(song.id);
            } else {
              await app.player.setQueue(songs, startIndex: index);
              await app.player.play();
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) _toggleSelection(song.id);
          },
          onActionSelected: (val) {
            if (val == 'fav') _addToFavourites([song], app, accent);
            if (val == 'playlist') _addToPlaylist([song], app, accent);
            if (val == 'details') _showDetails(song, accent);
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
              Icon(_searchQuery.isEmpty ? Icons.library_music_rounded : Icons.search_off_rounded, size: 64, color: _textMuted.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(_searchQuery.isEmpty ? 'No songs found' : 'No results for "$_searchQuery"', style: const TextStyle(color: _textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
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
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
      child: Row(children: [const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)))]),
    );
  }
}

// ── Song Row ─────────────────────────────────────────────────────────────────

class _SongRow extends StatefulWidget {
  final Song song;
  final int index;
  final Color accentColor;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(String) onActionSelected;

  const _SongRow({
    required this.song, required this.index, required this.accentColor,
    required this.isSelectionMode, required this.isSelected,
    required this.onTap, required this.onLongPress, required this.onActionSelected,
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
    final app = context.read<AppState>();
    final accent = widget.accentColor;

    return StreamBuilder<Song?>(
        stream: app.player.currentSongStream,
        initialData: app.player.currentSong,
        builder: (context, snap) {
          final isPlaying = snap.data?.id == widget.song.id && !widget.isSelectionMode;
          final highlight = widget.isSelected || isPlaying;

          return GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
            onTapCancel: () => setState(() => _pressed = false),
            onLongPress: () { setState(() => _pressed = false); widget.onLongPress(); },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuart,
              margin: const EdgeInsets.symmetric(vertical: 5),
              transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
              transformAlignment: Alignment.center,
              // ALIGNMENT FIX: Added 12px left padding so background box wraps content cleanly
              padding: const EdgeInsets.only(left: 7, right: 4, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: highlight ? accent.withOpacity(0.10) : (_pressed ? _bgGlass.withOpacity(0.6) : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: highlight ? accent.withOpacity(0.35) : Colors.transparent),
              ),
              child: Row(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutQuart,
                    child: widget.isSelectionMode
                        ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: widget.isSelected ? accent : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.isSelected ? accent : _textMuted, width: 2),
                        ),
                        child: widget.isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.song.title,
                          style: TextStyle(
                            color: highlight ? (widget.isSelected ? Colors.white : accent) : _textPrimary,
                            fontSize: 14,
                            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.song.artist.isEmpty ? 'Unknown Artist' : widget.song.artist,
                          style: const TextStyle(color: _textSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  if (!widget.isSelectionMode) ...[
                    const SizedBox(width: 8), // Right side spacing
                    _ThemedMenu(
                      onSelected: widget.onActionSelected,
                      items: const [
                        PopupMenuItem(value: 'fav', child: _MenuItem(icon: Icons.favorite_border_rounded, label: 'Add to Favourite')),
                        PopupMenuItem(value: 'playlist', child: _MenuItem(icon: Icons.playlist_add_rounded, label: 'Add to Playlist')),
                        PopupMenuItem(value: 'details', child: _MenuItem(icon: Icons.info_outline_rounded, label: 'Details')),
                        ],
                    ),
                  ]
                ],
              ),
            ),
          );
        }
    );
  }
}

// ── Shared UI Components (Menus & Dialogs) ───────────────────────────────────

class _ThemedMenu extends StatelessWidget {
  final Function(String) onSelected;
  final List<PopupMenuEntry<String>> items;

  const _ThemedMenu({required this.onSelected, required this.items});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF27272A))),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF71717A), size: 20),
        itemBuilder: (_) => items,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _MenuItem({required this.icon, required this.label, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SelectPlaylistSheet extends StatelessWidget {
  final AppState app;
  final Color accentColor;
  final Function(String) onSelect;

  const _SelectPlaylistSheet({required this.app, required this.accentColor, required this.onSelect});

  static const _divider = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final playlists = app.playlists;

    return Container(
      height: size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: _divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('SELECT PLAYLIST', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _divider),
          Expanded(
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, i) {
                final p = playlists[i];
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.queue_music_rounded, color: accentColor, size: 20),
                  ),
                  title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('${p.songIds.length} songs', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                  onTap: () => onSelect(p.id),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}


class _SongDetailsDialog extends StatelessWidget {
  final Song song;
  final Color accentColor;

  const _SongDetailsDialog({required this.song, required this.accentColor});

  String _formatSize(File file) {
    if (!file.existsSync()) return "Unknown";
    final bytes = file.lengthSync();
    return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  String _formatDate(File file) {
    if (!file.existsSync()) return "Unknown";
    final dt = file.lastModifiedSync();
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  String _formatDuration(Duration? d) {
    if (d == null) return "Unknown";
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    File file;
    try {
      if (song.uri.startsWith('file://')) {
        file = File.fromUri(Uri.parse(song.uri));
      } else {
        file = File(song.uri);
      }
    } catch (e) {
      file = File(song.uri);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Song Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _DetailRow(label: 'Title', value: song.title.isEmpty ? 'Unknown' : song.title),
            _DetailRow(label: 'Artist', value: song.artist.isEmpty ? 'Unknown' : song.artist),
            _DetailRow(label: 'Album', value: song.album.isEmpty ? 'Unknown' : song.album),
            _DetailRow(label: 'Duration', value: _formatDuration(song.duration)),
            _DetailRow(label: 'File Size', value: _formatSize(file)),
            _DetailRow(label: 'Date Added', value: _formatDate(file)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: accentColor.withOpacity(0.5))),
                alignment: Alignment.center,
                child: Text('Close', style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ── Miscellaneous UI ─────────────────────────────────────────────────────────
class _SortToggle extends StatelessWidget {
  final SongSort current;
  final Color accentColor;
  final ValueChanged<SongSort> onChanged;

  const _SortToggle({required this.current, required this.accentColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF27272A))),
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
      onTap: () { HapticFeedback.lightImpact(); onChanged(value); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14), height: 34,
        decoration: BoxDecoration(color: active ? accentColor.withOpacity(0.18) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? accentColor : const Color(0xFFA1A1AA), fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _IconCircleButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); if (onTap != null) onTap!(); },
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF18181B), border: Border.all(color: const Color(0xFF27272A))),
        child: Center(child: child),
      ),
    );
  }
}