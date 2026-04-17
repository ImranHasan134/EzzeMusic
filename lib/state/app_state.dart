import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for compute()
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
  static const _kAccentColorKey = 'accentColor';
  static const _kHideShortClipsKey = 'hideShortClips';
  static const _kFavouritesPlaylistId = 'pl_favourites';
  static const _kFavouritesPlaylistName = 'Favourite';

  late final SharedPreferences _prefs;
  late final PlayerController player;
  late final SongsRepository songsRepository;

  StreamSubscription<List<Song>>? _queueSub;
  StreamSubscription<int?>? _indexSub;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Color _accentColor = const Color(0xFF6366F1);
  Color get accentColor => _accentColor;

  // 1. SET TO FALSE BY DEFAULT
  bool _hideShortClips = false;
  bool get hideShortClips => _hideShortClips;

  // ── High Performance Caching ──────────────────────────────────
  List<Song> _allSongsMaster = []; // Memory cache of full library
  List<Song> _songsCache = const [];
  List<Song> get songsCache => _songsCache;

  final List<Playlist> _playlists = [];
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Playlist? get favouritesPlaylist =>
      _playlists.where((p) => p.id == _kFavouritesPlaylistId).firstOrNull;

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

  // ── Initialization ───────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _loadPlaylists();
    _loadAccentColor();
    _loadLibraryFilters(); // Loads saved state or defaults to false

    player = PlayerController();
    await player.init();

    songsRepository = SongsRepository();
    await songsRepository.init();

    _queueSub?.cancel();
    _queueSub = player.queueStream.listen((_) => _saveLastPlayed());
    _indexSub?.cancel();
    _indexSub = player.currentIndexStream.listen((_) => _saveLastPlayed());

    await _restoreLastPlayed();

    // Initial load: Full scan on app start
    await refreshLibrarySongs(forceRescan: true);
  }

  // ── Optimized Library Logic ──────────────────────────────────

  Future<void> refreshLibrarySongs({bool forceRescan = false}) async {
    // 1. Fetch from storage only if needed
    if (_allSongsMaster.isEmpty || forceRescan) {
      _allSongsMaster = await songsRepository.getLibrarySongsAscending();
    }

    // 2. CONNECTION FIX: Populate the cache that the UI uses
    if (_hideShortClips) {
      // Background filtering to keep UI smooth
      _songsCache = await compute(_filterMusicLogic, _allSongsMaster);
    } else {
      // Just copy the whole list to the cache
      _songsCache = List.from(_allSongsMaster);
    }

    notifyListeners();
  }

  // This was missing from your provided code!
  static List<Song> _filterMusicLogic(List<Song> songs) {
    return songs.where((s) {
      final duration = s.duration ?? Duration.zero;
      if (duration.inSeconds < 30) return false;

      final path = s.uri;
      return path.endsWith('.mp3') || path.endsWith('.MP3');
    }).toList();
  }

  // This handles the switch in Settings
  Future<void> toggleHideShortClips(bool value) async {
    _hideShortClips = value;
    await _prefs.setBool(_kHideShortClipsKey, value);
    // Refresh using RAM cache (instant)
    await refreshLibrarySongs(forceRescan: false);
  }

  Future<void> importSongs() async {
    _songsCache = await songsRepository.importSongsFromFilesPicker();
    notifyListeners();
  }

  // ── Playlists ────────────────────────────────────────────────

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

  // ── Favourites ───────────────────────────────────────────────

  Future<void> addCurrentSongToFavourites() async {
    final song = player.currentSong;
    if (song == null) return;
    final fav = await _ensureFavouritesPlaylist();
    await addSongToPlaylist(playlistId: fav.id, songId: song.id);
  }

  Future<void> removeSongFromFavourites(int songId) async {
    final fav = favouritesPlaylist;
    if (fav == null) return;
    await removeSongFromPlaylist(playlistId: fav.id, songId: songId);
  }

  bool isSongFavourited(int songId) {
    final fav = favouritesPlaylist;
    return fav != null && fav.songIds.contains(songId);
  }

  // ── Playlist Internals ───────────────────────────────────────

  Future<Playlist> _ensureFavouritesPlaylist() async {
    final existing = favouritesPlaylist;
    if (existing != null) return existing;
    final created = Playlist(
      id: _kFavouritesPlaylistId,
      name: _kFavouritesPlaylistName,
      songIds: const [],
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _playlists.add(created);
    await _savePlaylists();
    notifyListeners();
    return created;
  }

  Future<void> addSongToPlaylist({required String playlistId, required int songId}) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].addSong(songId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist({required String playlistId, required int songId}) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].removeSong(songId);
    await _savePlaylists();
    notifyListeners();
  }

  // ── Personalization ──────────────────────────────────────────

  void _loadAccentColor() {
    final val = _prefs.getInt(_kAccentColorKey);
    if (val != null) _accentColor = Color(val);
  }

  Future<void> updateAccentColor(Color color) async {
    _accentColor = color;
    await _prefs.setInt(_kAccentColorKey, color.value);
    notifyListeners();
  }

  void _loadTheme() {
    final v = _prefs.getString(_kThemeModeKey);
    _themeMode = v == 'light' ? ThemeMode.light : v == 'dark' ? ThemeMode.dark : ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_kThemeModeKey, mode.name);
    notifyListeners();
  }

  // ── Core Persistence ─────────────────────────────────────────

  void _loadLibraryFilters() {
    // 2. FALLBACK TO FALSE IF NOT SAVED
    _hideShortClips = _prefs.getBool(_kHideShortClipsKey) ?? false;
  }

  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndsAt = null;
    if (duration != null) {
      _sleepEndsAt = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () async {
        await player.pause();
        _sleepEndsAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> _saveLastPlayed() async {
    final q = player.queue;
    if (q.isEmpty) return;
    await _prefs.setString(_kLastQueueKey, jsonEncode(q.map((e) => e.toJson()).toList()));
    await _prefs.setInt(_kLastIndexKey, player.currentIndex ?? 0);
  }

  Future<void> _restoreLastPlayed() async {
    final raw = _prefs.getString(_kLastQueueKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(Song.fromJson).toList();
      final idx = _prefs.getInt(_kLastIndexKey) ?? 0;
      await player.setQueue(list, startIndex: idx.clamp(0, list.length - 1));
    } catch (_) {}
  }

  void _loadPlaylists() {
    final raw = _prefs.getString(_kPlaylistsKey);
    _playlists..clear()..addAll(raw == null ? [] : (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(Playlist.fromJson));
  }

  Future<void> _savePlaylists() async => await _prefs.setString(_kPlaylistsKey, jsonEncode(_playlists.map((e) => e.toJson()).toList()));

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _queueSub?.cancel();
    _indexSub?.cancel();
    player.dispose();
    super.dispose();
  }
}