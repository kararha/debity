import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// All supported debt/installment status values.
enum DebtStatus { paid, partial, overdue, pending, active, completed, cancelled }

/// Pill badge matching the Debity design system.
///
/// Each status has a defined text-color, background-color (10% opacity), and
/// an uppercase label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        cfg.label,
        style: AppTextStyles.badgeText.copyWith(color: cfg.fg),
      ),
    );
  }

  // ── Static factory helpers ─────────────────────────────────────────
  static Widget fromString(String raw) {
    final s = _parse(raw);
    return StatusBadge(status: s);
  }

  static DebtStatus _parse(String raw) {
    return switch (raw.toLowerCase().trim()) {
      'paid'      => DebtStatus.paid,
      'partial'   => DebtStatus.partial,
      'overdue'   => DebtStatus.overdue,
      'active'    => DebtStatus.active,
      'completed' => DebtStatus.completed,
      'cancelled' => DebtStatus.cancelled,
      _           => DebtStatus.pending,
    };
  }
}

// ── Config ─────────────────────────────────────────────────────────────
class _BadgeCfg {
  const _BadgeCfg(this.fg, this.bg, this.label);
  final Color fg;
  final Color bg;
  final String label;
}

const _config = <DebtStatus, _BadgeCfg>{
  DebtStatus.paid: _BadgeCfg(
    AppColors.success,
    Color(0x1A34D399), // success/10
    'PAID',
  ),
  DebtStatus.partial: _BadgeCfg(
    AppColors.warning,
    Color(0x1AFBBF24), // warning/10
    'PARTIAL',
  ),
  DebtStatus.overdue: _BadgeCfg(
    AppColors.danger,
    Color(0x1AF87171), // danger/10
    'OVERDUE',
  ),
  DebtStatus.pending: _BadgeCfg(
    AppColors.textSecondary,
    Color(0x1A94A3B8), // slate-400/10
    'PENDING',
  ),
  DebtStatus.active: _BadgeCfg(
    AppColors.success,
    Color(0x1A34D399),
    'ACTIVE',
  ),
  DebtStatus.completed: _BadgeCfg(
    AppColors.brand400,
    Color(0x1A8B9EDD), // brand-400/10
    'COMPLETED',
  ),
  DebtStatus.cancelled: _BadgeCfg(
    AppColors.textSecondary,
    Color(0x1A94A3B8),
    'CANCELLED',
  ),
};

/// Small circular badge used on tabs/headers to show an overdue count.
class OverdueBadge extends StatelessWidget {
  const OverdueBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x26F87171), // red-500/15
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: const Color(0x33F87171), width: 1), // red-500/20
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTextStyles.xs.copyWith(
          color: AppColors.danger,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
