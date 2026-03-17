import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgDeep        = Color(0xFF0D0D14);
  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppState>();
    final playlists = app.playlists;
    final size      = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xFF1A1020), _bgDeep],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(size.width * 0.06, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLAYLISTS',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Playlists',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              '${playlists.length} '
                                  '${playlists.length == 1 ? 'playlist' : 'playlists'}',
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // New playlist button
                      GestureDetector(
                        onTap: () => _createPlaylist(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
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
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'New',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: playlists.isEmpty
                  ? _buildEmptyState(context)
                  : _buildPlaylistList(context, app, playlists, size),
            ),
          ],
        ),
      ),
    );
  }

  // ── Playlist list ────────────────────────────────────────────────
  Widget _buildPlaylistList(BuildContext context, AppState app,
      List playlists, Size size) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          size.width * 0.04, 4, size.width * 0.04, 120),
      itemCount: playlists.length,
      separatorBuilder: (_, __) =>
      const Divider(height: 1, color: _divider, indent: 72),
      itemBuilder: (context, index) {
        final p = playlists[index];
        return _PlaylistRow(
          name: p.name,
          songCount: p.songIds.length,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlistId: p.id),
            ),
          ),
          onRename: () => _renamePlaylist(context, p.id, p.name),
          onDelete: () => context.read<AppState>().deletePlaylist(p.id),
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
              child: const Icon(Icons.queue_music_rounded,
                  size: 36, color: _textMuted),
            ),
            const SizedBox(height: 20),
            const Text(
              'No playlists yet',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first playlist to get started.',
              style: TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _createPlaylist(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create Playlist',
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

  // ── Create dialog ────────────────────────────────────────────────
  Future<void> _createPlaylist(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await _showPlaylistDialog(
      context: context,
      title: 'New Playlist',
      hint: 'Playlist name',
      confirmLabel: 'Create',
      controller: ctrl,
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AppState>().createPlaylist(ctrl.text);
  }

  // ── Rename dialog ────────────────────────────────────────────────
  Future<void> _renamePlaylist(
      BuildContext context, String playlistId, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final ok = await _showPlaylistDialog(
      context: context,
      title: 'Rename Playlist',
      hint: 'Playlist name',
      confirmLabel: 'Save',
      controller: ctrl,
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AppState>().renamePlaylist(playlistId, ctrl.text);
  }

  // ── Shared themed dialog ─────────────────────────────────────────
  Future<bool?> _showPlaylistDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required String confirmLabel,
    required TextEditingController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => _ThemedDialog(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        controller: controller,
      ),
    );
  }
}

// ── Playlist Row ──────────────────────────────────────────────────────────────

class _PlaylistRow extends StatefulWidget {
  final String name;
  final int songCount;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _PlaylistRow({
    required this.name,
    required this.songCount,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_PlaylistRow> createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<_PlaylistRow> {
  bool _pressed = false;

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
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
            // Icon badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bgGlass,
                border: Border.all(color: _divider),
              ),
              child: const Icon(Icons.queue_music_rounded,
                  color: _textMuted, size: 20),
            ),

            const SizedBox(width: 14),

            // Name + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
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
                    '${widget.songCount} '
                        '${widget.songCount == 1 ? 'song' : 'songs'}',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Popup menu
            _ThemedPopupMenu(
              onRename: widget.onRename,
              onDelete: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Themed Popup Menu ─────────────────────────────────────────────────────────

class _ThemedPopupMenu extends StatelessWidget {
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ThemedPopupMenu({required this.onRename, required this.onDelete});

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: _bgGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _divider),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'rename') onRename();
          if (v == 'delete') onDelete();
        },
        icon: const Icon(Icons.more_vert_rounded,
            color: _textMuted, size: 20),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: const [
                Icon(Icons.drive_file_rename_outline_rounded,
                    color: _textPrimary, size: 16),
                SizedBox(width: 10),
                Text('Rename',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 16),
                SizedBox(width: 10),
                Text('Delete',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Themed Dialog ─────────────────────────────────────────────────────────────

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

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

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
            // Title
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

            // Input field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: _accent,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                      color: _textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _divider),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Confirm
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8C5A), _accent],
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
                          letterSpacing: 0.2,
                        ),
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