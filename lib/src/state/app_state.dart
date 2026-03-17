import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/songs_repository.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'player_controller.dart';

class AppState extends ChangeNotifier {
  static const _kThemeModeKey = 'themeMode';
  static const _kPlaylistsKey = 'playlists';
  static const _kLastQueueKey = 'lastQueue.v1';
  static const _kLastIndexKey = 'lastIndex.v1';
  static const _kFavouritesPlaylistId = 'pl_favourites';
  static const _kFavouritesPlaylistName = 'Favourite';

  late final SharedPreferences _prefs;
  late final PlayerController player;
  late final SongsRepository songsRepository;

  StreamSubscription<List<Song>>? _queueSub;
  StreamSubscription<int?>? _indexSub;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  final List<Playlist> _playlists = [];
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Playlist? get favouritesPlaylist =>
      _playlists.where((p) => p.id == _kFavouritesPlaylistId).firstOrNull;

  List<Song> _songsCache = const [];
  List<Song> get songsCache => _songsCache;

  Timer? _sleepTimer;
  DateTime? _sleepEndsAt;
  DateTime? get sleepEndsAt => _sleepEndsAt;
  Duration? get sleepRemaining {
    final endsAt = _sleepEndsAt;
    if (endsAt == null) return null;
    final d = endsAt.difference(DateTime.now());
    if (d.isNegative) return Duration.zero;
    return d;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _loadPlaylists();

    player = PlayerController();
    await player.init();

    songsRepository = SongsRepository();
    await songsRepository.init();

    _queueSub?.cancel();
    _queueSub = player.queueStream.listen((_) => _saveLastPlayed());
    _indexSub?.cancel();
    _indexSub = player.currentIndexStream.listen((_) => _saveLastPlayed());

    await _restoreLastPlayed();
  }

  Future<void> refreshLibrarySongs() async {
    _songsCache = await songsRepository.getLibrarySongsAscending();
    notifyListeners();
  }

  Future<void> importSongs() async {
    _songsCache = await songsRepository.importSongsFromFilesPicker();
    notifyListeners();
  }

  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndsAt = null;

    if (duration == null) {
      notifyListeners();
      return;
    }

    _sleepEndsAt = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () async {
      await player.pause();
      _sleepTimer = null;
      _sleepEndsAt = null;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _saveLastPlayed() async {
    final q = player.queue;
    if (q.isEmpty) return;
    final idx = player.currentIndex ?? 0;
    await _prefs.setString(
      _kLastQueueKey,
      jsonEncode(q.map((e) => e.toJson()).toList()),
    );
    await _prefs.setInt(_kLastIndexKey, idx);
  }

  Future<void> _restoreLastPlayed() async {
    final raw = _prefs.getString(_kLastQueueKey);
    if (raw == null) return;
    final idx = _prefs.getInt(_kLastIndexKey) ?? 0;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Song.fromJson)
          .toList();
      if (list.isEmpty) return;
      await player.setQueue(list, startIndex: idx.clamp(0, list.length - 1));
    } catch (_) {
      // If parsing fails (schema change), just ignore.
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _queueSub?.cancel();
    _indexSub?.cancel();
    player.dispose();
    super.dispose();
  }

  void _loadTheme() {
    final value = _prefs.getString(_kThemeModeKey);
    _themeMode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' || null => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(
      _kThemeModeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
    notifyListeners();
  }

  void _loadPlaylists() {
    final raw = _prefs.getString(_kPlaylistsKey);
    _playlists
      ..clear()
      ..addAll(
        raw == null
            ? const []
            : (jsonDecode(raw) as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map(Playlist.fromJson),
      );
  }

  Future<void> _savePlaylists() async {
    await _prefs.setString(
      _kPlaylistsKey,
      jsonEncode(_playlists.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> createPlaylist(String name) async {
    _playlists.add(Playlist.newPlaylist(name: name));
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].copyWith(name: newName);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addSongToPlaylist({
    required String playlistId,
    required int songId,
  }) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].addSong(songId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addCurrentSongToFavourites() async {
    final song = player.currentSong;
    if (song == null) return;

    final fav = await _ensureFavouritesPlaylist();
    await addSongToPlaylist(playlistId: fav.id, songId: song.id);
  }

  Future<void> removeSongFromFavourites(int songId) async {
    final fav = favouritesPlaylist;
    if (fav == null) return;
    await removeSongFromPlaylist(
      playlistId: fav.id,
      songId: songId,
    );
  }
  bool isSongFavourited(int songId) {
    final fav = favouritesPlaylist;
    if (fav == null) return false;
    return fav.songIds.contains(songId);
  }

  Future<Playlist> _ensureFavouritesPlaylist() async {
    final existing = favouritesPlaylist;
    if (existing != null) return existing;


    final now = DateTime.now().millisecondsSinceEpoch;
    final created = Playlist(
      id: _kFavouritesPlaylistId,
      name: _kFavouritesPlaylistName,
      songIds: const [],
      createdAtMs: now,
    );
    _playlists.add(created);
    await _savePlaylists();
    notifyListeners();
    return created;
  }

  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required int songId,
  }) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].removeSong(songId);
    await _savePlaylists();
    notifyListeners();
  }
}

