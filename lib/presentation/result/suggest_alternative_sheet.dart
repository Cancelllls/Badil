import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';
import '../../data/repositories/crowdsource_repository.dart';

class SuggestAlternativeSheet extends StatefulWidget {
  final String? targetBarcode;
  final String? targetProductName;

  const SuggestAlternativeSheet({
    super.key,
    this.targetBarcode,
    this.targetProductName,
  });

  static Future<void> show(
    BuildContext context, {
    String? targetBarcode,
    String? targetProductName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SuggestAlternativeSheet(
        targetBarcode: targetBarcode,
        targetProductName: targetProductName,
      ),
    );
  }

  @override
  State<SuggestAlternativeSheet> createState() => _SuggestAlternativeSheetState();
}

class _SuggestAlternativeSheetState extends State<SuggestAlternativeSheet> {
  final _formKey = GlobalKey<FormState>();
  final CrowdsourceRepository _repository = CrowdsourceRepository();

  late TextEditingController _barcodeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _alternativeCtrl;
  late TextEditingController _notesCtrl;

  String _selectedStatus = 'boycott';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.targetBarcode ?? '');
    _nameCtrl = TextEditingController(text: widget.targetProductName ?? '');
    _companyCtrl = TextEditingController();
    _alternativeCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _alternativeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final strings = LocaleController.instance.strings;

    try {
      await _repository.submitUnknownProduct(
        barcode: _barcodeCtrl.text.trim(),
        productName: _nameCtrl.text.trim(),
        brandName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        suggestedStatus: _selectedStatus,
        suggestedAlternative: _alternativeCtrl.text.trim().isEmpty
            ? null
            : _alternativeCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text(
              strings.suggestionSubmitted,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = LocaleController.instance.strings;
    final textDir = LocaleController.instance.textDirection;

    return Directionality(
      textDirection: textDir,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.suggestFormTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocaleController.instance.isArabic
                            ? "ساعد مجتمع بديل في توثيق المنتجات واكتشاف البدائل الوطنية."
                            : "Help the community document products and discover ethical alternatives.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceChip(
                              label: "${strings.statusBoycott} 🛑",
                              selected: _selectedStatus == 'boycott',
                              onSelected: () => setState(() => _selectedStatus = 'boycott'),
                              selectedColor: AppTheme.boycottRed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildChoiceChip(
                              label: "${strings.filterSafeLocal} 🟢",
                              selected: _selectedStatus == 'safe_local',
                              onSelected: () => setState(() => _selectedStatus = 'safe_local'),
                              selectedColor: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: strings.barcodeLabel,
                          prefixIcon: const Icon(Icons.qr_code_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: strings.productNameField,
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? strings.fillRequiredFields : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _companyCtrl,
                        decoration: InputDecoration(
                          labelText: strings.brandNameField,
                          prefixIcon: const Icon(Icons.business_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_selectedStatus == 'boycott') ...[
                        TextFormField(
                          controller: _alternativeCtrl,
                          decoration: InputDecoration(
                            labelText: strings.altNameField,
                            prefixIcon: const Icon(Icons.swap_horiz_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: strings.notesField,
                          prefixIcon: const Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  strings.submitBtn,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required Color selectedColor,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.withValues(alpha: 0.4),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? selectedColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
