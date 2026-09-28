import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../data/models/alternative_model.dart';
import '../../data/repositories/product_repository.dart';
import 'suggest_alternative_sheet.dart';

class ProductResultSheet extends StatefulWidget {
  final ProductModel product;

  const ProductResultSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductModel product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductResultSheet(product: product),
    );
  }

  @override
  State<ProductResultSheet> createState() => _ProductResultSheetState();
}

class _ProductResultSheetState extends State<ProductResultSheet> {
  final ProductRepository _repository = ProductRepository();
  List<AlternativeModel> _alternatives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    if (widget.product.isBoycott) {
      final alts = await _repository.getAlternatives(widget.product.id);
      if (mounted) {
        setState(() {
          _alternatives = alts;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBoycott = widget.product.isBoycott;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Scrollable Content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Status Header Card
                  _buildStatusHeader(isBoycott, isDark),

                  const SizedBox(height: 20),

                  // Product Details
                  _buildProductInfo(isDark),

                  const SizedBox(height: 20),

                  // Alternatives Section
                  if (isBoycott) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "البدائل المصرية المتاحة 🇪🇬",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_alternatives.length} بدائل معتمدة",
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_alternatives.isEmpty)
                      _buildNoAlternativesFound(isDark)
                    else
                      ..._alternatives.map((alt) => _buildAlternativeCard(alt, isDark)),
                  ] else ...[
                    // If Safe Local Product
                    _buildSafeLocalBanner(isDark),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            SuggestAlternativeSheet.show(
                              context,
                              targetBarcode: widget.product.barcode,
                              targetProductName: widget.product.nameAr,
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text("اقترح بديلاً آخر"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () {
                          final altText = _alternatives.map((a) => "• ${a.product.nameAr} (${a.product.companyName})").join("\n");
                          final text = widget.product.isBoycott
                              ? "منتج '${widget.product.nameAr}' مقاطعة! البدائل المصرية المقترحة:\n$altText\n\nتم الفحص عبر تطبيق بديل (Badil) 🇪🇬"
                              : "منتج '${widget.product.nameAr}' منتج محلي مصري 100%! 🇪🇬\nتم الفحص عبر تطبيق بديل (Badil)";
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تم نسخ معلومات المنتج والبدائل بنجاح"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: "نسخ التفاصيل",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isBoycott, bool isDark) {
    final bgColor = isBoycott
        ? AppTheme.boycottRed.withOpacity(0.12)
        : AppTheme.primaryGreen.withOpacity(0.12);
    final borderColor = isBoycott ? AppTheme.boycottRed : AppTheme.primaryGreen;
    final iconColor = isBoycott ? AppTheme.boycottRed : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBoycott ? Icons.block_rounded : Icons.verified_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBoycott ? "منتج مقاطعة 🛑" : "منتج محلي 100% مصري 🇪🇬",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBoycott
                      ? "يدعم جهات غير متوافقة - ننصح باستبداله بالبدائل المحلية"
                      : "شركة مصرية وطنية - يدعم الاقتصاد المحلي",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.nameAr,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.product.nameEn != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.product.nameEn!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBadge(Icons.business_rounded, widget.product.companyName, isDark),
              const SizedBox(width: 8),
              if (widget.product.countryOfOrigin != null)
                _buildBadge(Icons.public_rounded, "بلد المنشأ: ${widget.product.countryOfOrigin}", isDark),
            ],
          ),
          if (widget.product.reasonAr != null && widget.product.isBoycott) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.boycottRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.product.reasonAr!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.boycottRed,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(AlternativeModel alt, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    "🇪🇬",
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alt.product.nameAr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alt.product.companyName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amberGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppTheme.amberGold),
                    const SizedBox(width: 4),
                    Text(
                      alt.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.amberGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (alt.noteAr != null) ...[
            const SizedBox(height: 10),
            Text(
              alt.noteAr!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafeLocalBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_rounded, color: AppTheme.primaryGreen, size: 36),
          const SizedBox(height: 8),
          const Text(
            "شكراً لدعمك المنتج المصري!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "هذا المنتج مصنوع بأيادي مصرية ويدعم الاقتصاد الوطني وتوفير فرص العمل.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlternativesFound(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          "لم يتم تسجيل بدائل معتمدة بعد لهذا المنتج.\nكن أول من يقترح بديلاً محلياً!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}
