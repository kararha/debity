# 🔥 إعداد Firebase Cloud Messaging (FCM)

## الخطوة 1: إنشاء مشروع Firebase

1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. انقر على "Add project" أو "إضافة مشروع"
3. أدخل اسم المشروع: `debity` أو أي اسم تريده
4. اتبع الخطوات لإنشاء المشروع

## الخطوة 2: إضافة تطبيق Android

1. في Firebase Console، انقر على أيقونة Android
2. أدخل اسم الحزمة: `com.example.debity`
   - يمكنك تغييره في `android/app/build.gradle.kts`
3. أدخل لقب التطبيق: `ديبتي`
4. انقر "Register app"

## الخطوة 3: تحميل google-services.json

1. حمّل ملف `google-services.json`
2. ضعه في مجلد: `android/app/google-services.json`

```
debity/
├── android/
│   ├── app/
│   │   ├── google-services.json  <-- ضع الملف هنا
│   │   └── ...
```

## الخطوة 4: إعداد iOS (اختياري)

1. في Firebase Console، انقر على أيقونة iOS
2. أدخل Bundle ID: `com.example.debity`
3. حمّل ملف `GoogleService-Info.plist`
4. ضعه في: `ios/Runner/GoogleService-Info.plist`

## الخطوة 5: الحصول على Server Key

1. في Firebase Console، اذهب إلى ⚙️ Project Settings
2. انقر على "Cloud Messaging" tab
3. انسخ "Server key" (أو أنشئ واحد جديد)

## الخطوة 6: إضافة Server Key في Supabase

```bash
# باستخدام Supabase CLI
supabase secrets set FCM_SERVER_KEY=your-server-key-here
```

أو من Supabase Dashboard:
1. اذهب إلى Settings > Edge Functions
2. أضف Secret جديد:
   - Name: `FCM_SERVER_KEY`
   - Value: Server key من Firebase

## الخطوة 7: تحديث firebase_options.dart (اختياري)

يمكنك استخدام FlutterFire CLI لإنشاء الملف تلقائياً:

```bash
# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# تكوين Firebase
flutterfire configure
```

أو يمكنك تحديث القيم يدوياً في `lib/firebase_options.dart`

## الخطوة 8: تشغيل التطبيق

```bash
flutter pub get
flutter run
```

---

## 🧪 اختبار الإشعارات

### من Firebase Console:
1. اذهب إلى Engage > Messaging
2. انقر "Create your first campaign"
3. اختر "Firebase Notification messages"
4. أدخل العنوان والنص
5. اختر التطبيق وأرسل

### من Supabase Edge Function:
```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer your-anon-key' \
  -H 'Content-Type: application/json' \
  -d '{
    "token": "device-fcm-token",
    "title": "تذكير بالقسط",
    "body": "لديك قسط مستحق اليوم"
  }'
```

---

## 📱 الحصول على FCM Token

FCM Token يُحفظ تلقائياً في قاعدة البيانات عند تشغيل التطبيق.

للحصول عليه برمجياً:
```dart
import 'package:debity/services/fcm_service.dart';

String? token = FCMService.fcmToken;
print('FCM Token: $token');
```

---

## ⚠️ ملاحظات مهمة

1. **minSdkVersion**: يجب أن يكون 21 أو أعلى
2. **Internet Permission**: مضاف تلقائياً
3. **Background Messages**: تعمل حتى عند إغلاق التطبيق
4. **iOS**: يتطلب شهادة APNs من Apple Developer Account

---

## 🔧 استكشاف الأخطاء

### الإشعارات لا تظهر؟
1. تأكد من أن `google-services.json` في المكان الصحيح
2. تأكد من منح صلاحية الإشعارات للتطبيق
3. تحقق من Logcat للأخطاء

### Token فارغ؟
1. تأكد من اتصال الإنترنت
2. تأكد من تفعيل Cloud Messaging في Firebase Console

### خطأ في Build؟
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
flutter run
```
