import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'app_strings.dart';
export 'app_strings.dart';

class LocaleController extends ChangeNotifier {
  static final LocaleController instance = LocaleController._();
  LocaleController._();

  Locale _locale = const Locale('ar');
  bool _initialized = false;

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  AppStrings get strings => AppStrings(isArabic);
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final saved = await DatabaseHelper.instance.getSetting('locale');
      if (saved != null && (saved == 'ar' || saved == 'en')) {
        _locale = Locale(saved);
      }
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
    try {
      await DatabaseHelper.instance.setSetting('locale', langCode);
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    final next = isArabic ? 'en' : 'ar';
    await setLocale(next);
  }
}
