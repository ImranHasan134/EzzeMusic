import 'dart:io';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';

class SongsRepository {
  final OnAudioQuery _query = OnAudioQuery();

  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return false;

    // Android 13+ uses READ_MEDIA_AUDIO, older uses READ_EXTERNAL_STORAGE.
    final statusAudio = await Permission.audio.status;
    if (statusAudio.isGranted) return true;

    final result = await Permission.audio.request();
    if (result.isGranted) return true;

    // Some devices/ROMs still require storage permission for MediaStore.
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<List<Song>> getDeviceSongsAscending() async {
    if (!Platform.isAndroid) return const [];

    final can = await ensurePermission();
    if (!can) return const [];

    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songs
        .where((s) => (s.uri ?? '').isNotEmpty)
        .map(
          (s) => Song(
            id: s.id,
            title: (s.title).trim(),
            artist: (s.artist ?? 'Unknown artist').trim(),
            uri: s.uri!,
            duration: s.duration == null ? null : Duration(milliseconds: s.duration!),
          ),
        )
        .toList();
  }
}

