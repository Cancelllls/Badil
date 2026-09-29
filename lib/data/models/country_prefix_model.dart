class CountryPrefixModel {
  final String prefix;
  final String countryCode;
  final String nameAr;
  final String nameEn;
  final String flagEmoji;
  final String defaultStatus; // 'safe_local' | 'boycott' | 'neutral'

  const CountryPrefixModel({
    required this.prefix,
    required this.countryCode,
    required this.nameAr,
    required this.nameEn,
    required this.flagEmoji,
    required this.defaultStatus,
  });

  String localizedName(bool isAr) => isAr ? nameAr : nameEn;

  factory CountryPrefixModel.fromMap(Map<String, dynamic> map) {
    return CountryPrefixModel(
      prefix: map['prefix'] as String,
      countryCode: map['country_code'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      flagEmoji: map['flag_emoji'] as String,
      defaultStatus: map['default_status'] as String,
    );
  }
}
