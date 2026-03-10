import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/services/auth_service.dart';

/// Supabase Edge Functions API Service
/// Manages all API calls to Supabase backend
class ApiService {
  // Supabase anon key
  static const String _anonKey = AppConstants.supabaseAnonKey;

  // Endpoint names - Authentication
  static const String _createUser = 'create-user';
  static const String _refreshToken = 'refresh-token';
  static const String _logout = 'logout';

  // Endpoint names - Debt Management
  static const String _createDebt = 'create-debt';
  static const String _recordPayment = 'process-payment';

  // Endpoint names - Notifications
  static const String _notifyUpcomingDue = 'notify-upcoming-due';

  static const String _checkOverdue = 'check-overdue';
  static const String _dailyReminder = 'daily-reminder';
  static const String _pendingNotifications = 'pending-notifications';
  static const String _statistics = 'statistics';

  // Supabase client — used for functions.invoke() which auto-attaches JWT
  final _supabase = Supabase.instance.client;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client
  // (kept for potential future use; not used for edge-function calls)
  // final http.Client _client = http.Client();

  // Get tokens — prefer AuthService's in-memory access_token, fall back to SDK session.
  String? get _accessToken =>
      AuthService().accessToken ??
      Supabase.instance.client.auth.currentSession?.accessToken;
  String? get _refreshTokenValue =>
      Supabase.instance.client.auth.currentSession?.refreshToken;

