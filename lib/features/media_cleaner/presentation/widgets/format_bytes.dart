/// Human-readable byte size for media cards and the delete-confirm screen.
/// ASCII-only units keep the label policy (no Turkish special characters).
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final value = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$value ${units[unit]}';
}
