import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/generated/app_localizations.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String)? onBarcodeScanned;
  final VoidCallback? onClose;

  const BarcodeScannerWidget({
    super.key,
    this.onBarcodeScanned,
    this.onClose,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with TickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isScanning = true;
  bool _flashEnabled = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _initializeAnimation();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false;
          _scannedCode = barcode.rawValue;
        });

        HapticFeedback.mediumImpact();
        _processBarcode(barcode.rawValue!);
      }
    }
  }

  void _processBarcode(String code) async {
    await Future.delayed(const Duration(seconds: 1));

    final mockProducts = {
      '123456789': AppLocalizations.of(context)!.organicBananas,
      '987654321': AppLocalizations.of(context)!.wholeMilk1l,
      '456789123': AppLocalizations.of(context)!.sourdoughBread,
      '789123456': AppLocalizations.of(context)!.greekYogurt,
      '321654987': AppLocalizations.of(context)!.freeRangeEggs,
    };

    final productName = mockProducts[code] ?? 'Product not found';

    if (productName != 'Product not found') {
      widget.onBarcodeScanned?.call(productName);
      widget.onClose?.call();
    } else {
      _showProductNotFound();
    }
  }

  void _showProductNotFound() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.productNotFoundTrySearchingManually, maxLines: 1, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.ok2,
          onPressed: () => widget.onClose?.call(),
        ),
      ),
    );

    setState(() => _isScanning = true);
  }

  void _toggleFlash() async {
    if (!kIsWeb) {
      try {
        await _scannerController.toggleTorch();
        setState(() => _flashEnabled = !_flashEnabled);
        HapticFeedback.lightImpact();
      } catch (e) {
        // Flash not supported
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebFallback();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),
          _buildScannerOverlay(),
          _buildTopControls(),
          _buildBottomInstructions(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              ...List.generate(4, (index) => _buildCornerIndicator(index)),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    top: _animation.value * (60.w - 4),
                    left: 2,
                    right: 2,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.primary,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerIndicator(int index) {
    final theme = Theme.of(context);
    final positions = [
      {'top': 0.0, 'left': 0.0},
      {'top': 0.0, 'right': 0.0},
      {'bottom': 0.0, 'left': 0.0},
      {'bottom': 0.0, 'right': 0.0},
    ];

    final position = positions[index];

    return Positioned(
      top: position['top'],
      left: position['left'],
      right: position['right'],
      bottom: position['bottom'],
      child: Container(
        width: 6.w,
        height: 6.w,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2
                ? BorderSide(
                    color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
            bottom: index >= 2
                ? BorderSide(
                    color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
            left: index % 2 == 0
                ? BorderSide(
                    color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
            right: index % 2 == 1
                ? BorderSide(
                    color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onClose?.call();
              },
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.surface,
                size: 24,
              ),
            ),
            if (!kIsWeb)
              IconButton(
                onPressed: _toggleFlash,
                icon: CustomIconWidget(
                  iconName: _flashEnabled ? 'flash_on' : 'flash_off',
                  color: _flashEnabled
                      ? theme.colorScheme.primary
                      : Colors.white,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInstructions() {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isScanning
                    ? AppLocalizations.of(context)!.positionBarcodeWithinTheFrame
                    : AppLocalizations.of(context)!.processing2,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.surface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              Text(
                AppLocalizations.of(context)!.theBarcodeWillBeScannedAutomatically,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFallback() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'qr_code_scanner',
            color: theme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          SizedBox(height: 4.h),
          Text(
            AppLocalizations.of(context)!.barcodeScanner,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          Text(
            'Barcode scanning is not available on web.\nPlease use the mobile app for this feature.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onClose?.call();
            },
            child: Text(AppLocalizations.of(context)!.close, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}