  // Default headers (used by authHeaders builder)
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'apikey': _anonKey,
  };

  // Headers with authorization (for authenticated endpoints)
  Map<String, String> get authHeaders => {
    ..._baseHeaders,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Set tokens - No-op as we use Supabase singleton
  void setTokens({required String accessToken, required String refreshToken}) {
    // Tokens are managed by Supabase.instance
  }

  /// Clear tokens - No-op as we use Supabase singleton
  void clearTokens() {
    // Tokens are managed by Supabase.instance
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current refresh token
  String? get refreshToken => _refreshTokenValue;

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Generic POST request handler — routes through supabase.functions.invoke()
  /// so the user's JWT is always attached automatically.
  Future<ApiResponse> _post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      debugPrint('functions.invoke POST $endpoint');
      final result = await _supabase.functions.invoke(
        endpoint,
        body: body,
        method: HttpMethod.post,
      );
      final data = result.data is Map ? result.data as Map<String, dynamic> : {};
      return ApiResponse.success(data);
    } on FunctionException catch (e) {
      debugPrint('FunctionException [$endpoint]: ${e.status} ${e.details}');
      final details = e.details;
      final message = (details is Map ? details['error'] : details?.toString()) ??
          'Error ${e.status}';
      return ApiResponse.error(message.toString(), statusCode: e.status);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } catch (e) {
      debugPrint('API Error [$endpoint]: $e');
      return ApiResponse.error(e.toString());
    }
  }

  /// Generic GET request handler — routes through supabase.functions.invoke()
  Future<ApiResponse> _get(
    String endpoint,
  ) async {
    try {
      debugPrint('functions.invoke GET $endpoint');
      final result = await _supabase.functions.invoke(
        endpoint,
        method: HttpMethod.get,
      );
      final data = result.data is Map ? result.data as Map<String, dynamic> : {};
      return ApiResponse.success(data);
    } on FunctionException catch (e) {
      debugPrint('FunctionException [$endpoint]: ${e.status} ${e.details}');
      final details = e.details;
      final message = (details is Map ? details['error'] : details?.toString()) ??
          'Error ${e.status}';
      return ApiResponse.error(message.toString(), statusCode: e.status);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } catch (e) {
      debugPrint('API Error [$endpoint]: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // ============================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================

  /// Create a new user account
  /// Endpoint: POST /create-user
  /// Returns user data and tokens on success
  Future<AuthResponse> createUser({
    required String email,
    required String password,
    String? phone,
    Map<String, dynamic>? userMetadata,
  }) async {
    final metadata = userMetadata ?? {};
    if (phone != null) {
      metadata['phone'] = phone;
    }

    final response = await _post(
      _createUser,
      body: {
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        'user_metadata': metadata,
      },
    );

    if (response.isSuccess) {
      final authResponse = AuthResponse.fromJson(response.data);
      if (authResponse.accessToken != null &&
          authResponse.refreshToken != null) {
        setTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken!,
        );
      }
      return authResponse;
    }
    throw ApiException(response.error ?? 'Failed to create user');
  }

  /// Refresh authentication tokens
  /// Endpoint: POST /refresh-token
  /// Returns new session data on success
  Future<RefreshTokenResponse> refreshAuthToken({
    String? refreshTokenParam,
  }) async {
    final tokenToUse = refreshTokenParam ?? _refreshTokenValue;

    if (tokenToUse == null) {
      throw ApiException('No refresh token available');
    }

    final response = await _post(
      _refreshToken,
      body: {'refresh_token': tokenToUse},
    );

    if (response.isSuccess) {
      final refreshResponse = RefreshTokenResponse.fromJson(response.data);
      if (refreshResponse.session != null) {
        setTokens(
          accessToken: refreshResponse.session!.accessToken,
          refreshToken: refreshResponse.session!.refreshToken,
        );
      }
      return refreshResponse;
    }
    throw ApiException(response.error ?? 'Failed to refresh token');
  }

  /// Logout user — delegates to AuthService which clears memory + secure storage.
  Future<LogoutResponse> logout() async {
    try {
      await AuthService().logout();
    } catch (e) {
      debugPrint('Logout error (ignored): $e');
    }
    return LogoutResponse(success: true);
  }

  // ============================================================
  // DEBT MANAGEMENT ENDPOINTS
  // ============================================================

  /// Create a new debt with auto-generated installments
  /// Endpoint: POST /create-debt
  ///
  /// The backend will:
  /// 1. Calculate financials (total_amount, installment_amount)
  /// 2. Create debt record with status 'active'
  /// 3. Generate installment records for each month
  ///
  /// Returns the created debt ID on success
  Future<CreateDebtResponse> createDebt({
    required String customerId,
    required String itemName,
    String? itemDescription,
    required double originalPrice,
    required double sellingPrice,
    required double downPayment,
    required int numberOfInstallments,
    required DateTime startDate,
  }) async {
    final response = await _post(
      _createDebt,
      body: {
        'customer_id': customerId,
        'item_name': itemName,
        if (itemDescription != null) 'item_description': itemDescription,
        'original_price': originalPrice,
        'selling_price': sellingPrice,
        'down_payment': downPayment,
        'number_of_installments': numberOfInstallments,
        'start_date': startDate.toIso8601String().split('T')[0],
      },
    );

    if (response.isSuccess) {
      return CreateDebtResponse.fromJson(response.data);
    }
    throw ApiException(response.error ?? 'Failed to create debt');
  }

  /// Record a payment for an installment
  /// Endpoint: POST /record-payment
  ///
  /// The backend will:
  /// 1. Insert payment record
  /// 2. Update installment status (pending -> partial -> paid)
  /// 3. Update parent debt remaining_amount and status
  ///
  /// Returns new installment status on success
  Future<RecordPaymentResponse> recordPayment({
    required String installmentId,
    required double amount,
    required DateTime paymentDate,
    String? paymentMethod,
    String? notes,
  }) async {
    final response = await _post(
      _recordPayment,
      body: {
        'installment_id': installmentId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T')[0],
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (notes != null) 'notes': notes,
      },
    );

    if (response.isSuccess) {
      return RecordPaymentResponse.fromJson(response.data);
    }
    throw ApiException(response.error ?? 'Failed to record payment');
  }

  // ============================================================
  // NOTIFICATION ENDPOINTS
  // ============================================================

  /// Trigger notification check for upcoming due payments
  /// Endpoint: POST /notify-upcoming-due
  ///
  /// [daysBefore] controls how many days ahead to look for due installments.
  /// Matches the "التذكير قبل" setting in SettingsScreen.
  ///
  /// The backend will:
  /// 1. Query installments due within [daysBefore] days that are not paid
  /// 2. Get admin FCM tokens
  /// 3. Send push notifications via FCM
  /// 4. Log notifications in notification_logs table
  ///
  /// Returns count of processed notifications
  Future<NotifyUpcomingDueResponse> notifyUpcomingDue({int daysBefore = 1}) async {
    final response = await _post(
      _notifyUpcomingDue,
      body: {'days_before': daysBefore},
    );

    if (response.isSuccess) {
      return NotifyUpcomingDueResponse.fromJson(response.data);
    }
    throw ApiException(response.error ?? 'Failed to process notifications');
  }

  // ============================================================
  // STATISTICS ENDPOINTS
  // ============================================================

  /// Get dashboard statistics
  Future<StatisticsResponse> getStatistics() async {
    debugPrint('=== getStatistics ===');
    // functions.invoke() automatically uses the current user JWT.
    final response = await _get(_statistics);

    if (response.isSuccess) {
      return StatisticsResponse.fromJson(response.data);
    }
    throw ApiException(response.error ?? 'Failed to get statistics');
  }

  // ============================================================
  // OVERDUE & REMINDER ENDPOINTS
  // ============================================================

  /// Check and update overdue installments
  Future<OverdueResponse> checkOverdueInstallments() async {
    final response = await _post(_checkOverdue);

    if (response.isSuccess) {
      return OverdueResponse.fromJson(response.data);
    }
    throw ApiException(response.error ?? 'Failed to check overdue installments');
  }

  /// Run daily reminder check
  /// Gets installments due tomorrow, today, and overdue
  /// Creates notifications and optionally sends FCM push
  Future<ReminderResponse> runDailyReminderCheck() async {
    final response = await _post(_dailyReminder);

    if (response.isSuccess) {
      return ReminderResponse.fromJson(response.data);
    }
    throw ApiException(response.error ?? 'Failed to run reminder check');
  }

  /// Get all pending (unsent) notifications
  /// Marks them as sent after retrieval
  Future<NotificationsResponse> getPendingNotifications() async {
    debugPrint('[ApiService] getPendingNotifications() — invoking $_pendingNotifications');
    final response = await _post(_pendingNotifications);
    debugPrint('[ApiService] getPendingNotifications() — isSuccess=${response.isSuccess} error=${response.error} statusCode=${response.statusCode}');
    debugPrint('[ApiService] getPendingNotifications() — raw data keys: ${response.data is Map ? (response.data as Map).keys.toList() : response.data.runtimeType}');

    if (response.isSuccess) {
      try {
        final parsed = NotificationsResponse.fromJson(response.data);
        debugPrint('[ApiService] getPendingNotifications() — parsed ${parsed.notifications.length} notifications');
        return parsed;
      } catch (e, stack) {
        debugPrint('[ApiService] getPendingNotifications() — PARSE ERROR: $e');
        debugPrint('[ApiService] getPendingNotifications() — PARSE STACK: $stack');
        rethrow;
      }
    }
    throw ApiException(response.error ?? 'Failed to get notifications');
  }

  /// Health check for create-user endpoint
  Future<bool> checkCreateUserHealth() async {
    final response = await _get(_createUser);
    return response.isSuccess && response.data['ok'] == true;
  }

  /// Health check for logout endpoint
  Future<bool> checkLogoutHealth() async {
    final response = await _get(_logout);
    return response.isSuccess && response.data['ok'] == true;
  }

  /// Dispose resources
  void dispose() {
    // Nothing to close — using supabase.functions.invoke()
  }
}

// ============================================================
// RESPONSE MODELS
// ============================================================

/// Generic API Response wrapper
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) =>
      ApiResponse._(isSuccess: true, data: data);

  factory ApiResponse.error(String error, {int? statusCode}) =>
      ApiResponse._(isSuccess: false, error: error, statusCode: statusCode);
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ============================================================
// AUTHENTICATION RESPONSE MODELS
// ============================================================

