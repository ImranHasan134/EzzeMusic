class Song {
  final int id;
  final String title;
  final String artist;
  final String uri;
  final Duration? duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.duration,
  });
}

