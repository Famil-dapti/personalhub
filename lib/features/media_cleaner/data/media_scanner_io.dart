import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:photo_manager/photo_manager.dart';

import '../../../core/db/app_database.dart';
import 'media_scanner.dart';

/// Android/iOS implementation backed by photo_manager. Indexes the full library
/// in pages (size resolved per asset for the freed-space estimate) and deletes
/// through the OS trash dialog.
class DeviceMediaScanner implements MediaScanner {
  static const int _pageSize = 200;
  static const int _flushEvery = 200;

  @override
  bool get supported => true;

  @override
  Future<MediaAccess> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend();
    if (state.isAuth) return MediaAccess.granted;
    if (state.hasAccess) return MediaAccess.limited;
    return MediaAccess.denied;
  }

  @override
  Future<void> indexDevice({
    required String deviceId,
    required AppDatabase db,
    void Function(int done, int total)? onProgress,
  }) async {
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common, // images + videos
    );
    if (paths.isEmpty) return;
    final all = paths.first;
    final total = await all.assetCountAsync;
    onProgress?.call(0, total);

    final existing = await db.indexedAssetIds(deviceId);
    final seen = <String>{};
    final buffer = <LocalMediaAssetsCompanion>[];
    var done = 0;

    final pages = (total / _pageSize).ceil();
    for (var page = 0; page < pages; page++) {
      final entities = await all.getAssetListPaged(page: page, size: _pageSize);
      for (final e in entities) {
        seen.add(e.id);
        done++;
        if (!existing.contains(e.id)) {
          buffer.add(await _toCompanion(e, deviceId));
        }
      }
      if (buffer.length >= _flushEvery) {
        await db.upsertMediaAssets(buffer);
        buffer.clear();
      }
      onProgress?.call(done, total);
    }
    if (buffer.isNotEmpty) await db.upsertMediaAssets(buffer);

    // Delta removal: assets indexed before but absent now were deleted/moved.
    await db.removeMediaAssets(existing.difference(seen).toList());
  }

  Future<LocalMediaAssetsCompanion> _toCompanion(
      AssetEntity e, String deviceId) async {
    var sizeBytes = 0;
    try {
      final f = await e.file;
      if (f != null) sizeBytes = await f.length();
    } on Exception {
      // Unreadable asset (cloud-only / permission edge) — leave size 0.
    }
    final relative = e.relativePath;
    return LocalMediaAssetsCompanion.insert(
      assetId: e.id,
      deviceId: deviceId,
      type: e.type == AssetType.video ? 'video' : 'image',
      indexedAt: DateTime.now(),
      albumName: Value(_albumFromPath(relative)),
      relativePath: Value(relative),
      sizeBytes: Value(sizeBytes),
      width: Value(e.width),
      height: Value(e.height),
      durationSec: Value(e.type == AssetType.video ? e.duration : null),
      createdDate: Value(e.createDateTime),
      title: Value(e.title),
    );
  }

  // Folder name from a relativePath like "DCIM/Camera/" -> "Camera".
  String? _albumFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final parts =
        path.split('/').where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }

  @override
  Future<List<String>> deleteAssets(List<String> assetIds) {
    if (assetIds.isEmpty) return Future.value(const []);
    return PhotoManager.editor.deleteWithIds(assetIds);
  }

  @override
  Future<Uint8List?> thumbnail(String assetId,
      {int width = 600, int height = 600}) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity?.thumbnailDataWithSize(ThumbnailSize(width, height));
  }
}

MediaScanner createMediaScannerImpl() => DeviceMediaScanner();
