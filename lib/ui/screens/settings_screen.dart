import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _bgDeep = Color(0xFF09090B);
  static const _textPrimary = Color(0xFFFAFAFA);
  static const _textMuted = Color(0xFF71717A);
  static const _divider = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final accent = app.accentColor;
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4), radius: 1.1,
          colors: [Color(0xFF18181B), _bgDeep],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(size.width * 0.06, 20, size.width * 0.06, 120),
        children: [
          Text(
              'SETTINGS',
              style: TextStyle(
                // Changed from _textMuted to dynamic accent with opacity
                  color: accent.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3
              )
          ),
          const Text('Preferences', style: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),

          // ── AUDIO & PLAYBACK ──────────────────────────────────────
          const _SectionHeader(title: 'Audio & Playback'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.bedtime_rounded, title: 'Sleep Timer',
              subtitle: app.sleepEndsAt == null ? 'Off' : 'Stops in ${_formatRemaining(app.sleepRemaining)}',
              isActive: app.sleepEndsAt != null, accentColor: accent,
              onTap: () => _openSleepTimerSheet(context),
            ),
          ]),

          const SizedBox(height: 32),

          // ── PERSONALIZATION ───────────────────────────────────────
          const _SectionHeader(title: 'Personalization'),
          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.palette_rounded, title: 'Accent Color',
              subtitle: 'Customize glow and highlights', accentColor: accent,
              onTap: () => _openColorPicker(context),
            ),
          ]),

          const SizedBox(height: 32),

          // ── ADVANCED ──────────────────────────────────────────────
          const _SectionHeader(title: 'Advanced'),
          _SettingsCard(children: [
            _SettingsTile(icon: Icons.security_rounded, title: 'App Permissions', subtitle: 'Manage storage access', accentColor: accent, onTap: () => openAppSettings()),
            ]),
        ],
      ),
    );
  }

  void _openColorPicker(BuildContext context) {
    final app = context.read<AppState>();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => _ColorPickerSheet(
        currentMetadata: app.accentColor,
        onSelect: (newColor) { app.updateAccentColor(newColor); Navigator.pop(context); },
      ),
    );
  }

  Future<void> _openSleepTimerSheet(BuildContext context) async {
    final app = context.read<AppState>();
    await showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _SleepTimerSheet(
        onSelect: (d) { app.setSleepTimer(d); Navigator.pop(context); },
        accentColor: app.accentColor,
      ),
    );
  }

  static String _formatRemaining(Duration? d) {
    if (d == null) return '—';
    final mTotal = (d.inSeconds / 60).ceil();
    return mTotal >= 60 ? '${mTotal ~/ 60}h ${mTotal % 60}m' : '${mTotal}m';
  }
}

// ── COLOR PICKER (Outside the main class) ───────────────────────────

class _ColorPickerSheet extends StatelessWidget {
  final Color currentMetadata;
  final Function(Color) onSelect;
  const _ColorPickerSheet({required this.currentMetadata, required this.onSelect, super.key});

  static const _palette = [Color(0xFF6366F1), Color(0xFFF43F5E), Color(0xFFD4AF37), Color(0xFF10B981), Color(0xFF0EA5E9), Color(0xFF8B5CF6), Color(0xFFF59E0B), Color(0xFFEC4899)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Color(0xFF09090B), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Color(0xFF27272A)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('ACCENT COLOR', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true, crossAxisCount: 4, mainAxisSpacing: 20, crossAxisSpacing: 20,
          children: _palette.map((c) => GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(color: c.value == currentMetadata.value ? Colors.white : Colors.transparent, width: 3)),
              child: c.value == currentMetadata.value ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
          )).toList(),
        ),
      ]),
    );
  }
}

// ── REUSABLE UI COMPONENTS ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title, super.key});
  @override
  Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))); }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children, super.key});
  @override
  Widget build(BuildContext context) { return Container(decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF27272A))), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Column(children: children))); }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final bool isActive; final Color accentColor; final VoidCallback onTap; final Widget? trailing;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, required this.accentColor, this.isActive = false, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: isActive ? accentColor.withOpacity(0.1) : const Color(0xFF27272A), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isActive ? accentColor : const Color(0xFFA1A1AA), size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)), Text(subtitle, style: TextStyle(color: isActive ? accentColor : const Color(0xFF71717A), fontSize: 12))])),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFF3F3F46), size: 20),
        ]),
      ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  final Function(Duration?) onSelect; final Color accentColor;
  const _SleepTimerSheet({required this.onSelect, required this.accentColor, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF09090B), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        const Text('SLEEP TIMER', style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.timer_off_rounded, color: Colors.white24), title: const Text('Off', style: TextStyle(color: Colors.white)), onTap: () => onSelect(null)),
        ListTile(leading: const Icon(Icons.timer_rounded, color: Colors.white), title: const Text('15 minutes', style: TextStyle(color: Colors.white)), onTap: () => onSelect(const Duration(minutes: 15))),
        ListTile(leading: const Icon(Icons.timer_rounded, color: Colors.white), title: const Text('30 minutes', style: TextStyle(color: Colors.white)), onTap: () => onSelect(const Duration(minutes: 30))),
        ListTile(leading: const Icon(Icons.nightlight_round, color: Colors.white), title: const Text('1 hour', style: TextStyle(color: Colors.white)), onTap: () => onSelect(const Duration(hours: 1))),
      ]),
    );
  }
}