/// User model from auth response
class AuthUser {
  final String id;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? userMetadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthUser({
    required this.id,
    this.email,
    this.phone,
    this.userMetadata,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? '',
      email: json['email'],
      phone: json['phone'],
      userMetadata: json['user_metadata'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (userMetadata != null) 'user_metadata': userMetadata,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

/// Auth response from create-user endpoint
class AuthResponse {
  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  AuthResponse({this.user, this.accessToken, this.refreshToken, this.error});

  bool get isSuccess => user != null && accessToken != null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      error: json['error'],
    );
  }
}

/// Session model for refresh token response
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final int? expiresAt;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
    this.expiresIn,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      expiresAt: json['expires_at'],
    );
  }

  /// Check if token is expired (with 5 minute buffer)
  bool get isExpired {
    if (expiresAt == null) return false;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt! * 1000);
    return DateTime.now().isAfter(
      expiryTime.subtract(const Duration(minutes: 5)),
    );
  }
}

/// Refresh token response
class RefreshTokenResponse {
  final AuthSession? session;
  final AuthUser? user;
  final String? error;

  RefreshTokenResponse({this.session, this.user, this.error});

  bool get isSuccess => session != null;

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      session: json['session'] != null
          ? AuthSession.fromJson(json['session'])
          : null,
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
      error: json['error'],
    );
  }
}

