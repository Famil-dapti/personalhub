import 'package:flutter/material.dart';

/// Deterministic per-app accent color + leading avatar for notification rows.
/// We have no real app icons, so a stable color derived from the source name
/// plus its first letter gives each app a recognizable identity.

const List<Color> _palette = [
  Color(0xFF1565C0), // blue
  Color(0xFF2E7D32), // green
  Color(0xFF6A1B9A), // purple
  Color(0xFFC62828), // red
  Color(0xFFE65100), // orange
  Color(0xFF00838F), // teal
  Color(0xFFAD1457), // pink
  Color(0xFF4527A0), // indigo
];

Color appBrandColor(String? source) {
  if (source == null || source.isEmpty) return _palette.first;
  final hash = source.codeUnits.fold<int>(0, (a, c) => a + c);
  return _palette[hash % _palette.length];
}

String appInitial(String? source) {
  if (source == null || source.trim().isEmpty) return '?';
  return source.trim().characters.first.toUpperCase();
}

/// 40px rounded brand avatar with the app's initial.
class AppBrandAvatar extends StatelessWidget {
  const AppBrandAvatar({super.key, required this.source, this.size = 40});

  final String? source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = appBrandColor(source);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        appInitial(source),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
