import 'package:flutter/material.dart';

/// Shimmer skeleton placeholder.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest
                .withOpacity(0.3 + _animation.value * 0.3),
          ),
        );
      },
    );
  }
}

/// Skeleton for workout screen.
class WorkoutSkeleton extends StatelessWidget {
  const WorkoutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonBox(
          width: double.infinity,
          height: 100,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (_) => const _ExerciseSkeleton()),
      ],
    );
  }
}

class _ExerciseSkeleton extends StatelessWidget {
  const _ExerciseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
              const SizedBox(width: 12),
              SkeletonBox(width: 120, height: 20),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonBox(width: 80, height: 16),
          const SizedBox(height: 12),
          Row(
            children: [
              SkeletonBox(width: 48, height: 48, borderRadius: BorderRadius.circular(12)),
              const SizedBox(width: 16),
              SkeletonBox(width: 100, height: 20),
              const Spacer(),
              SkeletonBox(width: 48, height: 48, borderRadius: BorderRadius.circular(12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for progress screen.
class ProgressSkeleton extends StatelessWidget {
  const ProgressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: SkeletonBox(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SkeletonBox(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SkeletonBox(
          width: double.infinity,
          height: 80,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 24),
        SkeletonBox(width: 140, height: 24),
        const SizedBox(height: 12),
        ...List.generate(5, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SkeletonBox(
            width: double.infinity,
            height: 64,
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ],
    );
  }
}
