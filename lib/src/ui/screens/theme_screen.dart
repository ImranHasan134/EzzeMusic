import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = app.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Dark mode'),
          subtitle: Text(isDark ? 'On' : 'Off'),
          trailing: Switch(
            value: isDark,
            onChanged: (v) =>
                context.read<AppState>().setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
      ),
    );
  }
}

