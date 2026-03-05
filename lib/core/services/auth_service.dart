import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

// Re-export EmptyLocalStorage so main.dart can reference it from one import.
export 'package:supabase_flutter/supabase_flutter.dart' show EmptyLocalStorage;

// ---------------------------------------------------------------------------
// AuthService
//
// Responsibilities:
//   • Registration  → POST /functions/v1/create-user  (no JWT, no auto-login)
//   • Login         → POST /functions/v1/login
//   • Token refresh → POST /functions/v1/refresh-token
//   • Logout        → clear memory + secure storage
//   • Session restore on cold start (reads refresh_token from secure storage)
//
// Token storage policy (enforced here):
//   • access_token  → in-memory only (_accessToken static field)
//   • refresh_token → flutter_secure_storage (encrypted on-device)
// ---------------------------------------------------------------------------
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _functionsBaseUrl = AppConstants.functionsBaseUrl;
  static const _anonKey = AppConstants.supabaseAnonKey;
  static const _secureStorageKey = 'debity_refresh_token';

  // ── State ─────────────────────────────────────────────────────────────────
  String? _accessToken;
  Timer? _refreshTimer;

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Public getters ─────────────────────────────────────────────────────────
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null;

  // ── Default HTTP headers (no auth) ─────────────────────────────────────────
  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
      };

  // ── Authenticated headers ──────────────────────────────────────────────────
  Map<String, String> get authHeaders => {
        ..._baseHeaders,
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ---------------------------------------------------------------------------
  // Registration — calls create-user edge function
  // Spec: returns { user } — NO tokens. Do NOT log the user in.
  // ---------------------------------------------------------------------------
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

    final response = await http.post(
      Uri.parse('$_functionsBaseUrl/create-user'),
      headers: _baseHeaders,
      body: jsonEncode(body),
    );

    final data = _parseResponse(response, context: 'create-user');

    // Server returns { user } — no tokens, user must verify email first.
    if (data['user'] == null) {
      throw Exception(data['error'] ?? 'فشل إنشاء الحساب');
    }
  }

  // ---------------------------------------------------------------------------
  // Login — calls login edge function
  // Spec: returns { access_token, refresh_token, user }
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_functionsBaseUrl/login'),
      headers: _baseHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _parseResponse(response, context: 'login');

    // Edge function wraps result as { data: { user, session: { access_token, refresh_token } } }
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

  // ---------------------------------------------------------------------------
  // Token Refresh — calls refresh-token edge function
  // Reads the stored refresh_token, exchanges it, stores the new pair.
  // ---------------------------------------------------------------------------
  Future<void> refreshToken() async {
    final storedRefresh =
        await _secureStorage.read(key: _secureStorageKey);
    if (storedRefresh == null) {
      throw Exception('لا يوجد refresh token محفوظ');
    }

    final response = await http.post(
      Uri.parse('$_functionsBaseUrl/refresh-token'),
      headers: _baseHeaders,
      body: jsonEncode({'refresh_token': storedRefresh}),
    );

    final data = _parseResponse(response, context: 'refresh-token');

    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('استجابة تجديد غير صحيحة من الخادم');
    }

    await _applyTokens(accessToken, refreshToken);
  }

  // ---------------------------------------------------------------------------
  // Logout — clear memory + secure storage + Supabase in-memory session
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    _cancelRefreshTimer();
    _accessToken = null;
    await _secureStorage.delete(key: _secureStorageKey);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut (ignored): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Session Restore — called on cold start
  // Reads refresh_token → calls refresh edge function → re-hydrates session
  // Returns true if session was restored successfully.
  // ---------------------------------------------------------------------------
  Future<bool> tryRestoreSession() async {
    try {
      final stored = await _secureStorage.read(key: _secureStorageKey);
      if (stored == null) return false;
      await refreshToken();
      return true;
    } catch (e) {
      debugPrint('Session restore failed: $e');
      // Clear stale tokens
      _accessToken = null;
      await _secureStorage.delete(key: _secureStorageKey);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Store tokens, inject into Supabase client, schedule proactive refresh.
  Future<void> _applyTokens(
      String accessToken, String refreshToken) async {
    // access_token → memory only
    _accessToken = accessToken;

    // refresh_token → secure storage
    await _secureStorage.write(key: _secureStorageKey, value: refreshToken);

    // Inject into Supabase SDK so .from() calls work transparently.
    try {
      await Supabase.instance.client.auth.setSession(refreshToken);
    } catch (e) {
      debugPrint('setSession (ignored): $e');
    }

    // Schedule proactive refresh ~2 minutes before expiry (default expiry ≈ 1 h).
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

  /// Parse HTTP response; throw on non-2xx.
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
}
