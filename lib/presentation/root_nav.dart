import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/locale_controller.dart';
import 'scanner/scanner_view.dart';
import 'search/search_view.dart';
import 'categories/categories_view.dart';
import 'tip_jar/tip_jar_view.dart';

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScannerView(),
    SearchView(),
    CategoriesView(),
    TipJarView(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final strings = LocaleController.instance.strings;
        final textDir = LocaleController.instance.textDirection;

        return Directionality(
          textDirection: textDir,
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = index);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    activeIcon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
                    label: strings.navScanner,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.search_rounded),
                    activeIcon: const Icon(Icons.search_rounded, size: 26),
                    label: strings.navSearch,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.grid_view_rounded),
                    activeIcon: const Icon(Icons.grid_view_rounded, size: 26),
                    label: strings.navCategories,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.favorite_outline_rounded),
                    activeIcon: const Icon(Icons.favorite_rounded, size: 26),
                    label: strings.navSupport,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
