/// Password validation rules enforced on the Flutter side.
/// Regex: /^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$/
///
/// Four conditions displayed as a live checklist while the user types:
///  1. At least 8 characters
///  2. At least one letter (A–Z / a–z)
///  3. At least one number (0–9)
///  4. At least one special character
class PasswordValidator {
  const PasswordValidator._();

  static final RegExp _fullRegex = RegExp(
    r'''^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$''',
  );

  // ── Individual rule checks ─────────────────────────────────────────────────

  static bool hasMinLength(String value) => value.length >= 8;

  static bool hasLetter(String value) => value.contains(RegExp(r'[A-Za-z]'));

  static bool hasDigit(String value) => value.contains(RegExp(r'\d'));

  static bool hasSpecial(String value) =>
      value.contains(RegExp(r'''[!@#$%^&*()\-_=+\[\]{};':"\\|,.<>\/?]'''));

  // ── Full validation ────────────────────────────────────────────────────────

  /// Returns true when the password meets all four rules.
  static bool isValid(String value) => _fullRegex.hasMatch(value);

  /// Returns an Arabic error message or null if valid.
  /// Used in form validators.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (!hasMinLength(value)) {
      return 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل';
    }
    if (!hasLetter(value)) {
      return 'يجب أن تحتوي على حرف واحد على الأقل';
    }
    if (!hasDigit(value)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!hasSpecial(value)) {
      return 'يجب أن تحتوي على رمز خاص واحد على الأقل (!@#\$…)';
    }
    return null;
  }

  // ── Localised rule labels ──────────────────────────────────────────────────

  static const List<_PasswordRule> rules = [
    _PasswordRule(
      label: '8 أحرف على الأقل',
      labelEn: 'At least 8 characters',
      check: hasMinLength,
    ),
    _PasswordRule(
      label: 'حرف واحد على الأقل (A–Z)',
      labelEn: 'At least one letter',
      check: hasLetter,
    ),
    _PasswordRule(
      label: 'رقم واحد على الأقل (0–9)',
      labelEn: 'At least one number',
      check: hasDigit,
    ),
    _PasswordRule(
      label: 'رمز خاص واحد على الأقل (!@#\$…)',
      labelEn: 'At least one special character',
      check: hasSpecial,
    ),
  ];
}

/// Describes a single password rule.
class _PasswordRule {
  final String label;
  final String labelEn;
  final bool Function(String) check;

  const _PasswordRule({
    required this.label,
    required this.labelEn,
    required this.check,
  });
}

// ── Re-export for consumers ────────────────────────────────────────────────

/// Public alias so consumers can iterate rules easily.
typedef PasswordRule = _PasswordRule;
