import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badil/core/database/database_helper.dart';
import 'package:badil/core/localization/locale_controller.dart';
import 'package:badil/data/models/product_model.dart';
import 'package:badil/data/models/category_model.dart';
import 'package:badil/data/models/alternative_model.dart';
import 'package:badil/data/models/country_prefix_model.dart';
import 'package:badil/presentation/tip_jar/tip_jar_view.dart';
import 'package:badil/core/theme/app_theme.dart';

void main() {
  group('Arabic Normalization Tests', () {
    test('Unifies Alef with Hamza and Madda variants', () {
      expect(DatabaseHelper.normalizeArabic('أحمد'), 'احمد');
      expect(DatabaseHelper.normalizeArabic('إبراهيم'), 'ابراهيم');
      expect(DatabaseHelper.normalizeArabic('آيس كريم'), 'ايس كريم');
    });

    test('Unifies Teh Marbuta and Heh', () {
      expect(DatabaseHelper.normalizeArabic('شوكولاتة'), 'شوكولاته');
      expect(DatabaseHelper.normalizeArabic('جبنة'), 'جبنه');
    });

    test('Unifies Alef Maqsura and Yeh', () {
      expect(DatabaseHelper.normalizeArabic('شيبسى'), 'شيبسي');
      expect(DatabaseHelper.normalizeArabic('على'), 'علي');
    });

    test('Strips Tashkeel / Harakat', () {
      expect(DatabaseHelper.normalizeArabic('بَدِيل'), 'بديل');
      expect(DatabaseHelper.normalizeArabic('شَيْبْسِي'), 'شيبسي');
    });
  });

  group('Model Serialization & Localization Tests', () {
    test('ProductModel parses boycott product correctly and supports bilingual getters', () {
      final map = {
        'id': 'pepsi_can',
        'barcode': '6221010001011',
        'name_ar': 'بيبسي كانز',
        'name_en': 'Pepsi Can',
        'company_name': 'PepsiCo',
        'status': 'boycott',
        'reason_ar': 'دعم الاحتلال',
        'reason_en': 'Supports occupation',
        'created_at': 1700000000,
      };

      final product = ProductModel.fromMap(map);
      expect(product.id, 'pepsi_can');
      expect(product.isBoycott, isTrue);
      expect(product.isSafeLocal, isFalse);
      expect(product.localizedName(true), 'بيبسي كانز');
      expect(product.localizedName(false), 'Pepsi Can');
      expect(product.localizedReason(true), 'دعم الاحتلال');
      expect(product.localizedReason(false), 'Supports occupation');
    });

    test('CategoryModel parses properly and supports localizedName', () {
      final map = {
        'id': 'beverages',
        'name_ar': 'مشروبات',
        'name_en': 'Beverages',
        'icon': 'coffee',
        'sort_order': 1,
      };

      final cat = CategoryModel.fromMap(map);
      expect(cat.id, 'beverages');
      expect(cat.localizedName(true), 'مشروبات');
      expect(cat.localizedName(false), 'Beverages');
      expect(cat.sortOrder, 1);
    });

    test('AlternativeModel parses noteEn and supports localizedNote', () {
      final p = const ProductModel(
        id: 'spiro',
        nameAr: 'سبيرو سباتس',
        nameEn: 'Spiro Spathis',
        companyName: 'Spiro',
        status: 'safe_local',
        createdAt: 1700000000,
      );

      final alt = AlternativeModel(
        product: p,
        noteAr: 'العلامة المصرية الأقدم',
        noteEn: 'Oldest Egyptian soda',
        rating: 5.0,
      );

      expect(alt.localizedNote(true), 'العلامة المصرية الأقدم');
      expect(alt.localizedNote(false), 'Oldest Egyptian soda');
    });

    test('CountryPrefixModel parses and provides flags', () {
      final prefix = const CountryPrefixModel(
        prefix: '729',
        countryCode: 'IL',
        nameAr: 'إسرائيل (مقاطعة مؤكدة)',
        nameEn: 'Israel (Strict Boycott)',
        flagEmoji: '🇮🇱',
        defaultStatus: 'boycott',
      );

      expect(prefix.defaultStatus, 'boycott');
      expect(prefix.flagEmoji, '🇮🇱');
      expect(prefix.localizedName(true), 'إسرائيل (مقاطعة مؤكدة)');
      expect(prefix.localizedName(false), 'Israel (Strict Boycott)');
    });
  });

  group('LocaleController Tests', () {
    test('Toggles between Arabic and English with correct directionality', () async {
      final ctrl = LocaleController.instance;
      await ctrl.setLocale('ar');
      expect(ctrl.isArabic, isTrue);
      expect(ctrl.textDirection, TextDirection.rtl);
      expect(ctrl.strings.navScanner, 'فحص الباركود');

      await ctrl.toggleLocale();
      expect(ctrl.isArabic, isFalse);
      expect(ctrl.textDirection, TextDirection.ltr);
      expect(ctrl.strings.navScanner, 'Scanner');

      // Return to Arabic default
      await ctrl.setLocale('ar');
      expect(ctrl.isArabic, isTrue);
    });
  });

  testWidgets('TipJarView renders donation options and sponsor banner correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const TipJarView(),
      ),
    );

    expect(find.text('إنستاباي (InstaPay)'), findsOneWidget);
    expect(find.text('فودافون كاش (Vodafone Cash)'), findsOneWidget);
    expect(find.text('USDT (TRC-20)'), findsOneWidget);
  });
}
