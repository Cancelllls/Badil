import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
      List<ProductModel> results;
      if (_selectedCategoryId != null && query.trim().isEmpty) {
        results = await _repository.getProductsByCategory(_selectedCategoryId!);
      } else {
        results = await _repository.searchProducts(query);
        if (_selectedCategoryId != null) {
          results = results.where((p) => p.categoryId == _selectedCategoryId).toList();
        }
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

    List<ProductModel> results;
    if (categoryId == null) {
      results = await _repository.searchProducts(_searchCtrl.text);
    } else {
      if (_searchCtrl.text.trim().isNotEmpty) {
        results = await _repository.searchProducts(_searchCtrl.text);
        results = results.where((p) => p.categoryId == categoryId).toList();
      } else {
        results = await _repository.getProductsByCategory(categoryId);
      }
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("دليل المنتجات والبدائل 🇪🇬"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "ابحث بالاسم (مثال: بيبسي، شيبسي، أوكسي، سبيرو)...",
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

            // Category Filter Chips
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip("الكل", _selectedCategoryId == null, () => _selectCategory(null)),
                  ..._categories.map((cat) => _buildFilterChip(
                        cat.nameAr,
                        _selectedCategoryId == cat.id,
                        () => _selectCategory(cat.id),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Main Product List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        // Sponsor Banner
                        if (_searchCtrl.text.isEmpty && _selectedCategoryId == null)
                          const SponsorCard(),

                        if (_products.isEmpty)
                          _buildEmptyState(isDark)
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _searchCtrl.text.isNotEmpty
                                  ? "نتائج البحث (${_products.length}):"
                                  : "المنتجات الأكثر بحثاً والبدائل الوطنية:",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          ..._products.map((p) => _buildProductListTile(p, isDark)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryGreen : null,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProductListTile(ProductModel product, bool isDark) {
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
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isBoycott ? Icons.block_rounded : Icons.verified_rounded,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          product.nameAr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Text(
              product.companyName,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isBoycott ? "مقاطعة" : "بديل محلي 🇪🇬",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => ProductResultSheet.show(context, product),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 14),
          const Text(
            "لم نجد نتائج مطابقة لبحثك",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "تأكد من كتابة الاسم بشكل صحيح، أو اقترح إضافة المنتج لدعم قاعدة البيانات.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () {
              SuggestAlternativeSheet.show(context, targetProductName: _searchCtrl.text);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text("اقترح إضافة هذا المنتج"),
          ),
        ],
      ),
    );
  }
}
