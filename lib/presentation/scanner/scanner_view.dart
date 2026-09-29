import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/country_prefix_model.dart';
import '../result/product_result_sheet.dart';
import '../result/suggest_alternative_sheet.dart';
import 'manual_barcode_dialog.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animController;
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

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
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
        final prefixInfo = await _repository.getCountryPrefix(rawBarcode);
        if (mounted) {
          _showUnlistedProductDialog(rawBarcode, prefixInfo);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showUnlistedProductDialog(String barcode, CountryPrefixModel? prefixInfo) {
    final isAr = LocaleController.instance.isArabic;
    final strings = LocaleController.instance.strings;
    final textDir = LocaleController.instance.textDirection;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: textDir,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.amberGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded, color: AppTheme.amberGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.barcodeNotFoundTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barcode pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      barcode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Country origin detection banner if detected by GS1 prefix
              if (prefixInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: prefixInfo.defaultStatus == 'boycott'
                        ? AppTheme.boycottRed.withValues(alpha: 0.12)
                        : AppTheme.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: prefixInfo.defaultStatus == 'boycott'
                          ? AppTheme.boycottRed.withValues(alpha: 0.3)
                          : AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(prefixInfo.flagEmoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? "بلد المنشأ (رمز الباركود): ${prefixInfo.nameAr}"
                                  : "Origin by Prefix: ${prefixInfo.nameEn}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: prefixInfo.defaultStatus == 'boycott'
                                    ? AppTheme.boycottRed
                                    : AppTheme.primaryGreen,
                              ),
                            ),
                            if (prefixInfo.defaultStatus == 'boycott')
                              Text(
                                isAr
                                    ? "⚠️ الباركود يبدأ بـ 729 (رمز الاحتلال الإسرائيلي المباشر)"
                                    : "⚠️ Barcode begins with 729 (Direct Israeli manufacture)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.boycottRed.withValues(alpha: 0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                strings.barcodeNotFoundDesc,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings.close),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                SuggestAlternativeSheet.show(context, targetBarcode: barcode);
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(strings.suggestProductBtn),
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
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final strings = LocaleController.instance.strings;
        final isAr = LocaleController.instance.isArabic;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera View
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

              // 2. Futuristic Reticle Overlay
              _buildScannerOverlay(),

              // 3. Top Action Controls & Language Switcher
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badil Brand Capsule
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'بَديل 🇪🇬' : 'Badil 🇪🇬',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "· ${strings.offlineBadge}",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Actions Row: Lang Toggle, Torch, Flip
                        Row(
                          children: [
                            // Language Switcher Pill
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                LocaleController.instance.toggleLocale();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.language_rounded, color: AppTheme.primaryGreen, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr ? "EN" : "عربي",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Torch Button
                            _buildCircleButton(
                              icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: _isTorchOn ? AppTheme.amberGold : Colors.white,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _controller.toggleTorch();
                                setState(() => _isTorchOn = !_isTorchOn);
                              },
                            ),
                            const SizedBox(width: 8),

                            // Camera Switch
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

              // 4. Bottom Manual Entry Card
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Quick Hint Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppTheme.amberGold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            strings.scannerQuickHint,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Manual Barcode Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.95),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _openManualBarcode,
                        icon: const Icon(Icons.keyboard_rounded),
                        label: Text(
                          strings.manualBarcodeBtn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildScannerOverlay() {
    final size = MediaQuery.of(context).size;
    final scanBoxWidth = size.width * 0.78;
    final scanBoxHeight = scanBoxWidth * 0.68;

    return Center(
      child: SizedBox(
        width: scanBoxWidth,
        height: scanBoxHeight,
        child: Stack(
          children: [
            // Framing Border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),

            // Animated Scanning Pulse Line
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Positioned(
                  top: _animController.value * (scanBoxHeight - 4),
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withValues(alpha: 0.0),
                          AppTheme.primaryGreenGlow,
                          AppTheme.primaryGreen.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Corner Accents
            ..._buildCornerAccents(),

            // Processing Indicator
            if (_isProcessing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerAccents() {
    const double length = 24;
    const double thickness = 4;
    const color = AppTheme.primaryGreen;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(22)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(22)),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topRight: Radius.circular(22)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topRight: Radius.circular(22)),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(22)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(22)),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(22)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(22)),
          ),
        ),
      ),
    ];
  }
}
