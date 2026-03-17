import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/songs_repository.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'player_controller.dart';

class AppState extends ChangeNotifier {
  static const _kThemeModeKey = 'themeMode';
  static const _kUserProfileKey = 'userProfile';
  static const _kPlaylistsKey = 'playlists';

  late final SharedPreferences _prefs;
  late final PlayerController player;
  late final SongsRepository songsRepository;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  final List<Playlist> _playlists = [];
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  List<Song> _songsCache = const [];
  List<Song> get songsCache => _songsCache;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _loadPlaylists();

    player = PlayerController();
    await player.init();

    songsRepository = SongsRepository();
  }

  Future<void> refreshDeviceSongs() async {
    _songsCache = await songsRepository.getDeviceSongsAscending();
    notifyListeners();
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

