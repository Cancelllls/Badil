import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';
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
    final isAr = LocaleController.instance.isArabic;
    final strings = LocaleController.instance.strings;
    final textDir = LocaleController.instance.textDirection;

    return Directionality(
      textDirection: textDir,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
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
                width: 48,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Scrollable Content
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // Status Header Card
                  _buildStatusHeader(isBoycott, isDark, strings, isAr),

                  const SizedBox(height: 18),

                  // Product Details Card
                  _buildProductInfo(isDark, strings, isAr),

                  const SizedBox(height: 20),

                  // Alternatives Section
                  if (isBoycott) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          strings.verifiedAlternativesTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAr ? "${_alternatives.length} بدائل" : "${_alternatives.length} alternatives",
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        ),
                      )
                    else if (_alternatives.isEmpty)
                      _buildNoAlternativesFound(isDark, strings)
                    else
                      ..._alternatives.map((alt) => _buildAlternativeCard(alt, isDark, isAr)),
                  ] else ...[
                    _buildSafeLocalBanner(isDark, strings),
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
                              targetProductName: widget.product.localizedName(isAr),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: Text(strings.suggestAlternativeBtn),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          final altText = _alternatives
                              .map((a) => "• ${a.product.localizedName(isAr)} (${a.product.companyName})")
                              .join("\n");
                          final text = widget.product.isBoycott
                              ? "${strings.statusBoycott}: ${widget.product.localizedName(isAr)}!\n${strings.verifiedAlternativesTitle}:\n$altText\n\n${strings.appName} 🇪🇬"
                              : "${widget.product.localizedName(isAr)} - ${strings.statusSafeLocal}! 🇪🇬\n${strings.appName}";
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isAr ? "تم نسخ معلومات المنتج والبدائل" : "Product & alternatives copied!"),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded),
                        tooltip: strings.share,
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

  Widget _buildStatusHeader(bool isBoycott, bool isDark, AppStrings strings, bool isAr) {
    final bgColor = isBoycott
        ? AppTheme.boycottRed.withValues(alpha: 0.12)
        : AppTheme.primaryGreen.withValues(alpha: 0.12);
    final borderColor = isBoycott ? AppTheme.boycottRed : AppTheme.primaryGreen;
    final iconColor = isBoycott ? AppTheme.boycottRed : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBoycott ? Icons.block_rounded : Icons.verified_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBoycott ? strings.statusBoycott : strings.statusSafeLocal,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isBoycott ? strings.boycottWarningShort : strings.safeLocalShort,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildProductInfo(bool isDark, AppStrings strings, bool isAr) {
    final reason = widget.product.localizedReason(isAr);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.localizedName(isAr),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.product.nameEn != null && isAr) ...[
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(Icons.business_rounded, widget.product.companyName, isDark),
              if (widget.product.countryOfOrigin != null)
                _buildBadge(Icons.public_rounded, "${strings.countryOfOrigin}: ${widget.product.countryOfOrigin}", isDark),
              if (widget.product.barcode != null)
                _buildBadge(Icons.qr_code_rounded, widget.product.barcode!, isDark),
            ],
          ),
          if (reason != null && widget.product.isBoycott) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.boycottRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.boycottRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.boycottRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.boycottReasonTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.boycottRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                          ),
                        ),
                      ],
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
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
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

  Widget _buildAlternativeCard(AlternativeModel alt, bool isDark, bool isAr) {
    final note = alt.localizedNote(isAr);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        ProductResultSheet.show(context, alt.product);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("🇪🇬", style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alt.product.localizedName(isAr),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alt.product.companyName,
                        style: const TextStyle(
                          fontSize: 12,
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
                    color: AppTheme.amberGold.withValues(alpha: 0.15),
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
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSafeLocalBanner(bool isDark, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.primaryGreen, size: 40),
          const SizedBox(height: 8),
          Text(
            LocaleController.instance.isArabic
                ? "شكراً لدعمك الصناعة الوطنية! 🇪🇬"
                : "Thank you for supporting national industry! 🇪🇬",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleController.instance.isArabic
                ? "هذا المنتج مصنع بأيادي مصرية وعربية ويساهم مباشرة في تنمية الاقتصاد المستقل."
                : "This product is manufactured domestically and directly strengthens independent economic growth.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlternativesFound(bool isDark, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          strings.noAlternativesFound,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}
