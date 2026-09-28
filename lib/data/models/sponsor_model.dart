class SponsorModel {
  final String id;
  final String brandName;
  final String headlineAr;
  final String descriptionAr;
  final String? promoCode;
  final String? ctaUrl;
  final String? category;

  const SponsorModel({
    required this.id,
    required this.brandName,
    required this.headlineAr,
    required this.descriptionAr,
    this.promoCode,
    this.ctaUrl,
    this.category,
  });

  factory SponsorModel.fromMap(Map<String, dynamic> map) {
    return SponsorModel(
      id: map['id'] as String,
      brandName: map['brand_name'] as String,
      headlineAr: map['headline_ar'] as String,
      descriptionAr: map['description_ar'] as String,
      promoCode: map['promo_code'] as String?,
      ctaUrl: map['cta_url'] as String?,
      category: map['category'] as String?,
    );
  }
}
