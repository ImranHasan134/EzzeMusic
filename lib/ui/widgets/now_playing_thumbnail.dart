import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlayingThumbnail extends StatelessWidget {
  final int songId;

  const NowPlayingThumbnail({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    // 1. Link to the dynamic accent color from your theme
    final accent = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    // Responsive sizing: 75% of screen width
    final double artSize = size.width * 0.75;

    return Center(
      child: Container(
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          // ── CIRCULAR SHAPE ──
          shape: BoxShape.circle,
          boxShadow: [
            // Deep shadow for physical depth
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            // Soft dynamic glow matching your theme color
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 50,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. THE IMAGE (Clipped perfectly to Circle) ──
            ClipOval(
              child: QueryArtworkWidget(
                id: songId,
                type: ArtworkType.AUDIO,
                artworkHeight: artSize,
                artworkWidth: artSize,
                artworkFit: BoxFit.cover,
                quality: 100,
                nullArtworkWidget: _buildPlaceholder(accent, artSize),
              ),
            ),

            // ── 2. THE OVERLAY RIM (Hides edges perfectly) ──
            // We put this on TOP of the image to mask any pixel gaps
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12), // Subtle luxury rim
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color accent, double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [const Color(0xFF18181B), accent.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
            Icons.music_note_rounded,
            size: size * 0.35,
            color: accent.withOpacity(0.25)
        ),
      ),
    );
  }
}