/// Logout response
class LogoutResponse {
  final bool success;
  final String? error;

  LogoutResponse({required this.success, this.error});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json['success'] ?? false,
      error: json['error'],
    );
  }
}

// ============================================================
// DEBT MANAGEMENT RESPONSE MODELS
// ============================================================

/// Create debt response
class CreateDebtResponse {
  final bool success;
  final String? debtId;
  final String? error;

  CreateDebtResponse({required this.success, this.debtId, this.error});

  factory CreateDebtResponse.fromJson(Map<String, dynamic> json) {
    return CreateDebtResponse(
      success: json['success'] ?? false,
      debtId: json['debt_id'],
      error: json['error'],
    );
  }
}

/// Record payment response
class RecordPaymentResponse {
  final bool success;
  final String? newStatus;
  final String? error;

  RecordPaymentResponse({required this.success, this.newStatus, this.error});

  /// Check if installment is now fully paid
  bool get isPaid => newStatus == 'paid';

  /// Check if installment is partially paid
  bool get isPartial => newStatus == 'partial';

  factory RecordPaymentResponse.fromJson(Map<String, dynamic> json) {
    return RecordPaymentResponse(
      success: json['success'] ?? false,
      newStatus: json['new_status'],
      error: json['error'],
    );
  }
}

// ============================================================
// NOTIFICATION RESPONSE MODELS
// ============================================================

/// Notify upcoming due response
class NotifyUpcomingDueResponse {
  final int processed;
  final String? error;

  NotifyUpcomingDueResponse({required this.processed, this.error});

  bool get isSuccess => error == null;

  factory NotifyUpcomingDueResponse.fromJson(Map<String, dynamic> json) {
    return NotifyUpcomingDueResponse(
      processed: json['processed'] ?? 0,
      error: json['error'],
    );
  }
}

// ============================================================
// STATISTICS RESPONSE MODELS
// ============================================================

/// Statistics Response
class StatisticsResponse {
  final bool success;
  final Statistics statistics;

  StatisticsResponse({
    required this.success,
    required this.statistics,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    return StatisticsResponse(
      success: true, // API returns raw data on success
      statistics: Statistics.fromJson(json),
    );
  }
}

/// Statistics Model
class Statistics {
  // Overall
  final double totalDebts;
  final double totalPaid;
  final double totalRemaining;
  final int activeDebts;
  final int completedDebts;
  final int customersCount;

  // Overdue
  final int overdueCount;
  final double overdueAmount;

  // Monthly
  final double monthlyTotal;
  final double monthlyPaid;
  final double monthlyRemaining;

  // Upcoming
  final int upcomingCount;
  final List<UpcomingInstallment> upcomingInstallments;

  // Top Customers (New)
  final List<TopCustomer> topCustomers;
  
