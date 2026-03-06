import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return loc ?? AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'appName': {
      'ar': 'ديبتي',
      'en': 'Debity',
    },
    'tagline': {
      'ar': 'إدارة الأقساط والديون بذكاء',
      'en': 'Smart installments and debt management',
    },
    'version_label': {
      'ar': 'v1.0.0',
      'en': 'v1.0.0',
    },
    'no_internet': {
      'ar': 'لا يوجد اتصال بالإنترنت',
      'en': 'No internet connection',
    },
    'welcome_title': {
      'ar': 'أهلاً بك في ديبتي',
      'en': 'Welcome to Debity',
    },
    'login_prompt': {
      'ar': 'سجل دخولك للمتابعة',
      'en': 'Sign in to continue',
    },
    'email_label': {
      'ar': 'البريد الإلكتروني',
      'en': 'Email',
    },
    // 'password_label' already defined above
    'login_button': {
      'ar': 'تسجيل الدخول',
      'en': 'Sign In',
    },
    'no_account': {
      'ar': 'ليس لديك حساب؟',
      'en': 'Don\'t have an account?',
    },
    'create_account': {
      'ar': 'إنشاء حساب جديد',
      'en': 'Create account',
    },
    // Register screen
    'register_title': {
      'ar': 'إنشاء حساب جديد',
      'en': 'Create an account',
    },
    'register_subtitle': {
      'ar': 'أدخل بياناتك لإنشاء حساب',
      'en': 'Fill your details to create an account',
    },
    'full_name_label': {
      'ar': 'الاسم الكامل',
      'en': 'Full name',
    },
    'full_name_required': {
      'ar': 'الرجاء إدخال الاسم',
      'en': 'Please enter a name',
    },
    'phone_label': {
      'ar': 'رقم الهاتف',
      'en': 'Phone number',
    },
    'phone_hint': {
      'ar': '07xxxxxxxxx أو +9647xxxxxxxxx',
      'en': '07xxxxxxxxx or +9647xxxxxxxxx',
    },
    'phone_required': {
      'ar': 'الرجاء إدخال رقم الهاتف',
      'en': 'Please enter phone number',
    },
    'phone_too_short': {
      'ar': 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل',
      'en': 'Phone number must be at least 10 digits',
    },
    'password_label': {
      'ar': 'كلمة المرور',
      'en': 'Password',
    },
    'password_requirements': {
      'ar': 'كلمة المرور لا تستوفي الشروط',
      'en': 'Password does not meet requirements',
    },
    'password_required': {
      'ar': 'الرجاء إدخال كلمة المرور',
      'en': 'Please enter a password',
    },
    'register_button': {
      'ar': 'إنشاء حساب',
      'en': 'Create account',
    },
    'already_have_account': {
      'ar': 'لديك حساب بالفعل؟',
      'en': 'Already have an account?',
    },
    'sign_in': {
      'ar': 'تسجيل الدخول',
      'en': 'Sign in',
    },
    // Verify email screen
    'verify_email_title': {
      'ar': 'تحقق من بريدك الإلكتروني',
      'en': 'Check your email',
    },
    'verify_email_sent_to': {
      'ar': 'تم إرسال رسالة تأكيد إلى',
      'en': 'A confirmation email was sent to',
    },
    'open_confirmation_email': {
      'ar': 'افتح رسالة التأكيد في بريدك',
      'en': 'Open the confirmation email',
    },
    'click_activation_link': {
      'ar': 'انقر على رابط التفعيل في الرسالة',
      'en': 'Tap the activation link in the message',
    },
    'return_to_app_and_login': {
      'ar': 'ارجع إلى التطبيق وسجّل دخولك',
      'en': 'Return to the app and sign in',
    },
    'go_to_login': {
      'ar': 'الذهاب إلى تسجيل الدخول',
      'en': 'Go to sign in',
    },
    'check_spam_note': {
      'ar': 'لم تصلك الرسالة؟ تحقق من مجلد الرسائل المزعجة (Spam)',
      'en': 'Didn\'t receive the email? Check your Spam folder',
    },
    'required_suffix': {
      'ar': 'مطلوب',
      'en': 'required',
    },
    'invalid_suffix': {
      'ar': 'غير صحيحة',
      'en': 'is invalid',
    },
    // Home / Dashboard
    'nav_home': {
      'ar': 'الرئيسية',
      'en': 'Home',
    },
    'nav_customers': {
      'ar': 'العملاء',
      'en': 'Customers',
    },
    'nav_debts': {
      'ar': 'الديون',
      'en': 'Debts',
    },
    'nav_settings': {
      'ar': 'الإعدادات',
      'en': 'Settings',
    },
    'dashboard_title': {
      'ar': 'لوحة التحكم',
      'en': 'Dashboard',
    },
    'retry': {
      'ar': 'إعادة المحاولة',
      'en': 'Retry',
    },
    'stat_total_debts': {
      'ar': 'إجمالي الديون',
      'en': 'Total debts',
    },
    'stat_total_remaining': {
      'ar': 'المبلغ المتبقي',
      'en': 'Remaining amount',
    },
    'stat_total_paid': {
      'ar': 'المبلغ المدفوع',
      'en': 'Paid amount',
    },
    'stat_overdue_installments': {
      'ar': 'أقساط متأخرة',
      'en': 'Overdue installments',
    },
    'mini_active_debts': {
      'ar': 'ديون نشطة',
      'en': 'Active debts',
    },
    'mini_completed_debts': {
      'ar': 'ديون مكتملة',
      'en': 'Completed debts',
    },
    'section_overdue_installments': {
      'ar': 'الأقساط المتأخرة',
      'en': 'Overdue installments',
    },
    'section_top_debtors': {
      'ar': 'أعلى العملاء مديونية',
      'en': 'Top debtors',
    },
    'no_overdue_installments': {
      'ar': 'لا توجد أقساط متأخرة',
      'en': 'No overdue installments',
    },
    'no_data': {
      'ar': 'لا توجد بيانات',
      'en': 'No data',
    },
  };

  String _t(String key) {
    final code = locale.languageCode;
    return _localizedValues[key]?[code] ?? _localizedValues[key]?['en'] ?? key;
  }

  String get appName => _t('appName')!;
  String get tagline => _t('tagline')!;
  String get versionLabel => _t('version_label')!;
  String get noInternet => _t('no_internet')!;
  String get welcomeTitle => _t('welcome_title')!;
  String get loginPrompt => _t('login_prompt')!;
  String get emailLabel => _t('email_label')!;
  String get passwordLabel => _t('password_label')!;
  String get loginButton => _t('login_button')!;
  String get noAccount => _t('no_account')!;
  String get createAccount => _t('create_account')!;
  // Register
  String get registerTitle => _t('register_title')!;
  String get registerSubtitle => _t('register_subtitle')!;
  String get fullName_label => _t('full_name_label')!;
  String get full_name_required => _t('full_name_required')!;
  String get phone_label => _t('phone_label')!;
  String get phone_hint => _t('phone_hint')!;
  String get phone_required => _t('phone_required')!;
  String get phone_too_short => _t('phone_too_short')!;
  String get password_requirements => _t('password_requirements')!;
  String get register_button => _t('register_button')!;
  String get already_have_account => _t('already_have_account')!;
  String get sign_in => _t('sign_in')!;
  String get passwordRequired => _t('password_required')!;

  // Verify email
  String get verifyEmailTitle => _t('verify_email_title')!;
  String get verifyEmailSentTo => _t('verify_email_sent_to')!;
  String get openConfirmationEmail => _t('open_confirmation_email')!;
  String get clickActivationLink => _t('click_activation_link')!;
  String get returnToAppAndLogin => _t('return_to_app_and_login')!;
  String get goToLogin => _t('go_to_login')!;
  String get checkSpamNote => _t('check_spam_note')!;
  String get requiredSuffix => _t('required_suffix')!;
  String get invalidSuffix => _t('invalid_suffix')!;
  // Home / Dashboard
  String get navHome => _t('nav_home')!;
  String get navCustomers => _t('nav_customers')!;
  String get navDebts => _t('nav_debts')!;
  String get navSettings => _t('nav_settings')!;
  String get dashboardTitle => _t('dashboard_title')!;
  String get retry => _t('retry')!;
  String get statTotalDebts => _t('stat_total_debts')!;
  String get statTotalRemaining => _t('stat_total_remaining')!;
  String get statTotalPaid => _t('stat_total_paid')!;
  String get statOverdueInstallments => _t('stat_overdue_installments')!;
  String get miniActiveDebts => _t('mini_active_debts')!;
  String get miniCompletedDebts => _t('mini_completed_debts')!;
  String get sectionOverdueInstallments => _t('section_overdue_installments')!;
  String get sectionTopDebtors => _t('section_top_debtors')!;
  String get noOverdueInstallments => _t('no_overdue_installments')!;
  String get noData => _t('no_data')!;

  // Backwards-compatible snake_case getters used across the app
  String get register_title => _t('register_title')!;
  String get register_subtitle => _t('register_subtitle')!;
  String get full_name_label => _t('full_name_label')!;
  String get full_name_required_snake => _t('full_name_required')!;
  String get phone_label_snake => _t('phone_label')!;
  String get phone_hint_snake => _t('phone_hint')!;
  String get phone_required_snake => _t('phone_required')!;
  String get phone_too_short_snake => _t('phone_too_short')!;
  String get password_label => _t('password_label')!;
  String get register_button_snake => _t('register_button')!;
  String get already_have_account_snake => _t('already_have_account')!;
  String get sign_in_snake => _t('sign_in')!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
