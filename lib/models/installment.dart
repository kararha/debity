enum InstallmentStatus { pending, paid, partial, overdue }

class Installment {
  final String? id;
  final String debtId;
  final int installmentNumber;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InstallmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Optional: Include debt and customer data when fetching
  final String? itemName;
  final String? customerName;
  final String? customerPhone;

  Installment({
    this.id,
    required this.debtId,
    required this.installmentNumber,
    required this.amount,
    this.paidAmount = 0,
    required this.dueDate,
    this.paidDate,
    this.status = InstallmentStatus.pending,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.itemName,
    this.customerName,
    this.customerPhone,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => amount - paidAmount;
  
  bool get isOverdue => 
      status != InstallmentStatus.paid && 
      dueDate.isBefore(DateTime.now());

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String?,
      debtId: json['debt_id'] as String,
      installmentNumber: json['installment_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.parse(json['due_date'] as String),
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      status: InstallmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InstallmentStatus.pending,
      ),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      itemName: json['debts']?['item_name'] as String?,
      customerName: json['debts']?['customers']?['name'] as String?,
      customerPhone: json['debts']?['customers']?['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'installment_number': installmentNumber,
      'amount': amount,
      'paid_amount': paidAmount,
      'due_date': dueDate.toIso8601String().split('T')[0],
      if (paidDate != null) 'paid_date': paidDate!.toIso8601String().split('T')[0],
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Installment copyWith({
    String? id,
    String? debtId,
    int? installmentNumber,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    DateTime? paidDate,
    InstallmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? customerName,
    String? customerPhone,
  }) {
    return Installment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemName: itemName ?? this.itemName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }

  @override
  String toString() {
    return 'Installment(id: $id, number: $installmentNumber, amount: $amount, status: $status)';
  }
}
