import 'package:flutter/material.dart';

/// Megaphone in a filled red circle: marks every row with `alarm = true`
/// (whatever it plays). Shape + color, so not color-only.
class AlarmBadge extends StatelessWidget {
  const AlarmBadge({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.campaign, color: Colors.white, size: size * 0.65),
    );
  }
}

/// Icon for a built-in sound key, or null for an unknown key.
IconData? soundIcon(String? key) => switch (key) {
  'bell' => Icons.notifications_active,
  'horn' => Icons.surround_sound,
  'siren' => Icons.crisis_alert,
  _ => null,
};
