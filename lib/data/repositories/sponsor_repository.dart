import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sponsor_model.dart';

class SponsorRepository {
  static const String apiBaseUrl = 'https://badil-api.cancellls.com/api/v1';

  // Default fallback sponsor banner for offline mode
  static const defaultSponsor = SponsorModel(
    id: 'spiro_official',
    brandName: 'سبيرو سباتس (Spiro Spathis)',
    headlineAr: 'مشروب الصودا المصري الأصيل منذ 1920',
    descriptionAr: 'ادعم الصناعة الوطنية واكتشف أحدث النكهات المنعشة في أقرب متجر إليك.',
    promoCode: 'EGYPT100',
    ctaUrl: 'https://cancellls.com',
    category: 'beverages',
  );

  Future<SponsorModel> getActiveSponsor() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/sponsors'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return SponsorModel.fromMap(data);
      }
    } catch (_) {}

    return defaultSponsor;
  }
}
