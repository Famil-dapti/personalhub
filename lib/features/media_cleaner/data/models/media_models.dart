/// Domain models + enums for the Media Cleaner (Phase 3). Storage-agnostic;
/// Drift <-> domain conversions live in `core/db/mappers.dart`.
library;

/// Whether an asset is a photo or a video.
enum MediaType { image, video }

/// The four swipe outcomes. `later` is a defer (re-shown), not a final verdict.
enum MediaDecisionKind { keep, delete, favorite, later }

extension MediaDecisionKindWire on MediaDecisionKind {
  // Wire strings must match the kDecision* constants in app_database.dart.
  String get wire => switch (this) {
        MediaDecisionKind.keep => 'keep',
        MediaDecisionKind.delete => 'delete',
        MediaDecisionKind.favorite => 'favorite',
        MediaDecisionKind.later => 'later',
      };

  bool get isFinal => this != MediaDecisionKind.later;
}

/// How the review deck is ordered.
enum MediaSortOrder { newest, oldest, largest, random }

/// Which media types the review deck includes.
enum MediaTypeFilter { all, photos, videos }

/// A single indexed photo/video on this device.
class MediaAsset {
  const MediaAsset({
    required this.assetId,
    required this.deviceId,
    required this.type,
    required this.sizeBytes,
    this.albumId,
    this.albumName,
    this.relativePath,
    this.width,
    this.height,
    this.durationSec,
    this.createdDate,
    this.title,
  });

  final String assetId;
  final String deviceId;
  final MediaType type;
  final int sizeBytes;
  final String? albumId;
  final String? albumName;
  final String? relativePath;
  final int? width;
  final int? height;
  final int? durationSec;
  final DateTime? createdDate;
  final String? title;

  bool get isVideo => type == MediaType.video;

  // Screenshots live in a "Screenshots" album/path on Android — used by the
  // screenshots-only filter.
  bool get isScreenshot {
    final hay = '${albumName ?? ''} ${relativePath ?? ''}'.toLowerCase();
    return hay.contains('screenshot');
  }
}

/// Per-device aggregate cleanup counters (synced; shown on phones + web).
class MediaStats {
  const MediaStats({
    required this.deviceId,
    required this.total,
    required this.decided,
    required this.kept,
    required this.deleted,
    this.deviceName,
  });

  final String deviceId;
  final String? deviceName;
  final int total;
  final int decided;
  final int kept;
  final int deleted;

  int get remaining => (total - decided).clamp(0, total);
  double get progress => total == 0 ? 0 : decided / total;
}
