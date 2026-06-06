import 'dart:typed_data';

import '../../../core/db/app_database.dart';
// Picks the real photo_manager impl on mobile (dart:io) and a no-op on web,
// keeping photo_manager (which needs dart:io) out of the web build.
import 'media_scanner_web.dart'
    if (dart.library.io) 'media_scanner_io.dart';

/// Outcome of asking the OS for photo/video access.
enum MediaAccess { granted, limited, denied }

/// Platform gateway to the device photo/video library. The only place
/// photo_manager is touched; everything else talks to this interface.
abstract class MediaScanner {
  /// False on web (no device file access) — drives the mobile-only gate.
  bool get supported;

  Future<MediaAccess> requestAccess();

  /// Indexes the whole library into Drift: inserts new assets, drops assets no
  /// longer on the device (delta). `onProgress(done, total)` drives a progress
  /// bar during the first full scan.
  Future<void> indexDevice({
    required String deviceId,
    required AppDatabase db,
    void Function(int done, int total)? onProgress,
  });

  /// Deletes via the OS MediaStore trash dialog; returns the ids actually
  /// removed (empty if the user cancels the system prompt).
  Future<List<String>> deleteAssets(List<String> assetIds);

  /// JPEG thumbnail bytes for a card, or null if the asset is gone.
  Future<Uint8List?> thumbnail(String assetId, {int width = 600, int height = 600});
}

/// Resolves to the mobile or web implementation at compile time.
MediaScanner createMediaScanner() => createMediaScannerImpl();
