import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ManualBarcodeDialog extends StatefulWidget {
  const ManualBarcodeDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const ManualBarcodeDialog(),
    );
  }

  @override
  State<ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<ManualBarcodeDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text("إدخال الباركود يدوياً 🔍"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "أدخل الأرقام المطبوعة أسفل الخطوط على عبوة المنتج (مثال: 6221010001011):",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "أدخل الباركود هنا...",
                prefixIcon: const Icon(Icons.qr_code_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => _ctrl.clear(),
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.pop(context, val.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            onPressed: () {
              if (_ctrl.text.trim().isNotEmpty) {
                Navigator.pop(context, _ctrl.text.trim());
              }
            },
            child: const Text("فحص المنتج"),
          ),
        ],
      ),
    );
  }
}
