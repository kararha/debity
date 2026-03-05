import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'debity_logo.dart';

/// Debity top app bar matching the design spec.
///
/// Height: 64dp
/// Background: surface1
/// Bottom border: 1dp borderSubtle
///
/// Left  : DebityLogo (size sm + wordmark)
/// Right :
///   - Language toggle pill (EN/AR)
///   - User avatar circle
///   - Logout icon button
class DebityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DebityAppBar({
    super.key,
    this.userInitial,
    this.currentLocale = 'AR',
    this.onLocaleToggle,
    this.onLogout,
    this.actions,
  });

  final String? userInitial;
  final String currentLocale;
  final VoidCallback? onLocaleToggle;
  final VoidCallback? onLogout;
  /// Extra custom actions prepended before the standard controls.
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarH);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.appBarH + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
        child: Row(
          children: [
            const DebityLogo(size: LogoSize.sm),
            const Spacer(),
            if (actions != null) ...actions!,
            // Language toggle pill
            if (onLocaleToggle != null) ...[
              _LanguagePill(locale: currentLocale, onTap: onLocaleToggle!),
              const SizedBox(width: AppSpacing.sp8),
            ],
            // User avatar
            if (userInitial != null) ...[
              _UserAvatar(initial: userInitial!),
              const SizedBox(width: AppSpacing.sp8),
            ],
            // Logout
            if (onLogout != null)
              _LogoutButton(onPressed: onLogout!),
          ],
        ),
      ),
    );
  }
}

// ─── Language pill ──────────────────────────────────────────────────────────

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.locale, required this.onTap});
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Text(
          locale,
          style: AppTextStyles.xs.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─── User avatar ────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.brand500,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: AppTextStyles.base.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ─── Logout button ──────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      onHover: (v) => setState(() => _hovered = v),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.logout_rounded,
          size: 20,
          color: _hovered ? AppColors.danger : AppColors.textSecondary,
        ),
      ),
    );
  }
}
