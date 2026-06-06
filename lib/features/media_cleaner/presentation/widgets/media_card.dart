import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/models/media_models.dart';
import '../providers/media_providers.dart';
import 'format_bytes.dart';

/// One review-deck card: full-bleed thumbnail with size/date/album overlays and
/// a video badge. Thumbnails come only through [mediaScannerProvider] so the
/// web build never imports photo_manager.
class MediaCard extends ConsumerWidget {
  const MediaCard({super.key, required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Material(
        elevation: 4,
        color: scheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumbnail(asset: asset),
            const _BottomScrim(),
            if (asset.isVideo)
              Positioned(top: AppSpacing.md, left: AppSpacing.md, child: _VideoBadge(asset: asset)),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _MetaRow(asset: asset),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanner = ref.read(mediaScannerProvider);
    return FutureBuilder<Uint8List?>(
      future: scanner.thumbnail(asset.assetId),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ThumbPlaceholder(icon: null);
        }
        if (bytes == null) {
          return const _ThumbPlaceholder(icon: Icons.broken_image_outlined);
        }
        return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
      },
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: icon == null
          ? const SizedBox(
              width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, size: 48, color: scheme.outline),
    );
  }
}

// Darkens the lower third so white meta text stays legible over bright photos.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, size: 16, color: Colors.white),
          if (asset.durationSec != null) ...[
            const SizedBox(width: 4),
            Text(_duration(asset.durationSec!),
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  String _duration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context) {
    final album = asset.albumName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Pill(child: Text(formatBytes(asset.sizeBytes), style: _metaStyle)),
            if (asset.createdDate != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _Pill(child: Text(formatDate(asset.createdDate!), style: _metaStyle)),
            ],
          ],
        ),
        if (album != null && album.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _Pill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_outlined, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(album,
                      overflow: TextOverflow.ellipsis, style: _metaStyle),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static const _metaStyle = TextStyle(color: Colors.white, fontSize: 12);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: child,
    );
  }
}
