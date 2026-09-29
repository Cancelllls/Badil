import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../result/product_result_sheet.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final ProductRepository _repository = ProductRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _repository.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'cookie':
        return Icons.cookie_rounded;
      case 'sparkles':
        return Icons.auto_awesome_rounded;
      case 'droplet':
        return Icons.water_drop_rounded;
      case 'milk':
        return Icons.breakfast_dining_rounded;
      case 'candy':
        return Icons.cake_rounded;
      case 'utensils':
        return Icons.restaurant_rounded;
      case 'shirt':
        return Icons.checkroom_rounded;
      case 'laptop':
        return Icons.laptop_chromebook_rounded;
      case 'store':
        return Icons.storefront_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _openCategoryDetails(CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CategoryProductsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final strings = LocaleController.instance.strings;
        final isAr = LocaleController.instance.isArabic;
        final textDir = LocaleController.instance.textDirection;

        return Directionality(
          textDirection: textDir,
          child: Scaffold(
            appBar: AppBar(
              title: Text(strings.categoriesHeaderTitle),
              centerTitle: true,
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (ctx, idx) {
                      final cat = _categories[idx];
                      return _buildCategoryCard(cat, isDark, isAr);
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel cat, bool isDark, bool isAr) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openCategoryDetails(cat),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(cat.icon),
                  color: AppTheme.primaryGreen,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                cat.localizedName(isAr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAr ? cat.nameEn : cat.nameAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryProductsScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ProductRepository _repository = ProductRepository();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prods = await _repository.getProductsByCategory(widget.category.id);
    if (mounted) {
      setState(() {
        _products = prods;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final strings = LocaleController.instance.strings;
        final isAr = LocaleController.instance.isArabic;
        final textDir = LocaleController.instance.textDirection;

        return Directionality(
          textDirection: textDir,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.category.localizedName(isAr)),
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (ctx, idx) {
                      final p = _products[idx];
                      final isBoycott = p.isBoycott;
                      final statusColor = isBoycott ? AppTheme.boycottRed : AppTheme.primaryGreen;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isBoycott ? Icons.block_rounded : Icons.verified_rounded,
                              color: statusColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            p.localizedName(isAr),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            "${p.companyName} • ${isBoycott ? strings.filterBoycott : (isAr ? 'بديل محلي 🇪🇬' : 'Safe Local 🇪🇬')}",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          trailing: Icon(
                            isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Theme.of(context).dividerColor,
                          ),
                          onTap: () => ProductResultSheet.show(context, p),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
