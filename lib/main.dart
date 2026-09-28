import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'presentation/root_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer portrait orientation for barcode scanning stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Warm up local database instance on launch
  DatabaseHelper.instance.database.ignore();

  runApp(const BadilApp());
}

class BadilApp extends StatelessWidget {
  const BadilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بديل - Badil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RootNav(),
    );
  }
}
