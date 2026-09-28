class PendingSubmissionModel {
  final String id;
  final String barcode;
  final String productName;
  final String? brandName;
  final String suggestedStatus; // 'boycott' | 'safe_local'
  final String? suggestedAlternative;
  final String? notes;
  final String status; // 'pending' | 'synced'
  final int createdAt;

  const PendingSubmissionModel({
    required this.id,
    required this.barcode,
    required this.productName,
    this.brandName,
    required this.suggestedStatus,
    this.suggestedAlternative,
    this.notes,
    this.status = 'pending',
    required this.createdAt,
  });

  factory PendingSubmissionModel.fromMap(Map<String, dynamic> map) {
    return PendingSubmissionModel(
      id: map['id'] as String,
      barcode: map['barcode'] as String,
      productName: map['product_name'] as String,
      brandName: map['brand_name'] as String?,
      suggestedStatus: map['suggested_status'] as String,
      suggestedAlternative: map['suggested_alternative'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'product_name': productName,
      'brand_name': brandName,
      'suggested_status': suggestedStatus,
      'suggested_alternative': suggestedAlternative,
      'notes': notes,
      'status': status,
      'created_at': createdAt,
    };
  }
}
