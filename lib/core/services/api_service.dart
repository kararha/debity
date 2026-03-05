import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import '../../models/customer.dart';

/// Core API service — uses the Supabase client for all database operations.
/// The Supabase client's session is hydrated by [AuthService] after every
/// login / token-refresh, so RLS policies (user_id = auth.uid()) work
/// transparently without any manual header injection here.
///
/// All authentication concerns (login, register, token storage, refresh) live
/// exclusively in [AuthService].
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _auth = AuthService();

  // ---------------------------------------------------------------------------
  // Auth helpers — delegate to AuthService
  // ---------------------------------------------------------------------------

  bool get isAuthenticated => _auth.isLoggedIn;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Customer CRUD — direct Supabase client, RLS enforces user_id filter
  // ---------------------------------------------------------------------------

  Future<List<Customer>> getCustomers({int limit = 100, int offset = 0}) async {
    _assertAuthenticated();
    final response = await _supabase
        .from('customers')
        .select()
        .order('name')
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => Customer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Customer?> getCustomer(String id) async {
    _assertAuthenticated();
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response != null ? Customer.fromJson(response) : null;
  }

  Future<Customer> createCustomer(Map<String, dynamic> customerData) async {
    _assertAuthenticated();
    // user_id is set automatically by the BEFORE INSERT trigger
    final response = await _supabase
        .from('customers')
        .insert(customerData)
        .select()
        .single();
    return Customer.fromJson(response);
  }

  Future<Customer> updateCustomer(
    String id,
    Map<String, dynamic> updates,
  ) async {
    _assertAuthenticated();
    final response = await _supabase
        .from('customers')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Customer.fromJson(response);
  }

  Future<void> deleteCustomer(String id) async {
    _assertAuthenticated();
    await _supabase.from('customers').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _assertAuthenticated() {
    if (!isAuthenticated) {
      throw Exception('المستخدم غير مسجّل الدخول');
    }
  }
}

