import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/models/media_models.dart';
import '../providers/media_providers.dart';
import 'format_bytes.dart';

/// One review-deck card: full-bleed thumbnail with size/date/album overlays, a
/// video badge, and faint rotated keep/delete guide stamps. Thumbnails come
/// only through [mediaScannerProvider] so the web build never imports
/// photo_manager.
class MediaCard extends ConsumerWidget {
  const MediaCard({super.key, required this.asset});

  final MediaAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Material(
        elevation: AppElevation.elev2,
        color: scheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumbnail(asset: asset),
            const _BottomScrim(),
            // Static low-opacity affordances: green SAKLA top-left, red SIL
            // top-right. Drag-progress wiring lives in the swiper, not here.
            const Positioned(
              top: AppSpacing.xl,
              left: AppSpacing.lg,
              child: _SwipeStamp(label: 'SAKLA', color: Color(0xFF2E7D52), angle: -0.21),
            ),
            const Positioned(
              top: AppSpacing.xl,
              right: AppSpacing.lg,
              child: _SwipeStamp(label: 'SIL', color: Color(0xFFBA1A1A), angle: 0.21),
            ),
            if (asset.isVideo)
              Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: _VideoBadge(asset: asset)),
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

// Bordered, rotated guide label ("SAKLA"/"SIL"). Kept faint and static so it
// reads as an affordance hint without competing with the photo.
class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp(
      {required this.label, required this.color, required this.angle});

  final String label;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
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
          const Icon(Icons.videocam, size: 16, color: Colors.white),
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
        if (album != null && album.isNotEmpty) ...[
          _Pill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_outlined, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(album,
                      overflow: TextOverflow.ellipsis, style: _metaStyle),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // tarih . boyut . tur in a single legible pill.
        _Pill(child: Text(_metaLine(), style: _metaStyle)),
      ],
    );
  }

  String _metaLine() {
    final type = asset.isVideo ? 'Video' : 'Foto';
    final parts = <String>[
      if (asset.createdDate != null) formatDate(asset.createdDate!),
      formatBytes(asset.sizeBytes),
      type,
    ];
    return parts.join('  .  ');
  }

  static const _metaStyle = TextStyle(
      color: Colors.white, fontSize: 12, fontFeatures: kTabularFigures);
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
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: child,
    );
  }
}