  // Trends (New)
  final Trends trends;
  final int totalPendingNotifications;
  final double avgInstallmentAmount;
  final double avgRemainingPerDebt;

  Statistics({
    required this.totalDebts,
    required this.totalPaid,
    required this.totalRemaining,
    required this.activeDebts,
    required this.completedDebts,
    required this.customersCount,
    required this.overdueCount,
    required this.overdueAmount,
    required this.monthlyTotal,
    required this.monthlyPaid,
    required this.monthlyRemaining,
    required this.upcomingCount,
    required this.upcomingInstallments,
    required this.topCustomers,
    required this.trends,
    required this.totalPendingNotifications,
    required this.avgInstallmentAmount,
    required this.avgRemainingPerDebt,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    final debtsByStatus = json['debts_by_status'] ?? {};
    final activeCount = (debtsByStatus['active'] ?? 0) as int;
    final completedCount = (debtsByStatus['paid'] ?? 0) as int;

    // Estimate Total Debt Value = Remaining + Paid
    final remaining = (json['total_remaining'] ?? 0).toDouble();
    final paid = (json['payments_sum'] ?? 0).toDouble();

    return Statistics(
      totalDebts: remaining + paid,
      totalPaid: paid,
      totalRemaining: remaining,
      activeDebts: activeCount,
      completedDebts: completedCount,
      customersCount: json['total_customers'] ?? 0,
      
      overdueCount: json['overdue_installments'] ?? 0,
      overdueAmount: 0.0, 
      
      monthlyTotal: 0.0, 
      monthlyPaid: 0.0, 
      monthlyRemaining: 0.0, 
      
      upcomingCount: 0, 
      upcomingInstallments: [], 
      
      topCustomers: (json['top_customers'] as List? ?? [])
          .map((e) => TopCustomer.fromJson(e))
          .toList(),
          
      trends: Trends.fromJson(json['trends'] ?? {}),
      totalPendingNotifications: json['total_pending_notifications'] ?? 0,
      avgInstallmentAmount: (json['avg_installment_amount'] ?? 0).toDouble(),
      avgRemainingPerDebt: (json['avg_remaining_per_debt'] ?? 0).toDouble(),
    );
  }
}

/// Trends Model
class Trends {
  final List<dynamic> customersPerDay;
  final List<dynamic> paymentsPerDay;

  Trends({required this.customersPerDay, required this.paymentsPerDay});

  factory Trends.fromJson(Map<String, dynamic> json) {
    return Trends(
      customersPerDay: json['customers_per_day'] ?? [],
      paymentsPerDay: json['payments_per_day'] ?? [],
    );
  }
}

/// Top Customer Model
class TopCustomer {
  final String customerId;
  final double remainingAmount;

  TopCustomer({required this.customerId, required this.remainingAmount});

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      customerId: json['customer_id'] ?? '',
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Upcoming Installment
class UpcomingInstallment {
  final String id;
  final double amount;
  final String dueDate;
  final String? itemName;
  final String? customerName;
  final String? customerPhone;

  UpcomingInstallment({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.itemName,
    this.customerName,
    this.customerPhone,
  });

  factory UpcomingInstallment.fromJson(Map<String, dynamic> json) {
    final debts = json['debts'] as Map<String, dynamic>?;
    final customers = debts?['customers'] as Map<String, dynamic>?;

    return UpcomingInstallment(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: json['due_date'] ?? '',
      itemName: debts?['item_name'],
      customerName: customers?['name'],
      customerPhone: customers?['phone'],
    );
  }
}

// ============================================================
// OVERDUE & REMINDER RESPONSE MODELS
// ============================================================

/// Overdue Installments Response
class OverdueResponse {
  final bool success;
  final int newlyOverdue;
  final int totalOverdue;
  final List<OverdueInstallment> updatedInstallments;

  OverdueResponse({
    required this.success,
    required this.newlyOverdue,
    required this.totalOverdue,
    required this.updatedInstallments,
  });

