import 'dart:typed_data';

import '../../../core/db/app_database.dart';
import 'media_scanner.dart';

/// Web has no device file access — the Media Cleaner is mobile-only here, so
/// every operation is a no-op and the UI shows the stats-only view instead.
class WebMediaScanner implements MediaScanner {
  @override
  bool get supported => false;

  @override
  Future<MediaAccess> requestAccess() async => MediaAccess.denied;

  @override
  Future<void> indexDevice({
    required String deviceId,
    required AppDatabase db,
    void Function(int done, int total)? onProgress,
  }) async {}

  @override
  Future<List<String>> deleteAssets(List<String> assetIds) async => const [];

  @override
  Future<Uint8List?> thumbnail(String assetId,
          {int width = 600, int height = 600}) async =>
      null;
}

MediaScanner createMediaScannerImpl() => WebMediaScanner();
