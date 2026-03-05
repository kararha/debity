enum DebtStatus { active, completed, cancelled }

class Debt {
  final String? id;
  final String customerId;
  final String itemName;
  final String? itemDescription;
  final double originalPrice;
  final double sellingPrice;
  final double downPayment;
  final double totalAmount;
  final double remainingAmount;
  final int numberOfInstallments;
  final double installmentAmount;
  final DateTime startDate;
  final DebtStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Optional: Include customer data when fetching
  final String? customerName;
  final String? customerPhone;

  Debt({
    this.id,
    required this.customerId,
    required this.itemName,
    this.itemDescription,
    required this.originalPrice,
    required this.sellingPrice,
    required this.downPayment,
    double? totalAmount,
    double? remainingAmount,
    required this.numberOfInstallments,
    double? installmentAmount,
    required this.startDate,
    this.status = DebtStatus.active,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.customerName,
    this.customerPhone,
  })  : totalAmount = totalAmount ?? (sellingPrice - downPayment),
        remainingAmount = remainingAmount ?? (sellingPrice - downPayment),
        installmentAmount = installmentAmount ?? 
            ((sellingPrice - downPayment) / numberOfInstallments),
        createdAt = createdAt ?? DateTime.now();

  double get profit => sellingPrice - originalPrice;
  double get paidAmount => totalAmount - remainingAmount;
  double get progressPercentage => 
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      itemName: json['item_name'] as String,
      itemDescription: json['item_description'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      downPayment: (json['down_payment'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble(),
      numberOfInstallments: json['number_of_installments'] as int,
      installmentAmount: (json['installment_amount'] as num?)?.toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      status: DebtStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DebtStatus.active,
      ),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      customerName: json['customers']?['name'] as String?,
      customerPhone: json['customers']?['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'item_name': itemName,
      'item_description': itemDescription,
      'original_price': originalPrice,
      'selling_price': sellingPrice,
      'down_payment': downPayment,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'number_of_installments': numberOfInstallments,
      'installment_amount': installmentAmount,
      'start_date': startDate.toIso8601String().split('T')[0],
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Debt copyWith({
    String? id,
    String? customerId,
    String? itemName,
    String? itemDescription,
    double? originalPrice,
    double? sellingPrice,
    double? downPayment,
    double? totalAmount,
    double? remainingAmount,
    int? numberOfInstallments,
    double? installmentAmount,
    DateTime? startDate,
    DebtStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerPhone,
  }) {
    return Debt(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      originalPrice: originalPrice ?? this.originalPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      downPayment: downPayment ?? this.downPayment,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }

  @override
  String toString() {
    return 'Debt(id: $id, itemName: $itemName, totalAmount: $totalAmount, remainingAmount: $remainingAmount)';
  }
}
