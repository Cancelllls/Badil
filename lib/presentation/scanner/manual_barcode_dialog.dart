import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';

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
    final strings = LocaleController.instance.strings;
    final textDir = LocaleController.instance.textDirection;

    return Directionality(
      textDirection: textDir,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.manualBarcodeTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleController.instance.isArabic
                  ? "أدخل الأرقام المطبوعة أسفل خطوط الباركود على المنتج:"
                  : "Enter the barcode digits printed on the product packaging:",
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: strings.manualBarcodeHint,
                prefixIcon: const Icon(Icons.dialpad_rounded),
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
            child: Text(strings.cancel),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_ctrl.text.trim().isNotEmpty) {
                Navigator.pop(context, _ctrl.text.trim());
              }
            },
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(strings.search),
          ),
        ],
      ),
    );
  }
}
