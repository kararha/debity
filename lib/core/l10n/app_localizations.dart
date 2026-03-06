import 'package:flutter/widgets.dart';

// Ignore noisy lints created during incremental i18n migration.
// The file intentionally includes snake_case getters for backwards compatibility
// and some unnecessary '!' assertions that are harmless because _t() always
// returns a non-null String. Suppress those analyzer warnings here.
// ignore_for_file: unnecessary_non_null_assertion, non_constant_identifier_names

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
    // Customers
    'customers_title': {
      'ar': 'العملاء',
      'en': 'Customers',
    },
    'customers_count': {
      'ar': '{count} عميل',
      'en': '{count} customers',
    },
    'customers_search_hint': {
      'ar': 'بحث عن عميل...',
      'en': 'Search customers...',
    },
    'add_customer': {
      'ar': 'إضافة عميل',
      'en': 'Add customer',
    },
    'load_failed': {
      'ar': 'تعذّر التحميل',
      'en': 'Failed to load',
    },
    'no_customers_yet': {
      'ar': 'لا يوجد عملاء بعد',
      'en': 'No customers yet',
    },
    'no_results': {
      'ar': 'لا توجد نتائج',
      'en': 'No results',
    },
    'add_first_customer_note': {
      'ar': 'أضف عميلك الأول بالضغط على +',
      'en': 'Add your first customer by tapping +',
    },
    'try_different_search': {
      'ar': 'جرّب كلمات بحث مختلفة',
      'en': 'Try different search terms',
    },
    // Add / Edit customer
    'add_customer_success': {
      'ar': 'تم إضافة العميل بنجاح',
      'en': 'Customer added',
    },
    'update_customer_success': {
      'ar': 'تم تحديث العميل بنجاح',
      'en': 'Customer updated',
    },
    'basic_info': {
      'ar': 'المعلومات الأساسية',
      'en': 'Basic information',
    },
    'extra_info': {
      'ar': 'معلومات إضافية',
      'en': 'Extra information',
    },
    'name_label': {
      'ar': 'اسم العميل',
      'en': 'Customer name',
    },
    'name_required': {
      'ar': 'الرجاء إدخال اسم العميل',
      'en': 'Please enter a name',
    },
    'name_too_short': {
      'ar': 'الاسم يجب أن يكون حرفين على الأقل',
      'en': 'Name must be at least 2 characters',
    },
    'phone_invalid': {
      'ar': 'رقم الهاتف غير صحيح',
      'en': 'Phone number is invalid',
    },
    'address_label': {
      'ar': 'العنوان',
      'en': 'Address',
    },
    'address_hint': {
      'ar': 'أدخل عنوان العميل (اختياري)',
      'en': 'Enter address (optional)',
    },
    'notes_label': {
      'ar': 'ملاحظات',
      'en': 'Notes',
    },
    'save_changes': {
      'ar': 'حفظ التغييرات',
      'en': 'Save changes',
    },
    'add_customer_button': {
      'ar': 'إضافة العميل',
      'en': 'Add customer',
    },
    'delete_customer_title': {
      'ar': 'حذف العميل',
      'en': 'Delete customer',
    },
    'delete_customer_confirm': {
      'ar': 'هل أنت متأكد من حذف "{name}"؟\nسيتم حذف جميع الديون والأقساط المرتبطة به.',
      'en': 'Are you sure you want to delete "{name}"?\nAll debts and installments will be removed.',
    },
    'cancel': {
      'ar': 'إلغاء',
      'en': 'Cancel',
    },
    'delete': {
      'ar': 'حذف',
      'en': 'Delete',
    },
    'delete_success': {
      'ar': 'تم حذف العميل بنجاح',
      'en': 'Customer deleted',
    },
    'delete_error': {
      'ar': 'خطأ في حذف العميل',
      'en': 'Failed to delete customer',
    },
    'failed_load_debts': {
      'ar': 'خطأ في تحميل الديون',
      'en': 'Failed to load debts',
    },
    'call': {
      'ar': 'اتصال',
      'en': 'Call',
    },
    'message': {
      'ar': 'رسالة',
      'en': 'Message',
    },
    'whatsapp': {
      'ar': 'واتساب',
      'en': 'WhatsApp',
    },
    'total_debts': {
      'ar': 'إجمالي الديون',
      'en': 'Total debts',
    },
    'total_paid': {
      'ar': 'إجمالي المدفوع',
      'en': 'Total paid',
    },
    'remaining': {
      'ar': 'المتبقي',
      'en': 'Remaining',
    },
    'active_debts': {
      'ar': 'الديون النشطة',
      'en': 'Active debts',
    },
    'debts_title': {
      'ar': 'الديون',
      'en': 'Debts',
    },
    'no_debts_for_customer': {
      'ar': 'لا توجد ديون لهذا العميل',
      'en': 'No debts for this customer',
    },
    // Installments
    'installments_title': {
      'ar': 'الأقساط',
      'en': 'Installments',
    },
    'installments_tab_all': {
      'ar': 'الكل ({count})',
      'en': 'All ({count})',
    },
    'installments_tab_pending': {
      'ar': 'معلقة ({count})',
      'en': 'Pending ({count})',
    },
    'installments_tab_overdue': {
      'ar': 'متأخرة ({count})',
      'en': 'Overdue ({count})',
    },
    'installments_tab_paid': {
      'ar': 'مدفوعة ({count})',
      'en': 'Paid ({count})',
    },
    'filter_all': {
      'ar': 'الكل',
      'en': 'All',
    },
    'filter_today': {
      'ar': 'اليوم',
      'en': 'Today',
    },
    'filter_week': {
      'ar': 'الأسبوع',
      'en': 'Week',
    },
    'filter_month': {
      'ar': 'الشهر',
      'en': 'Month',
    },
    'no_installments': {
      'ar': 'لا توجد أقساط',
      'en': 'No installments',
    },
    'enter_valid_amount': {
      'ar': 'الرجاء إدخال مبلغ صحيح',
      'en': 'Please enter a valid amount',
    },
    'amount_greater_than_remaining': {
      'ar': 'المبلغ أكبر من المتبقي',
      'en': 'Amount is greater than remaining',
    },
    'payment_full_success': {
      'ar': 'تم دفع القسط بالكامل',
      'en': 'Installment fully paid',
    },
    'payment_partial_success': {
      'ar': 'تم تسجيل الدفعة الجزئية',
      'en': 'Partial payment recorded',
    },
    'payment_error': {
      'ar': 'خطأ في الدفع',
      'en': 'Payment failed',
    },
    'payment_title': {
      'ar': 'دفع القسط',
      'en': 'Pay installment',
    },
    'payment_options': {
      'ar': 'خيارات الدفع',
      'en': 'Payment options',
    },
    'pay_full': {
      'ar': 'دفع كامل',
      'en': 'Pay full',
    },
    'pay_partial': {
      'ar': 'دفع جزئي',
      'en': 'Pay partial',
    },
    'enter_amount': {
      'ar': 'حدد المبلغ',
      'en': 'Enter amount',
    },
    'amount_label': {
      'ar': 'المبلغ',
      'en': 'Amount',
    },
    'amount_paid_label': {
      'ar': 'المبلغ المدفوع',
      'en': 'Amount paid',
    },
    'notes_optional': {
      'ar': 'ملاحظات (اختياري)',
      'en': 'Notes (optional)',
    },
    'confirm_payment': {
      'ar': 'تأكيد الدفع',
      'en': 'Confirm payment',
    },
    'installment_label': {
      'ar': 'قسط {num}',
      'en': 'Installment {num}',
    },
    'days_overdue': {
      'ar': 'متأخر {n} يوم',
      'en': '{n} days overdue',
    },
    'days_in_future': {
      'ar': 'بعد {n} يوم',
      'en': 'in {n} days',
    },
    // Language
    'language_label': {
      'ar': 'اللغة',
      'en': 'Language',
    },
    'language_ar': {
      'ar': 'العربية',
      'en': 'Arabic',
    },
    'language_en': {
      'ar': 'الإنجليزية',
      'en': 'English',
    },
    // Settings & Notifications
    'settings_title': {
      'ar': 'الإعدادات',
      'en': 'Settings',
    },
    'app_info_section': {
      'ar': 'معلومات التطبيق',
      'en': 'App info',
    },
    'appearance_section': {
      'ar': 'المظهر',
      'en': 'Appearance',
    },
    'notifications_section': {
      'ar': 'الإشعارات',
      'en': 'Notifications',
    },
    'enable_notifications': {
      'ar': 'تفعيل الإشعارات',
      'en': 'Enable notifications',
    },
    'enable_notifications_sub': {
      'ar': 'استلام إشعارات التذكير',
      'en': 'Receive reminder notifications',
    },
    'daily_reminder': {
      'ar': 'تذكير يومي',
      'en': 'Daily reminder',
    },
    'daily_reminder_sub': {
      'ar': 'تذكير بالأقساط المستحقة',
      'en': 'Remind about due installments',
    },
    'overdue_alerts': {
      'ar': 'تنبيه المتأخرات',
      'en': 'Overdue alerts',
    },
    'overdue_alerts_sub': {
      'ar': 'تنبيه عند تأخر الأقساط',
      'en': 'Notify when installments are overdue',
    },
    'reminder_before_label': {
      'ar': 'التذكير قبل',
      'en': 'Reminder before',
    },
    'test_notifications_section': {
      'ar': 'اختبار الإشعارات',
      'en': 'Test notifications',
    },
    'test_notification_now': {
      'ar': 'إشعار تجريبي فوري',
      'en': 'Send instant test notification',
    },
    'send_due_notifications': {
      'ar': 'إرسال إشعارات المستحقات',
      'en': 'Send due notifications',
    },
    'show_fcm_token': {
      'ar': 'عرض رمز FCM',
      'en': 'Show FCM token',
    },
    'data_section': {
      'ar': 'البيانات',
      'en': 'Data',
    },
    'sync_data': {
      'ar': 'مزامنة البيانات',
      'en': 'Sync data',
    },
    'update_overdues': {
      'ar': 'تحديث المتأخرات',
      'en': 'Update overdue',
    },
    'about_section': {
      'ar': 'حول',
      'en': 'About',
    },
    'privacy_policy': {
      'ar': 'سياسة الخصوصية',
      'en': 'Privacy policy',
    },
    'privacy_policy_content': {
      'ar': 'يلتزم تطبيق ديبتي بحماية خصوصية مستخدميه على النحو التالي:\n\n• جمع البيانات: يجمع التطبيق بيانات العملاء والأقساط التي تُدخلها أنت فقط، ولا يجمع أي بيانات شخصية دون إذنك.\n\n• تخزين البيانات: تُحفظ جميع البيانات بشكل مشفّر على خوادم Supabase الآمنة.\n\n• مشاركة البيانات: لا يتم مشاركة أي بيانات مع أطراف ثالثة بأي حال.\n\n• الإشعارات: تُستخدم بيانات FCM فقط لإرسال تذكيرات الأقساط لك.\n\n• للتواصل: karar.haider@debity.app',
      'en': 'Debity is committed to protecting user privacy. We collect only the customer and installment data you enter. Data is stored securely on Supabase servers and is not shared with third parties. FCM tokens are used solely for reminders. Contact: karar.haider@debity.app',
    },
    'terms_of_service': {
      'ar': 'شروط الاستخدام',
      'en': 'Terms of service',
    },
    'terms_of_service_content': {
      'ar': 'باستخدامك لتطبيق ديبتي، فإنك توافق على الشروط التالية:\n\n• الاستخدام المسموح: يُستخدم التطبيق لأغراض تتبع الأقساط والديون الشخصية أو التجارية المشروعة فقط.\n\n• المسؤولية: المطوّر غير مسؤول عن أي قرارات مالية تُتخذ بناء على بيانات التطبيق.\n\n• الملكية الفكرية: جميع حقوق التطبيق محفوظة لـ Karar Haider © 2026.\n\n• التعديلات: يحق للمطوّر تعديل هذه الشروط في أي وقت مع إشعار المستخدمين.\n\n• إنهاء الخدمة: يحق لنا إنهاء الخدمة في حالة إساءة الاستخدام.',
      'en': 'By using Debity you agree to the following terms: permitted use is for legitimate personal or business debt tracking; the developer is not responsible for financial decisions made using the app; intellectual property is owned by Karar Haider © 2026; terms may be modified and service may be terminated for abuse.',
    },
    'help_and_support': {
      'ar': 'المساعدة والدعم',
      'en': 'Help & support',
    },
    'help_and_support_content': {
      'ar': 'هل تحتاج إلى مساعدة؟ إليك كيفية التواصل معنا:\n\n📧 البريد الإلكتروني:\nkarar.haider@debity.app\n\n💡 الأسئلة الشائعة:\n• كيف أضيف عميلاً جديداً؟ اضغط على + في شاشة العملاء.\n• كيف أسجّل دفعة قسط؟ افتح تفاصيل الدين ثم اضغط على القسط.\n• هل يمكن استخدام التطبيق بدون إنترنت؟ البيانات تتطلب اتصالاً بالإنترنت للمزامنة.\n\n⏱ وقت الاستجابة: خلال 24 ساعة عمل.\n\nالإصدار الحالي: 1.0.0\nالمطوّر: Karar Haider',
      'en': 'Need help? Contact: karar.haider@debity.app\nFAQ: Tap + on Customers to add a customer. Tap an installment to record payment. The app requires internet to sync. Response time: within 24 business hours. Version: 1.0.0',
    },
    'rate_app': {
      'ar': 'تقييم التطبيق',
      'en': 'Rate app',
    },
    'rate_app_content': {
      'ar': 'هل تستمتع باستخدام ديبتي؟\n\nتقييمك يساعدنا على تحسين التطبيق وتطويره باستمرار.\n\nشكراً لدعمك! 🙏',
      'en': 'Enjoying Debity? Your rating helps us improve the app. Thank you for your support!',
    },
    'logout': {
      'ar': 'تسجيل الخروج',
      'en': 'Log out',
    },
    'confirm_logout': {
      'ar': 'هل تريد فعلاً تسجيل الخروج من حسابك؟',
      'en': 'Do you really want to log out?',
    },
    'copied': {
      'ar': 'تم النسخ',
      'en': 'Copied',
    },
    'developer_label': {
      'ar': 'المطور',
      'en': 'Developer',
    },
    'test_notification_sub': {
      'ar': 'اختبر ظهور الإشعارات على جهازك',
      'en': 'Test notifications on your device',
    },
    'send_due_notifications_sub': {
      'ar': 'إرسال FCM لأقساط غداً',
      'en': 'Send FCM for installments due tomorrow',
    },
    'fcm_token_subtitle': {
      'ar': 'رمز الجهاز لاختبار الإشعارات',
      'en': 'Device token for testing notifications',
    },
    'sync_data_sub': {
      'ar': 'تحديث البيانات من الخادم',
      'en': 'Refresh data from server',
    },
    'update_overdues_sub': {
      'ar': 'فحص وتحديث حالة الأقساط',
      'en': 'Check and update installment status',
    },
    'logout_sub': {
      'ar': 'تسجيل الخروج من حسابك',
      'en': 'Sign out of your account',
    },
    'copyright': {
      'ar': '© 2026 جميع الحقوق محفوظة',
      'en': '© 2026 All rights reserved',
    },
    'copy': {
      'ar': 'نسخ',
      'en': 'Copy',
    },
    // Notifications
    'notifications_title': {
      'ar': 'الإشعارات',
      'en': 'Notifications',
    },
    'refresh_reminders': {
      'ar': 'تحديث التذكيرات',
      'en': 'Refresh reminders',
    },
    'check_overdue': {
      'ar': 'فحص المتأخرات',
      'en': 'Check overdue',
    },
    'no_notifications': {
      'ar': 'لا توجد إشعارات',
      'en': 'No notifications',
    },
    'all_clear_message': {
      'ar': 'جميع الأقساط تحت السيطرة!',
      'en': 'All installments are under control!',
    },
    'new_notifications_created': {
      'ar': 'تم إنشاء {count} إشعار جديد',
      'en': '{count} new notification(s) created',
    },
    'updated_overdue_summary': {
      'ar': 'تم تحديث {new} قسط متأخر\nإجمالي المتأخرات: {total}',
      'en': '{new} overdue installment(s) updated\nTotal overdue: {total}',
    },
    // Debts
    'debts_search_hint': {
      'ar': 'بحث عن دين...',
      'en': 'Search debts...',
    },
    'add_debt': {
      'ar': 'إضافة دين',
      'en': 'Add debt',
    },
    'no_debts': {
      'ar': 'لا توجد ديون',
      'en': 'No debts',
    },
    'press_plus_add_debt': {
      'ar': 'اضغط + لإضافة دين جديد',
      'en': 'Press + to add a new debt',
    },
    'tab_all': {
      'ar': 'الكل ({count})',
      'en': 'All ({count})',
    },
    'tab_active': {
      'ar': 'نشط ({count})',
      'en': 'Active ({count})',
    },
    'tab_completed': {
      'ar': 'مكتمل ({count})',
      'en': 'Completed ({count})',
    },
    'status_active': {
      'ar': 'نشط',
      'en': 'Active',
    },
    'status_completed': {
      'ar': 'مكتمل',
      'en': 'Completed',
    },
    'status_cancelled': {
      'ar': 'ملغي',
      'en': 'Cancelled',
    },
    // Status badges
    'status_paid': {
      'ar': 'مدفوع',
      'en': 'Paid',
    },
    'status_partial': {
      'ar': 'جزئي',
      'en': 'Partial',
    },
    'status_overdue': {
      'ar': 'متأخر',
      'en': 'Overdue',
    },
    'status_pending': {
      'ar': 'قيد الانتظار',
      'en': 'Pending',
    },
    'progress_label': {
      'ar': 'التقدم',
      'en': 'Progress',
    },
    'paid_label': {
      'ar': 'مدفوع',
      'en': 'Paid',
    },
    'remaining_label': {
      'ar': 'متبقي',
      'en': 'Remaining',
    },
    'total_label': {
      'ar': 'إجمالي',
      'en': 'Total',
    },
    'installments_label': {
      'ar': 'الأقساط',
      'en': 'Installments',
    },
    'due_date_label': {
      'ar': 'تاريخ الاستحقاق',
      'en': 'Due date',
    },
    'selling_price': {
      'ar': 'سعر البيع',
      'en': 'Selling price',
    },
    'delete_debt_title': {
      'ar': 'حذف الدين',
      'en': 'Delete debt',
    },
    'delete_debt_confirm': {
      'ar': 'هل أنت متأكد من حذف هذا الدين المرتبط بـ "{name}"؟\nسيتم حذف جميع الأقساط المرتبطة.',
      'en': 'Are you sure you want to delete this debt linked to "{name}"?\nAll installments will be removed.',
    },
    'delete_debt_success': {
      'ar': 'تم حذف الدين بنجاح',
      'en': 'Debt deleted',
    },
    'delete_debt_error': {
      'ar': 'خطأ في حذف الدين',
      'en': 'Failed to delete debt',
    },
    'greeting_morning': {
      'ar': 'صباح الخير ☀️',
      'en': 'Good morning ☀️',
    },
    'greeting_afternoon': {
      'ar': 'مساء الخير 🌤️',
      'en': 'Good afternoon 🌤️',
    },
    'greeting_evening': {
      'ar': 'مساء النور 🌙',
      'en': 'Good evening 🌙',
    },
    'overdue_alert': {
      'ar': '{count} قسط متأخر — تحتاج إلى مراجعة',
      'en': '{count} overdue installment — please review',
    },
    'customer_label': {
      'ar': 'عميل',
      'en': 'Customer',
    },
    'remaining_amount_label': {
      'ar': 'المبلغ المتبقي',
      'en': 'Remaining amount',
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
  String get greetingMorning => _t('greeting_morning')!;
  String get greetingAfternoon => _t('greeting_afternoon')!;
  String get greetingEvening => _t('greeting_evening')!;
  String get overdueAlert => _t('overdue_alert')!;
  String get customerLabel => _t('customer_label')!;
  String get remainingAmountLabel => _t('remaining_amount_label')!;
  // Installments
  String get installmentsTitle => _t('installments_title')!;
  String get filterAll => _t('filter_all')!;
  String get filterToday => _t('filter_today')!;
  String get filterWeek => _t('filter_week')!;
  String get filterMonth => _t('filter_month')!;
  String get noInstallments => _t('no_installments')!;
  String get enterValidAmount => _t('enter_valid_amount')!;
  String get amountGreaterThanRemaining => _t('amount_greater_than_remaining')!;
  String get paymentFullSuccess => _t('payment_full_success')!;
  String get paymentPartialSuccess => _t('payment_partial_success')!;
  String get paymentError => _t('payment_error')!;
  String get paymentTitle => _t('payment_title')!;
  String get paymentOptions => _t('payment_options')!;
  String get payFull => _t('pay_full')!;
  String get payPartial => _t('pay_partial')!;
  String get enterAmount => _t('enter_amount')!;
  String get amountLabel => _t('amount_label')!;
  String get amountPaidLabel => _t('amount_paid_label')!;
  String get notesOptional => _t('notes_optional')!;
  String get confirmPayment => _t('confirm_payment')!;
  String get installmentLabel => _t('installment_label')!;
  String get daysOverdue => _t('days_overdue')!;
  String get daysInFuture => _t('days_in_future')!;
  // Language
  String get languageLabel => _t('language_label')!;
  String get languageAr => _t('language_ar')!;
  String get languageEn => _t('language_en')!;
  // Settings & Notifications getters
  String get settingsTitle => _t('settings_title')!;
  String get appInfoSection => _t('app_info_section')!;
  String get appearanceSection => _t('appearance_section')!;
  String get notificationsSection => _t('notifications_section')!;
  String get enableNotifications => _t('enable_notifications')!;
  String get enableNotificationsSub => _t('enable_notifications_sub')!;
  String get dailyReminder => _t('daily_reminder')!;
  String get dailyReminderSub => _t('daily_reminder_sub')!;
  String get overdueAlerts => _t('overdue_alerts')!;
  String get overdueAlertsSub => _t('overdue_alerts_sub')!;
  String get reminderBeforeLabel => _t('reminder_before_label')!;
  String get testNotificationsSection => _t('test_notifications_section')!;
  String get testNotificationNow => _t('test_notification_now')!;
  String get sendDueNotifications => _t('send_due_notifications')!;
  String get showFcmToken => _t('show_fcm_token')!;
  String get dataSection => _t('data_section')!;
  String get syncData => _t('sync_data')!;
  String get updateOverdues => _t('update_overdues')!;
  String get aboutSection => _t('about_section')!;
  String get privacyPolicy => _t('privacy_policy')!;
  String get termsOfService => _t('terms_of_service')!;
  String get helpAndSupport => _t('help_and_support')!;
  String get rateApp => _t('rate_app')!;
  String get logoutLabel => _t('logout')!;
  String get confirmLogout => _t('confirm_logout')!;
  String get copied => _t('copied')!;
  String get copy => _t('copy')!;
  String get developerLabel => _t('developer_label')!;
  String get testNotificationSub => _t('test_notification_sub')!;
  String get sendDueNotificationsSub => _t('send_due_notifications_sub')!;
  String get fcmTokenSubtitle => _t('fcm_token_subtitle')!;
  String get syncDataSub => _t('sync_data_sub')!;
  String get updateOverduesSub => _t('update_overdues_sub')!;
  String get logoutSub => _t('logout_sub')!;
  String get copyrightLabel => _t('copyright')!;

  String get privacyPolicyContent => _t('privacy_policy_content')!;
  String get termsOfServiceContent => _t('terms_of_service_content')!;
  String get helpAndSupportContent => _t('help_and_support_content')!;
  String get rateAppContent => _t('rate_app_content')!;
  // Notifications
  String get notificationsTitle => _t('notifications_title')!;
  String get refreshReminders => _t('refresh_reminders')!;
  String get checkOverdue => _t('check_overdue')!;
  String get noNotifications => _t('no_notifications')!;
  String get allClearMessage => _t('all_clear_message')!;
  String newNotificationsCreated(int count) => _t('new_notifications_created').replaceAll('{count}', '$count');
  String updatedOverdueSummary(int newly, int total) => _t('updated_overdue_summary').replaceAll('{new}', '$newly').replaceAll('{total}', '$total');
  // Customers
  String get customersTitle => _t('customers_title')!;
  String get customersCount => _t('customers_count')!;
  String get customersSearchHint => _t('customers_search_hint')!;
  String get addCustomer => _t('add_customer')!;
  String get loadFailed => _t('load_failed')!;
  String get noCustomersYet => _t('no_customers_yet')!;
  String get noResults => _t('no_results')!;
  String get addFirstCustomerNote => _t('add_first_customer_note')!;
  String get tryDifferentSearch => _t('try_different_search')!;
  // Add / Edit customer
  String get addCustomerSuccess => _t('add_customer_success')!;
  String get updateCustomerSuccess => _t('update_customer_success')!;
  String get basicInfo => _t('basic_info')!;
  String get extraInfo => _t('extra_info')!;
  String get nameLabel => _t('name_label')!;
  String get nameRequired => _t('name_required')!;
  String get nameTooShort => _t('name_too_short')!;
  String get phoneInvalid => _t('phone_invalid')!;
  String get addressLabel => _t('address_label')!;
  String get addressHint => _t('address_hint')!;
  String get notesLabel => _t('notes_label')!;
  String get saveChanges => _t('save_changes')!;
  String get addCustomerButton => _t('add_customer_button')!;
  String get deleteCustomerTitle => _t('delete_customer_title')!;
  String get deleteCustomerConfirm => _t('delete_customer_confirm')!;
  String get cancel => _t('cancel')!;
  String get delete => _t('delete')!;
  String get deleteSuccess => _t('delete_success')!;
  String get deleteError => _t('delete_error')!;
  String get failedLoadDebts => _t('failed_load_debts')!;
  String get call => _t('call')!;
  String get message => _t('message')!;
  String get whatsapp => _t('whatsapp')!;
  String get totalDebts => _t('total_debts')!;
  String get totalPaid => _t('total_paid')!;
  String get remaining => _t('remaining')!;
  String get activeDebts => _t('active_debts')!;
  String get debtsTitle => _t('debts_title')!;
  String get noDebtsForCustomer => _t('no_debts_for_customer')!;
  // Debts
  String get debtsSearchHint => _t('debts_search_hint')!;
  String get addDebt => _t('add_debt')!;
  String get noDebts => _t('no_debts')!;
  String get pressPlusAddDebt => _t('press_plus_add_debt')!;
  String tabLabel(String key, int count) => _t(key).replaceAll('{count}', '$count');
  String get statusActive => _t('status_active')!;
  String get statusCompleted => _t('status_completed')!;
  String get statusCancelled => _t('status_cancelled')!;
  String get statusPaid => _t('status_paid')!;
  String get statusPartial => _t('status_partial')!;
  String get statusOverdue => _t('status_overdue')!;
  String get statusPending => _t('status_pending')!;
  String get progressLabel => _t('progress_label')!;
  String get paidLabel => _t('paid_label')!;
  String get remainingLabel => _t('remaining_label')!;
  String get totalLabel => _t('total_label')!;
  String get installmentsLabel => _t('installments_label')!;
  String get dueDateLabel => _t('due_date_label')!;
  String get sellingPrice => _t('selling_price')!;
  String get deleteDebtTitle => _t('delete_debt_title')!;
  String get deleteDebtConfirm => _t('delete_debt_confirm')!;
  String get deleteDebtSuccess => _t('delete_debt_success')!;
  String get deleteDebtError => _t('delete_debt_error')!;

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
