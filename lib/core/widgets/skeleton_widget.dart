import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shimmer-pulse skeleton loader matching the Debity design system.
///
/// Uses a fade-pulse animation between surface2 and surface3.
///
/// Predefined factories:
///  - [SkeletonBox]      : arbitrary-size rectangle
///  - [SkeletonStatCard] : 80×32 value + label strip
///  - [SkeletonListRow]  : full-width × 48dp row
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = AppColors.of(context);
    _color = ColorTween(
      begin: c.surface2,
      end: c.surface3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _color.value,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Stat card skeleton: value + label strips.
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.statCardPad),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface1,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.of(context).borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 60, height: 10),
          const SizedBox(height: 8),
          const SkeletonBox(width: 80, height: 32),
          const SizedBox(height: 6),
          const SkeletonBox(width: 48, height: 10),
        ],
      ),
    );
  }
}

/// List row skeleton: full-width × 48dp.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(
      width: double.infinity,
      height: 48,
    );
  }
}

/// 2-column grid of [SkeletonStatCard]s.
Widget buildStatGridSkeleton() {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.5,
    children: const [
      SkeletonStatCard(),
      SkeletonStatCard(),
      SkeletonStatCard(),
      SkeletonStatCard(),
    ],
  );
}

/// Column of [SkeletonListRow]s.
Widget buildListSkeleton({int count = 4}) {
  return Column(
    children: List.generate(
      count,
      (i) => Padding(
        padding: EdgeInsets.only(bottom: i < count - 1 ? AppSpacing.listGap : 0),
        child: const SkeletonListRow(),
      ),
    ),
  );
}
