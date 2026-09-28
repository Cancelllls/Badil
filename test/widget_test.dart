import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badil/core/database/database_helper.dart';
import 'package:badil/data/models/product_model.dart';
import 'package:badil/data/models/category_model.dart';
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

  group('Model Serialization Tests', () {
    test('ProductModel parses boycott product correctly', () {
      final map = {
        'id': 'pepsi_can',
        'barcode': '6221010001011',
        'name_ar': 'بيبسي كانز',
        'company_name': 'PepsiCo',
        'status': 'boycott',
        'created_at': 1700000000,
      };

      final product = ProductModel.fromMap(map);
      expect(product.id, 'pepsi_can');
      expect(product.isBoycott, isTrue);
      expect(product.isSafeLocal, isFalse);
    });

    test('CategoryModel parses properly', () {
      final map = {
        'id': 'beverages',
        'name_ar': 'مشروبات',
        'name_en': 'Beverages',
        'icon': 'coffee',
        'sort_order': 1,
      };

      final cat = CategoryModel.fromMap(map);
      expect(cat.id, 'beverages');
      expect(cat.nameAr, 'مشروبات');
      expect(cat.sortOrder, 1);
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

    // Verify support channels are displayed
    expect(find.text('إنستاباي (InstaPay)'), findsOneWidget);
    expect(find.text('فودافون كاش (Vodafone Cash)'), findsOneWidget);
    expect(find.text('العملات الرقمية (USDT TRC-20)'), findsOneWidget);
    expect(find.text('شبكة تيليجرام (TON)'), findsOneWidget);
    expect(find.text('أصحاب المصانع والعلامات المصرية 📢'), findsOneWidget);
  });
}
