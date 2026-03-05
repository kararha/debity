import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Red-tinted error banner shown above or below a form.
///
/// Matches spec:
///  - Background : red-500/10
///  - Border     : 1dp red-500/20
///  - Text       : red-400, 14px
///  - Radius     : 8dp
///  - Padding    : 12dp×16dp
///  - Margin     : bottom 24dp
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp24),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp12,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1AEF4444), // red-500/10
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0x33EF4444), width: 1), // red-500/20
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.base.copyWith(color: AppColors.danger),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
