import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/customer.dart';
import 'customer_details_screen.dart';
import '../../core/services/api_service.dart';
import 'add_customer_screen.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/debity_input.dart';
import '../../core/widgets/skeleton_widget.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _filterCustomers();
    });
  }

  Future<void> _loadCustomers() async {
    if (mounted) setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Calling ApiService.getCustomers()...');
      final customers = await ApiService().getCustomers();
      debugPrint(
        'ApiService.getCustomers() returned ${customers.length} items',
      );
      if (customers.isNotEmpty) {
        debugPrint('First customer: ${customers.first.toJson()}');
      }

      if (!mounted) return;
      setState(() {
        _customers = customers; // The API returns List<Customer> directly
        _filteredCustomers = _customers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              customer.phone.contains(query) ||
              (customer.address?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.primaryColor, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).customersTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context).customersCount.replaceAll('{count}', '${_filteredCustomers.length}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 14),
                // Search bar
                DebityTextField(
                  controller: _searchController,
                  hintText: AppLocalizations.of(context).customersSearchHint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? _buildSkeletonList()
                : _error != null
                ? _buildErrorView()
                : _filteredCustomers.isEmpty
                ? _buildEmptyView()
                : _buildCustomerList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: AppLocalizations.of(context).addCustomer,
            button: true,
            child: Tooltip(
              message: AppLocalizations.of(context).addCustomer,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand500, AppColors.brand400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand500.withValues(alpha: 0.28),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                    );
                    if (result == true) _loadCustomers();
                  },
                  icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).addCustomer,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).loadFailed,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadCustomers,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).retry),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final isEmpty = _searchController.text.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.brand500.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmpty
                    ? Icons.people_outline_rounded
                    : Icons.search_off_rounded,
                size: 56,
                color: AppColors.brand500.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEmpty ? AppLocalizations.of(context).noCustomersYet : AppLocalizations.of(context).noResults,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isEmpty
                  ? AppLocalizations.of(context).addFirstCustomerNote
                  : AppLocalizations.of(context).tryDifferentSearch,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
                  );
                  if (result == true) _loadCustomers();
                },
                icon: const Icon(Icons.person_add_rounded),
                label: Text(AppLocalizations.of(context).addCustomer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear_rounded, color: AppColors.brand400),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ar' ? 'مسح البحث' : 'Clear Search',
                  style: const TextStyle(color: AppColors.brand400),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SkeletonBox(width: 52, height: 52, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 140, height: 16, radius: 4),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 100, height: 12, radius: 4),
                    const SizedBox(height: 6),
                    const SkeletonBox(width: 120, height: 12, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorPalette = [
      AppColors.primaryColor,
      AppColors.secondaryColor,
      AppColors.accentColor,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    final avatarColor =
        colorPalette[customer.name.codeUnitAt(0) % colorPalette.length];
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customer: customer),
            ),
          );
          if (result == true) _loadCustomers();
        },
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0] : '?',
                  style: TextStyle(
                    color: avatarColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark
                          ? Colors.white
                          : AppColors.of(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (customer.address != null &&
                      customer.address!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isRTL ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: isDark
                  ? const Color(0xFF4B5563)
                  : AppColors.borderColor,
            ),
          ],
        ),
      ),
    );
  }
}
