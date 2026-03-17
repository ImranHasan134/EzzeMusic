import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';

class PlayerController {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _queue = const [];

  AudioPlayer get audioPlayer => _player;
  List<Song> get queue => _queue;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<double> get speedStream => _player.speedStream;

  Future<void> init() async {
    // No-op: we set sources when user selects songs.
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List.unmodifiable(songs);
    final sources = songs
        .map(
          (s) => AudioSource.uri(
            Uri.parse(s.uri),
            tag: MediaItem(
              id: s.id.toString(),
              title: s.title,
              artist: s.artist,
              duration: s.duration,
            ),
          ),
        )
        .toList();

    await _player.setAudioSources(sources, initialIndex: startIndex);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> seekToIndex(int index) => _player.seek(Duration.zero, index: index);
  Future<void> next() => _player.seekToNext();
  Future<void> previous() => _player.seekToPrevious();

  Future<void> toggleShuffle() async {
    final next = !_player.shuffleModeEnabled;
    if (next) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(next);
  }

  Future<void> cycleRepeatMode() async {
    // off -> all -> one -> off
    final current = _player.loopMode;
    final next = switch (current) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _player.setLoopMode(next);
  }

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
}

