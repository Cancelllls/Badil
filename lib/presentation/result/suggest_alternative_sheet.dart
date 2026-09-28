import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text(
              "شكراً لك! تم حفظ اقتراحك محلياً وسيتم مراجعته وإضافته لقاعدة البيانات.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء الحفظ: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
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
            // Handle
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
                      const Text(
                        "اقترح منتجاً أو بديلاً مصرياً 🇪🇬",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "ساعد مجتمع بديل في توثيق المنتجات واكتشاف البدائل الوطنية الممتازة.",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Status Selector
                      Row(
                        children: [
                          Expanded(
                            child: _buildChoiceChip(
                              label: "منتج مقاطعة 🛑",
                              selected: _selectedStatus == 'boycott',
                              onSelected: () => setState(() => _selectedStatus = 'boycott'),
                              selectedColor: AppTheme.boycottRed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildChoiceChip(
                              label: "بديل محلي 🟢",
                              selected: _selectedStatus == 'safe_local',
                              onSelected: () => setState(() => _selectedStatus = 'safe_local'),
                              selectedColor: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Barcode
                      TextFormField(
                        controller: _barcodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "رقم الباركود (EAN / Barcode)",
                          prefixIcon: Icon(Icons.qr_code_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? "يرجى إدخال الباركود" : null,
                      ),
                      const SizedBox(height: 14),

                      // Product Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "اسم المنتج بالعربي",
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? "يرجى إدخال اسم المنتج" : null,
                      ),
                      const SizedBox(height: 14),

                      // Company Name
                      TextFormField(
                        controller: _companyCtrl,
                        decoration: const InputDecoration(
                          labelText: "اسم الشركة المصنعة (اختياري)",
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Suggested Alternative
                      if (_selectedStatus == 'boycott') ...[
                        TextFormField(
                          controller: _alternativeCtrl,
                          decoration: const InputDecoration(
                            labelText: "البديل المصري المقترح",
                            hintText: "مثال: سبيرو سباتس، أوكسي، تايجر...",
                            prefixIcon: Icon(Icons.swap_horiz_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "ملاحظات أو سبب المقاطعة (اختياري)",
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Submit Button
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
                              : const Text(
                                  "إرسال الاقتراح",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          color: selected ? selectedColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.withOpacity(0.4),
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
