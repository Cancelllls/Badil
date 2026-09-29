import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/product_repository.dart';
import '../result/product_result_sheet.dart';
import '../result/suggest_alternative_sheet.dart';
import '../widgets/sponsor_card.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final ProductRepository _repository = ProductRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  String? _selectedStatusFilter; // null | 'boycott' | 'safe_local'
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final cats = await _repository.getCategories();
    final prods = await _repository.searchProducts('');
    if (mounted) {
      setState(() {
        _categories = cats;
        _products = prods;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isLoading = true);
      List<ProductModel> results = await _repository.searchProducts(
        query,
        statusFilter: _selectedStatusFilter,
      );

      if (_selectedCategoryId != null) {
        results = results.where((p) => p.categoryId == _selectedCategoryId).toList();
      }

      if (mounted) {
        setState(() {
          _products = results;
          _isLoading = false;
        });
      }
    });
  }

  void _selectCategory(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoading = true;
    });

    List<ProductModel> results = await _repository.searchProducts(
      _searchCtrl.text,
      statusFilter: _selectedStatusFilter,
    );

    if (categoryId != null) {
      results = results.where((p) => p.categoryId == categoryId).toList();
    }

    if (mounted) {
      setState(() {
        _products = results;
        _isLoading = false;
      });
    }
  }

  void _selectStatusFilter(String? status) async {
    setState(() {
      _selectedStatusFilter = status;
      _isLoading = true;
    });

    List<ProductModel> results = await _repository.searchProducts(
      _searchCtrl.text,
      statusFilter: status,
    );

    if (_selectedCategoryId != null) {
      results = results.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    if (mounted) {
      setState(() {
        _products = results;
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
              title: Text(isAr ? "دليل المنتجات والبدائل 🇪🇬" : "Products & Alternatives Directory 🇪🇬"),
              centerTitle: true,
            ),
            body: Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: strings.searchPlaceholder,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // 2. Status Segmented Filter Pills (All / Boycott / Safe Local)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatusPill(
                        label: strings.filterAll,
                        isSelected: _selectedStatusFilter == null,
                        color: AppTheme.primaryGreen,
                        onTap: () => _selectStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusPill(
                        label: "${strings.filterBoycott} 🛑",
                        isSelected: _selectedStatusFilter == 'boycott',
                        color: AppTheme.boycottRed,
                        onTap: () => _selectStatusFilter('boycott'),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusPill(
                        label: "${strings.filterSafeLocal} 🟢",
                        isSelected: _selectedStatusFilter == 'safe_local',
                        color: AppTheme.primaryGreen,
                        onTap: () => _selectStatusFilter('safe_local'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Category Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip(
                        strings.filterAll,
                        _selectedCategoryId == null,
                        () => _selectCategory(null),
                      ),
                      ..._categories.map((cat) => _buildCategoryChip(
                            cat.localizedName(isAr),
                            _selectedCategoryId == cat.id,
                            () => _selectCategory(cat.id),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 4. Main Product List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          children: [
                            if (_searchCtrl.text.isEmpty && _selectedCategoryId == null && _selectedStatusFilter == null)
                              const SponsorCard(),

                            if (_products.isEmpty)
                              _buildEmptyState(isDark, strings)
                            else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  _searchCtrl.text.isNotEmpty
                                      ? "${strings.search}: ${strings.searchResultsCount(_products.length)}"
                                      : "${strings.popularBrandsTitle} (${_products.length}):",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              ..._products.map((p) => _buildProductListTile(p, isDark, isAr, strings)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryGreen : null,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildProductListTile(ProductModel product, bool isDark, bool isAr, AppStrings strings) {
    final isBoycott = product.isBoycott;
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
          product.localizedName(isAr),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                product.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isBoycott ? strings.filterBoycott : (isAr ? "بديل محلي 🇪🇬" : "Safe Local 🇪🇬"),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          isAr ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Theme.of(context).dividerColor,
        ),
        onTap: () => ProductResultSheet.show(context, product),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 14),
          Text(
            strings.noResultsTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            strings.noResultsDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              SuggestAlternativeSheet.show(context, targetProductName: _searchCtrl.text);
            },
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(strings.suggestProductBtn),
          ),
        ],
      ),
    );
  }
}
