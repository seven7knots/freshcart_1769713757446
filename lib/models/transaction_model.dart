class TransactionModel {
  final String id;
  final String walletId;
  final String type;
  final double amount;
  final String currency;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? paymentGatewayRef;
  final Map<String, dynamic>? paymentGatewayResponse;
  final String? description;
  final String? descriptionAr;
  final String status;
  final Map<String, dynamic> metadata;
  final String? createdBy;
  final DateTime? createdAt;

  const TransactionModel({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.currency = 'USD',
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.paymentGatewayRef,
    this.paymentGatewayResponse,
    this.description,
    this.descriptionAr,
    this.status = 'completed',
    this.metadata = const {},
    this.createdBy,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      balanceBefore: (json['balance_before'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      paymentGatewayRef: json['payment_gateway_ref'] as String?,
      paymentGatewayResponse:
          json['payment_gateway_response'] as Map<String, dynamic>?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      status: json['status'] as String? ?? 'completed',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'payment_gateway_ref': paymentGatewayRef,
      'payment_gateway_response': paymentGatewayResponse,
      'description': description,
      'description_ar': descriptionAr,
      'status': status,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? walletId,
    String? type,
    double? amount,
    String? currency,
    double? balanceBefore,
    double? balanceAfter,
    String? referenceType,
    String? referenceId,
    String? paymentGatewayRef,
    Map<String, dynamic>? paymentGatewayResponse,
    String? description,
    String? descriptionAr,
    String? status,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      paymentGatewayRef: paymentGatewayRef ?? this.paymentGatewayRef,
      paymentGatewayResponse:
          paymentGatewayResponse ?? this.paymentGatewayResponse,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
