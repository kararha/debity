import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Number formatting utilities
class NumberFormatter {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ar_IQ',
    symbol: 'د.ع',
    decimalDigits: 0,
  );

  static final _compactFormat = NumberFormat.compact(locale: 'ar');

  /// Format number as Iraqi Dinar currency
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format number in compact form (K, M, etc.)
  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  /// Format percentage
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

/// Date formatting utilities
class DateFormatter {
  static final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
  static final _timeFormat = DateFormat('HH:mm', 'ar');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'ar');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Get relative date text (today, tomorrow, yesterday, etc.)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'اليوم';
    if (difference == 1) return 'غداً';
    if (difference == -1) return 'أمس';
    if (difference > 1 && difference <= 7) return 'بعد $difference أيام';
    if (difference < -1 && difference >= -7) return 'منذ ${-difference} أيام';
    return formatDate(date);
  }

  /// Get days until date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.difference(today).inDays;
  }
}

/// Status color helpers
class StatusColors {
  static Color getInstallmentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.paidColor;
      case 'pending':
        return AppColors.pendingColor;
      case 'overdue':
        return AppColors.overdueColor;
      case 'partial':
        return AppColors.partialColor;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color getDebtStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.pendingColor;
      case 'completed':
        return AppColors.paidColor;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Spacing constants
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
}

/// Border radius constants
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}

/// Animation durations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// Icon sizes
class AppIconSizes {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
  static const double xxl = 64;
}
