import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/product_repository.dart';
import '../result/product_result_sheet.dart';
import '../result/suggest_alternative_sheet.dart';
import 'manual_barcode_dialog.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  final ProductRepository _repository = ProductRepository();

  bool _isTorchOn = false;
  bool _isProcessing = false;
  DateTime? _lastScannedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  Future<void> _handleBarcode(String rawBarcode) async {
    final now = DateTime.now();
    if (_isProcessing) return;
    if (_lastScannedTime != null && now.difference(_lastScannedTime!).inMilliseconds < 2500) {
      return;
    }

    _lastScannedTime = now;
    setState(() => _isProcessing = true);

    try {
      final product = await _repository.getProductByBarcode(rawBarcode);

      if (!mounted) return;

      if (product != null) {
        HapticFeedback.mediumImpact();
        await ProductResultSheet.show(context, product);
      } else {
        HapticFeedback.heavyImpact();
        _showUnlistedProductDialog(rawBarcode);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showUnlistedProductDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppTheme.amberGold, size: 28),
              SizedBox(width: 10),
              Text("المنتج غير مسجل بعد"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "الباركود: $barcode",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                "هذا المنتج غير متوفر حالياً في قاعدة البيانات بدون اتصال.\nهل تود إضافة اسمه واقتراح بديل مصري له لمساعدة الآخرين؟",
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إغلاق"),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                SuggestAlternativeSheet.show(context, targetBarcode: barcode);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text("إضافة المنتج الآن"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManualBarcode() async {
    final barcode = await ManualBarcodeDialog.show(context);
    if (barcode != null && barcode.isNotEmpty) {
      _handleBarcode(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final val = barcode.rawValue;
                if (val != null && val.trim().isNotEmpty) {
                  _handleBarcode(val.trim());
                  break;
                }
              }
            },
          ),

          // Custom Scanning Overlay Reticle
          _buildScannerOverlay(),

          // Top Action Controls (Torch & Flip)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Text("🇪🇬", style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text(
                            "بَديل | فحص الباركود",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Torch & Flip Controls
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isTorchOn ? AppTheme.amberGold : Colors.white,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _controller.toggleTorch();
                            setState(() => _isTorchOn = !_isTorchOn);
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildCircleButton(
                          icon: Icons.flip_camera_android_rounded,
                          color: Colors.white,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _controller.switchCamera();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls & Manual Entry
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Instruction Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "وجّه الكاميرا نحو باركود المنتج للتحقق الفوري",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),

                // Manual Barcode Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.92),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _openManualBarcode,
                    icon: const Icon(Icons.keyboard_rounded),
                    label: const Text(
                      "أدخل الباركود يدوياً 🔍",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildScannerOverlay() {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;

    return Center(
      child: SizedBox(
        width: scanBoxSize,
        height: scanBoxSize * 0.75,
        child: Stack(
          children: [
            // Framing Box
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.8),
                  width: 2.5,
                ),
              ),
            ),

            // Corner Accents
            ..._buildCornerAccents(),

            // Scanning line indicator
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerAccents() {
    const double length = 22;
    const double thickness = 4;
    const color = AppTheme.primaryGreen;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
    ];
  }
}
