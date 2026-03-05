import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Always dark status bar icons (dark mode app)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF131420),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: const EmptyLocalStorage(),
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM
  await FCMService.initialize();

  runApp(const DebityApp());
}

/// A [ValueNotifier] that drives LTR/RTL and font choice.
class AppLocale extends ChangeNotifier {
  static final AppLocale instance = AppLocale._();
  AppLocale._();

  Locale _locale = const Locale('ar', 'IQ');
  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';

  void toggle() {
    _locale = isRtl ? const Locale('en') : const Locale('ar', 'IQ');
    notifyListeners();
  }

  void setLocale(Locale l) {
    _locale = l;
    notifyListeners();
  }
}

class DebityApp extends StatelessWidget {
  const DebityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final locale = AppLocale.instance.locale;
        final isRtl = AppLocale.instance.isRtl;

        return MaterialApp(
          title: 'ديبتي',
          debugShowCheckedModeBanner: false,

          // Always dark mode
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,

          // Localizations
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: locale,
          supportedLocales: const [
            Locale('ar', 'IQ'),
            Locale('ar'),
            Locale('en'),
          ], 

          // RTL / LTR based on locale
          builder: (context, child) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}


