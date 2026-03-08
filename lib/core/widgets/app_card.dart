import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// General-purpose card matching the Debity design system.
///
/// - Background: surface1
/// - Border: 1dp borderSubtle
/// - Radius: 12dp (radiusLg)
/// - Padding: defaults to 20dp (stat card) or 24dp via [padding]
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _hovered
              ? AppColors.brand500.withValues(alpha: 0.30)
              : c.borderSubtle,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hovered = v),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: AppColors.brand500.withValues(alpha: 0.08),
          highlightColor: AppColors.brand500.withValues(alpha: 0.04),
          child: Padding(
            padding: widget.padding ??
                const EdgeInsets.all(AppSpacing.statCardPad),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Section panel card with a header title + child content.
class SectionPanel extends StatelessWidget {
  const SectionPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.panelPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sp16),
          child,
        ],
      ),
    );
  }
}

/// Stat card — label + large value + optional sub-label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.statLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Icon(icon, size: 16, color: AppColorScheme.of(context).textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sp8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                style: AppTextStyles.statValue.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                ),
                maxLines: 1,
              ),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: AppSpacing.sp4),
            Text(sub!, style: AppTextStyles.xs.copyWith(color: AppColorScheme.of(context).textMuted)),
          ],
        ],
      ),
    );
  }
}
