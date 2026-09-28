import 'product_model.dart';

class AlternativeModel {
  final ProductModel product;
  final String? noteAr;
  final double rating;

  const AlternativeModel({
    required this.product,
    this.noteAr,
    this.rating = 5.0,
  });

  factory AlternativeModel.fromMap(Map<String, dynamic> map, ProductModel product) {
    return AlternativeModel(
      product: product,
      noteAr: map['note_ar'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
