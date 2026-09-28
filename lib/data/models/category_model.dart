class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.sortOrder,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      icon: map['icon'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }
}
