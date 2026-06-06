import 'package:flutter/material.dart';

/// Dependency-free shimmer placeholder. Wrap skeleton boxes in a single
/// [Skeleton] so they pulse in sync while data loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: widget.child,
    );
  }
}

/// A single grey rounded block used to mock a piece of content.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Mock of a leading-avatar list row (used for transactions and categories).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: SkeletonBox(width: 40, height: 40, radius: 20),
      title: Padding(
        padding: EdgeInsets.only(right: 80),
        child: SkeletonBox(height: 14),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(right: 140, top: 6),
        child: SkeletonBox(height: 10),
      ),
      trailing: SkeletonBox(width: 56, height: 14),
    );
  }
}
