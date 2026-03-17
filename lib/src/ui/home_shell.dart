import 'package:flutter/material.dart';
import 'screens/now_playing_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/songs_screen.dart';
import 'screens/theme_screen.dart';

enum HomeSection { nowPlaying, playlists, songs, theme}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeSection _section = HomeSection.nowPlaying;

  String get _title => switch (_section) {
        HomeSection.nowPlaying => 'EzzeMusic',
        HomeSection.playlists => 'Playlists',
        HomeSection.songs => 'Songs',
        HomeSection.theme => 'Theme',
      };

  Widget get _body => switch (_section) {
        HomeSection.nowPlaying => const NowPlayingScreen(),
        HomeSection.playlists => const PlaylistsScreen(),
        HomeSection.songs => const SongsScreen(),
        HomeSection.theme => const ThemeScreen(),
      };

  void _go(HomeSection section) {
    setState(() => _section = section);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle),
                title: const Text('Now Playing'),
                selected: _section == HomeSection.nowPlaying,
                onTap: () => _go(HomeSection.nowPlaying),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: const Text('Playlist'),
                selected: _section == HomeSection.playlists,
                onTap: () => _go(HomeSection.playlists),
              ),
              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('Songs'),
                selected: _section == HomeSection.songs,
                onTap: () => _go(HomeSection.songs),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                selected: _section == HomeSection.theme,
                onTap: () => _go(HomeSection.theme),
              ),
            ],
          ),
        ),
      ),
      body: _body,
    );
  }
}

