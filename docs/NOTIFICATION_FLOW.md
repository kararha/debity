# 🔔 دورة حياة الإشعارات في تطبيق ديبتي (Debity)

يشرح هذا المستند كيف تعمل الإشعارات (Push Notifications) في التطبيق، وكيف تتواصل المكونات الثلاثة الرئيسية: **تطبيق الهاتف (Flutter)**، **قاعدة البيانات (Supabase)**، و **خدمة الإشعارات (Firebase)**.

---

## 🏗️ المكونات الرئيسية

1. **📱 تطبيق الهاتف (Flutter App)**: واجهة المستخدم، يستقبل الإشعارات ويعرضها.
2. **🗄️ Supabase**: العقل المدبر، يحتوي على قاعدة البيانات، الجداول، الـ Triggers، والـ Edge Functions.
3. **🔥 Firebase Cloud Messaging (FCM)**: ساعي البريد، الخدمة المسؤولة عن توصيل الإشعار الفعلي إلى هاتف المستخدم.

---

## 🔄 المخطط التوضيحي (Mermaid Diagram)

```mermaid
sequenceDiagram
    autonumber
    participant App as 📱 تطبيق الهاتف (Flutter)
    participant DB as 🗄️ Supabase (Database)
    participant Edge as ⚡ Supabase (Edge Function)
    participant FCM as 🔥 Firebase (FCM)

    %% 1. Registration Phase
    rect rgb(240, 248, 255)
        Note over App, DB: 1. مرحلة التسجيل (عند فتح التطبيق)
        App->>FCM: طلب FCM Token للجهاز
        FCM-->>App: إرجاع الـ Token (مثال: abc123xyz)
        App->>DB: حفظ الـ Token في جدول `user_fcm_tokens`
    end

    %% 2. Triggering Phase
    rect rgb(255, 245, 238)
        Note over App, DB: 2. مرحلة الحدث (Trigger)
        alt حدث فوري (إضافة دين / دفع قسط)
            App->>DB: إدخال بيانات في جدول `debts` أو `payments`
            DB->>DB: Database Trigger يكتشف التغيير
            DB->>DB: إضافة صف في جدول `pending_notifications`
        else حدث مجدول (تذكير بقسط)
            DB->>DB: Cron Job يعمل يومياً الساعة 9 صباحاً
            DB->>Edge: استدعاء دالة `daily-reminder-check`
            Edge->>DB: البحث عن الأقساط المستحقة قريباً
            Edge->>DB: إضافة صفوف في جدول `pending_notifications`
        end
    end

    %% 3. Sending Phase
    rect rgb(240, 255, 240)
        Note over DB, FCM: 3. مرحلة الإرسال
        DB->>DB: Trigger يعمل عند إضافة صف في `pending_notifications`
        DB->>Edge: استدعاء دالة `send-push-notification` مع بيانات الإشعار
        Edge->>DB: جلب الـ Tokens النشطة من `user_fcm_tokens`
        Edge->>FCM: إرسال طلب (POST) يحتوي على الـ Tokens + النص + العنوان
    end

    %% 4. Delivery Phase
    rect rgb(255, 240, 245)
        Note over FCM, App: 4. مرحلة التوصيل
        FCM->>App: إرسال الإشعار (Push Notification) إلى الهاتف
        alt التطبيق في الخلفية (Background)
            App->>App: نظام التشغيل يعرض الإشعار في الأعلى
        else التطبيق مفتوح (Foreground)
            App->>App: Flutter Local Notifications يعرض الإشعار داخل التطبيق
        end
    end
```

---

## 📝 شرح الخطوات بالتفصيل

### 1. مرحلة التسجيل (Registration)
عندما يقوم المستخدم بفتح التطبيق وتسجيل الدخول:
- يطلب التطبيق من Firebase إعطاءه "رقم تعريف فريد" لهذا الهاتف يُسمى **FCM Token**.
- يقوم التطبيق بإرسال هذا الـ Token إلى Supabase ليتم حفظه في جدول `user_fcm_tokens`.
- *الهدف:* لكي يعرف Supabase لاحقاً "أين" يرسل الإشعار.

### 2. مرحلة الحدث (Triggering)
كيف يقرر النظام أن هناك إشعار يجب إرساله؟ هناك طريقتان:
- **أحداث فورية:** عندما يقوم المستخدم بإضافة دين جديد أو تسجيل دفعة، يتم حفظ ذلك في الجداول (`debts` أو `payments`). يوجد "مراقب" (Database Trigger) يلاحظ هذا التغيير ويقوم فوراً بإنشاء "طلب إشعار" في جدول `pending_notifications`.
- **أحداث مجدولة (التذكير بالأقساط):** يوجد منبه (Cron Job) في Supabase يعمل كل يوم الساعة 9 صباحاً. يقوم بتشغيل دالة (`daily-reminder-check`) تبحث في جدول الأقساط (`installments`) وتقارنه بإعدادات المستخدم (`notification_settings`). إذا وجد قسطاً اقترب موعده، يقوم بإنشاء "طلب إشعار" في جدول `pending_notifications`.

### 3. مرحلة الإرسال (Sending)
بمجرد إضافة أي صف جديد في جدول `pending_notifications`:
- يعمل "مراقب" آخر (Trigger) فوراً.
- يقوم هذا المراقب باستدعاء دالة سحابية (Edge Function) اسمها `send-push-notification`.
- تقوم هذه الدالة بجلب الـ FCM Tokens الخاصة بالمستخدم من قاعدة البيانات.
- ثم تتصل بـ Firebase (باستخدام الـ `FCM_SERVICE_ACCOUNT` السري) وتقول له: "أرسل هذا العنوان وهذا النص إلى هذه الهواتف".

### 4. مرحلة التوصيل (Delivery)
- يستلم Firebase الطلب ويقوم بإرسال الإشعار عبر الإنترنت إلى هاتف المستخدم.
- إذا كان التطبيق مغلقاً أو في الخلفية، سيظهر الإشعار في شريط الإشعارات العلوي للهاتف.
- إذا كان التطبيق مفتوحاً أمام المستخدم، سيقوم كود Flutter (تحديداً `FlutterLocalNotifications`) بالتقاط الإشعار وعرضه كرسالة منبثقة داخل التطبيق.