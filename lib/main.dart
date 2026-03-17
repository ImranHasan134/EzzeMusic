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
    return MaterialApp(
      title: 'EzzeMusic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}