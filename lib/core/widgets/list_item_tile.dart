import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// List item row matching the Debity design system.
///
/// Layout: Row, space-between
///  - Left : primary + secondary text (truncated single line)
///  - Right: amount + date (text right-aligned)
class DebtListItem extends StatefulWidget {
  const DebtListItem({
    super.key,
    required this.primaryText,
    this.secondaryText,
    this.amount,
    this.date,
    this.amountColor,
    this.onTap,
    this.trailing,
  });

  final String primaryText;
  final String? secondaryText;
  final String? amount;
  final String? date;
  final Color? amountColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<DebtListItem> createState() => _DebtListItemState();
}

class _DebtListItemState extends State<DebtListItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.listItemH,
          vertical: AppSpacing.listItemV,
        ),
        decoration: BoxDecoration(
          color: _pressed ? AppColorScheme.of(context).surface3 : AppColorScheme.of(context).surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            // Left column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.primaryText,
                    style: AppTextStyles.listPrimary,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (widget.secondaryText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.secondaryText!,
                      style: AppTextStyles.listSecondary,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right column (optional trailing override)
            if (widget.trailing != null)
              widget.trailing!
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.amount != null)
                    Text(
                      widget.amount!,
                      style: AppTextStyles.listAmount.copyWith(
                        color: widget.amountColor ?? AppColors.of(context).textPrimary,
                      ),
                    ),
                  if (widget.date != null) ...[
                    const SizedBox(height: 2),
                    Text(widget.date!, style: AppTextStyles.listDate),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper to build a vertical list of [DebtListItem]s with 8dp gaps.
class DebtListView extends StatelessWidget {
  const DebtListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: itemBuilder,
    );
  }
}
