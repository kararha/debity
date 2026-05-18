import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'fcm_service.dart';

// Re-export EmptyLocalStorage so main.dart can reference it from one import.
export 'package:supabase_flutter/supabase_flutter.dart' show EmptyLocalStorage;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _functionsBaseUrl = AppConstants.functionsBaseUrl;
  static const _anonKey = AppConstants.supabaseAnonKey;
  static const _secureStorageKey = 'debity_refresh_token';

  String? _accessToken;
  Timer? _refreshTimer;

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null;

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
      };

  Map<String, String> get authHeaders => {
        ..._baseHeaders,
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ── Registration ───────────────────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'user_metadata': {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    };

    final data = await _postJson('create-user', body, context: 'create-user');

    if (data['user'] == null) {
      throw Exception(data['error'] ?? 'فشل إنشاء الحساب');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _postJson(
      'login',
      {'email': email, 'password': password},
      context: 'login',
    );

    final inner = data['data'] as Map<String, dynamic>?;
    final session = inner?['session'] as Map<String, dynamic>?;

    final accessToken = session?['access_token'] as String?;
    final refreshToken = session?['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('استجابة غير صحيحة من الخادم');
    }

    await _applyTokens(accessToken, refreshToken);
    return data;
  }

  // ── Token Refresh ──────────────────────────────────────────────────────────
  Future<void> refreshToken() async {
    final storedRefresh = await _secureStorage.read(key: _secureStorageKey);
    if (storedRefresh == null) {
      throw Exception('لا يوجد refresh token محفوظ');
    }

    final data = await _postJson(
      'refresh-token',
      {'refresh_token': storedRefresh},
      context: 'refresh-token',
    );

    final session = data['session'] as Map<String, dynamic>?;
    final accessToken = session?['access_token'] as String?;
    final refreshToken = session?['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('استجابة تجديد غير صحيحة من الخادم');
    }

    await _applyTokens(accessToken, refreshToken);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _cancelRefreshTimer();
    _accessToken = null;
    await _secureStorage.delete(key: _secureStorageKey);

    try {
      await FCMService.deactivateToken();
    } catch (e) {
      debugPrint('FCM deactivateToken (ignored): $e');
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut (ignored): $e');
    }
  }

  // ── Session Restore ────────────────────────────────────────────────────────
  Future<bool> tryRestoreSession() async {
    try {
      final stored = await _secureStorage.read(key: _secureStorageKey);
      if (stored == null) return false;
      await refreshToken();
      return true;
    } catch (e) {
      debugPrint('Session restore failed: $e');
      _accessToken = null;
      await _secureStorage.delete(key: _secureStorageKey);
      return false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _applyTokens(String accessToken, String refreshToken) async {
    // access_token → memory only
    _accessToken = accessToken;

    // refresh_token → secure storage
    await _secureStorage.write(key: _secureStorageKey, value: refreshToken);

    // ✅ Pass access token (not refresh token) so currentUser is properly set
    try {
      await Supabase.instance.client.auth.setSession(accessToken);
    } catch (e) {
      debugPrint('setSession (ignored): $e');
    }

    // currentUser is now set — FCM token save will work correctly
    try {
      final fcmToken = await FCMService.getToken();
      if (fcmToken != null) {
        await FCMService.saveFcmTokenToSupabase(fcmToken);
      }
    } catch (e) {
      debugPrint('Failed to save FCM token during auth: $e');
    }

    // Schedule proactive refresh ~2 minutes before expiry (default expiry ≈ 1 h)
    _scheduleRefresh(const Duration(minutes: 58));
  }

  void _scheduleRefresh(Duration delay) {
    _cancelRefreshTimer();
    _refreshTimer = Timer(delay, () async {
      try {
        await refreshToken();
      } catch (e) {
        debugPrint('Proactive refresh failed: $e');
      }
    });
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Map<String, dynamic> _parseResponse(http.Response response,
      {required String context}) {
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode >= 400) {
      final message = body['error']?.toString() ??
          body['message']?.toString() ??
          'خطأ ${response.statusCode} في $context';
      throw Exception(message);
    }
    return body;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    required String context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/$path'),
        headers: _baseHeaders,
        body: jsonEncode(body),
      );
      return _parseResponse(response, context: context);
    } on SocketException catch (_) {
      throw Exception('network');
    } on http.ClientException catch (_) {
      throw Exception('network');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}