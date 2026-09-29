import 'product_model.dart';

class AlternativeModel {
  final ProductModel product;
  final String? noteAr;
  final String? noteEn;
  final double rating;

  const AlternativeModel({
    required this.product,
    this.noteAr,
    this.noteEn,
    this.rating = 5.0,
  });

  String? localizedNote(bool isAr) {
    if (isAr) return noteAr;
    return (noteEn != null && noteEn!.trim().isNotEmpty) ? noteEn : noteAr;
  }

  factory AlternativeModel.fromMap(Map<String, dynamic> map, ProductModel product) {
    return AlternativeModel(
      product: product,
      noteAr: map['note_ar'] as String?,
      noteEn: map['note_en'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
