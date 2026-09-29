class ProductModel {
  final String id;
  final String? barcode;
  final String nameAr;
  final String? nameEn;
  final String companyName;
  final String? countryOfOrigin;
  final String? categoryId;
  final String status; // 'boycott' | 'safe_local' | 'under_review'
  final String? reasonAr;
  final String? reasonEn;
  final String? imageUrl;
  final bool isFeatured;
  final int createdAt;

  const ProductModel({
    required this.id,
    this.barcode,
    required this.nameAr,
    this.nameEn,
    required this.companyName,
    this.countryOfOrigin,
    this.categoryId,
    required this.status,
    this.reasonAr,
    this.reasonEn,
    this.imageUrl,
    this.isFeatured = false,
    required this.createdAt,
  });

  bool get isBoycott => status == 'boycott';
  bool get isSafeLocal => status == 'safe_local';

  String localizedName(bool isAr) {
    if (isAr) return nameAr;
    return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : nameAr;
  }

  String? localizedReason(bool isAr) {
    if (isAr) return reasonAr;
    return (reasonEn != null && reasonEn!.trim().isNotEmpty) ? reasonEn : reasonAr;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      barcode: map['barcode'] as String?,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String?,
      companyName: map['company_name'] as String,
      countryOfOrigin: map['country_of_origin'] as String?,
      categoryId: map['category_id'] as String?,
      status: map['status'] as String,
      reasonAr: map['reason_ar'] as String?,
      reasonEn: map['reason_en'] as String?,
      imageUrl: map['image_url'] as String?,
      isFeatured: (map['is_featured'] as num?)?.toInt() == 1,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name_ar': nameAr,
      'name_en': nameEn,
      'company_name': companyName,
      'country_of_origin': countryOfOrigin,
      'category_id': categoryId,
      'status': status,
      'reason_ar': reasonAr,
      'reason_en': reasonEn,
      'image_url': imageUrl,
      'is_featured': isFeatured ? 1 : 0,
      'created_at': createdAt,
    };
  }
}
