import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── Design tokens ────────────────────────────────────────────────
  static const _bgDeep        = Color(0xFF0D0D14);
  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    final app  = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xFF1A1020), _bgDeep],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
            size.width * 0.06, 20, size.width * 0.06, 120),
        children: [
          // ── Page header ────────────────────────────────────────
          const Text(
            'SETTINGS',
            style: TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Preferences',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.bedtime_rounded,
                title: 'Sleep Timer',
                subtitle: app.sleepEndsAt == null
                    ? 'Off'
                    : 'Stops in ${_formatRemaining(app.sleepRemaining)}',
                isActive: app.sleepEndsAt != null,
                onTap: () => _openSleepTimerSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sleep timer sheet ────────────────────────────────────────────
  Future<void> _openSleepTimerSheet(BuildContext context) async {
    final app = context.read<AppState>();

    Future<void> set(Duration? d) async {
      await app.setSleepTimer(d);
      if (context.mounted) Navigator.pop(context);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => _SleepTimerSheet(onSelect: set),
    );
  }

  static String _formatRemaining(Duration? d) {
    if (d == null) return '—';
    if (d == Duration.zero) return '0m';
    final totalMinutes = (d.inSeconds / 60).ceil();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h <= 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF4A4A5A),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
      ),
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  static const _bgGlass = Color(0xFF1E1E2A);
  static const _divider = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _pressed = false;

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive
                    ? _accent.withOpacity(0.15)
                    : const Color(0xFF252530),
                border: Border.all(
                  color: widget.isActive
                      ? _accent.withOpacity(0.3)
                      : const Color(0xFF2E2E3A),
                ),
              ),
              child: Icon(
                widget.icon,
                color: widget.isActive ? _accent : _textSecondary,
                size: 18,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color:
                      widget.isActive ? _accent : _textSecondary,
                      fontSize: 12,
                      fontWeight: widget.isActive
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: _textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sleep Timer Sheet ─────────────────────────────────────────────────────────

class _SleepTimerSheet extends StatelessWidget {
  final Future<void> Function(Duration?) onSelect;

  const _SleepTimerSheet({required this.onSelect});

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);
  static const _textMuted     = Color(0xFF4A4A5A);
  static const _divider       = Color(0xFF252530);

  static const _options = [
    (null,                        Icons.timer_off_rounded,    'Off',        'Disable sleep timer'),
    (Duration(minutes: 15),       Icons.timer_rounded,        '15 minutes', 'Short session'),
    (Duration(minutes: 30),       Icons.timer_rounded,        '30 minutes', 'Medium session'),
    (Duration(hours: 1),          Icons.nightlight_round,     '1 hour',     'Long session'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.12),
                      border: Border.all(
                          color: _accent.withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.bedtime_rounded,
                        color: _accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SLEEP TIMER',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Stop playback after',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: _divider),
              const SizedBox(height: 8),

              // Options
              ..._options.map((opt) {
                final (dur, icon, label, sub) = opt;
                return _TimerOptionTile(
                  icon: icon,
                  label: label,
                  subtitle: sub,
                  onTap: () => onSelect(dur),
                );
              }),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timer Option Tile ─────────────────────────────────────────────────────────

class _TimerOptionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TimerOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_TimerOptionTile> createState() => _TimerOptionTileState();
}

class _TimerOptionTileState extends State<_TimerOptionTile> {
  bool _pressed = false;

  static const _bgGlass       = Color(0xFF1E1E2A);
  static const _accent        = Color(0xFFFF6B35);
  static const _textPrimary   = Color(0xFFF0F0F5);
  static const _textSecondary = Color(0xFF8A8A9A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: _pressed
              ? _bgGlass.withOpacity(0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: _textSecondary, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}