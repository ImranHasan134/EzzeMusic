import 'package:flutter/material.dart';
import 'dart:io';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'src/state/app_state.dart';
import 'src/ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ezze.ezzemusic.channel.audio',
      androidNotificationChannelName: 'EzzeMusic Playback',
      androidNotificationOngoing: true,
    );
  }

  // Initialize AppState and wait for settings (Accent color, playlists, etc.) to load
  final appState = AppState();
  await appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const EzzeMusic(),
    ),
  );
}

class EzzeMusic extends StatelessWidget {
  const EzzeMusic({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap MaterialApp in a Consumer so it rebuilds when accentColor changes
    return Consumer<AppState>(
      builder: (context, app, child) {
        final accent = app.accentColor;

        return MaterialApp(
          title: 'EzzeMusic',
          debugShowCheckedModeBanner: false,

          // Apply the user's saved theme mode (Dark/Light/System)
          themeMode: app.themeMode,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,

            // ── GLOBAL COLORS ──────────────────────────────────────
            colorScheme: ColorScheme.fromSeed(
              seedColor: accent,
              primary: accent,
              secondary: accent,
              surface: const Color(0xFF09090B), // Deep luxury black
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF09090B),

            // ── SLIDER THEME (Global Seekbars) ─────────────────────
            sliderTheme: SliderThemeData(
              activeTrackColor: accent,
              thumbColor: accent,
              overlayColor: accent.withOpacity(0.12),
              trackHeight: 4,
            ),

            // ── SWITCH THEME ───────────────────────────────────────
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? accent : null),
              trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? accent.withOpacity(0.5) : null),
            ),

            // ── NAVIGATION BAR THEME ──────────────────────────────
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF18181B),
              indicatorColor: accent.withOpacity(0.15),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(color: accent);
                }
                return const IconThemeData(color: Color(0xFF71717A));
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600);
                }
                return const TextStyle(color: Color(0xFF71717A), fontSize: 12);
              }),
            ),

            // ── FLOATING ACTION BUTTON ────────────────────────────
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
          ),

          home: const HomeShell(),
        );
      },
    );
  }
}