import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/localization/locale_controller.dart';
import 'presentation/root_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer portrait orientation for barcode scanning stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Warm up local database instance and load locale on launch
  await DatabaseHelper.instance.database;
  await LocaleController.instance.init();

  runApp(const BadilApp());
}

class BadilApp extends StatelessWidget {
  const BadilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final isAr = LocaleController.instance.isArabic;
        return MaterialApp(
          title: isAr ? 'بَديل - Badil' : 'Badil - Boycott & Alternatives',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          locale: LocaleController.instance.locale,
          home: const RootNav(),
        );
      },
    );
  }
}