  factory OverdueResponse.fromJson(Map<String, dynamic> json) {
    return OverdueResponse(
      success: json['success'] ?? false,
      newlyOverdue: json['newly_overdue'] ?? 0,
      totalOverdue: json['total_overdue'] ?? 0,
      updatedInstallments: (json['updated_installments'] as List? ?? [])
          .map((e) => OverdueInstallment.fromJson(e))
          .toList(),
    );
  }
}

/// Overdue Installment details
class OverdueInstallment {
  final String id;
  final int installmentNumber;
  final double amount;
  final String dueDate;
  final String debtId;
  final String? itemName;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;

  OverdueInstallment({
    required this.id,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.debtId,
    this.itemName,
    this.customerId,
    this.customerName,
    this.customerPhone,
  });

  factory OverdueInstallment.fromJson(Map<String, dynamic> json) {
    final debts = json['debts'] as Map<String, dynamic>?;
    final customers = debts?['customers'] as Map<String, dynamic>?;

    return OverdueInstallment(
      id: json['id'] ?? '',
      installmentNumber: json['installment_number'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: json['due_date'] ?? '',
      debtId: json['debt_id'] ?? '',
      itemName: debts?['item_name'],
      customerId: debts?['customer_id'],
      customerName: customers?['name'],
      customerPhone: customers?['phone'],
    );
  }
}

/// Daily Reminder Response
class ReminderResponse {
  final bool success;
  final ReminderSummary summary;
  final List<ReminderNotification> notifications;

  ReminderResponse({
    required this.success,
    required this.summary,
    required this.notifications,
  });

  factory ReminderResponse.fromJson(Map<String, dynamic> json) {
    return ReminderResponse(
      success: json['success'] ?? false,
      summary: ReminderSummary.fromJson(json['summary'] ?? {}),
      notifications: (json['notifications'] as List? ?? [])
          .map((e) => ReminderNotification.fromJson(e))
          .toList(),
    );
  }
}

/// Reminder Summary
class ReminderSummary {
  final int tomorrow;
  final int today;
  final int overdue;
  final int totalNotifications;

  ReminderSummary({
    required this.tomorrow,
    required this.today,
    required this.overdue,
    required this.totalNotifications,
  });

  factory ReminderSummary.fromJson(Map<String, dynamic> json) {
    return ReminderSummary(
      tomorrow: json['tomorrow'] ?? 0,
      today: json['today'] ?? 0,
      overdue: json['overdue'] ?? 0,
      totalNotifications: json['total_notifications'] ?? 0,
    );
  }
}

/// Reminder Notification
class ReminderNotification {
  final String installmentId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double amount;
  final String dueDate;
  final String? itemName;
  final String type;
  final String title;
  final String body;

  ReminderNotification({
    required this.installmentId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.amount,
    required this.dueDate,
    this.itemName,
    required this.type,
    required this.title,
    required this.body,
  });

  factory ReminderNotification.fromJson(Map<String, dynamic> json) {
    return ReminderNotification(
      installmentId: json['installment_id'] ?? '',
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: json['due_date'] ?? '',
      itemName: json['item_name'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
    );
  }
}

/// Pending Notifications Response
class NotificationsResponse {
  final bool success;
  final int count;
  final List<PendingNotification> notifications;

  NotificationsResponse({
    required this.success,
    required this.count,
    required this.notifications,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      notifications: (json['notifications'] as List? ?? [])
          .map((e) => PendingNotification.fromJson(e))
          .toList(),
    );
  }
}

/// Pending Notification
class PendingNotification {
  final String id;
  final String installmentId;
  final String? customerId;
  final String type;
  final String title;
  final String body;
  final String? data;
  final DateTime createdAt;
  final bool sent;
  final DateTime? sentAt;

  PendingNotification({
    required this.id,
    required this.installmentId,
    this.customerId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    required this.sent,
    this.sentAt,
  });

  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'] ?? '',
      installmentId: json['installment_id'] ?? '',
      customerId: json['customer_id'],
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] != null ? jsonEncode(json['data']) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      sent: json['sent'] == true,
      sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at'].toString()) : null,
    );
  }
}
