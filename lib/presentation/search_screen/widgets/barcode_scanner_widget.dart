import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
    // Simulate barcode processing
    await Future.delayed(const Duration(seconds: 1));

    // Mock product lookup based on barcode
    final mockProducts = {
      '123456789': 'Organic Bananas',
      '987654321': 'Whole Milk 1L',
      '456789123': 'Sourdough Bread',
      '789123456': 'Greek Yogurt',
      '321654987': 'Free Range Eggs',
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
        content: Text('Product not found. Try searching manually.'),
        action: SnackBarAction(
          label: 'OK',
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
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),

          // Overlay
          _buildScannerOverlay(),

          // Top controls
          _buildTopControls(),

          // Bottom instructions
          _buildBottomInstructions(),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
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
              color: AppTheme.lightTheme.colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Corner indicators
              ...List.generate(4, (index) => _buildCornerIndicator(index)),

              // Scanning line animation
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
                            AppTheme.lightTheme.colorScheme.primary,
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
    final positions = [
      {'top': 0.0, 'left': 0.0}, // Top-left
      {'top': 0.0, 'right': 0.0}, // Top-right
      {'bottom': 0.0, 'left': 0.0}, // Bottom-left
      {'bottom': 0.0, 'right': 0.0}, // Bottom-right
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
                    color: AppTheme.lightTheme.colorScheme.primary, width: 4)
                : BorderSide.none,
            bottom: index >= 2
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 4)
                : BorderSide.none,
            left: index % 2 == 0
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 4)
                : BorderSide.none,
            right: index % 2 == 1
                ? BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
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
                color: Colors.white,
                size: 24,
              ),
            ),
            if (!kIsWeb)
              IconButton(
                onPressed: _toggleFlash,
                icon: CustomIconWidget(
                  iconName: _flashEnabled ? 'flash_on' : 'flash_off',
                  color: _flashEnabled
                      ? AppTheme.lightTheme.colorScheme.primary
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
                    ? 'Position barcode within the frame'
                    : 'Processing...',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'The barcode will be scanned automatically',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.lightTheme.colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'qr_code_scanner',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          SizedBox(height: 4.h),
          Text(
            'Barcode Scanner',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Barcode scanning is not available on web.\nPlease use the mobile app for this feature.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onClose?.call();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
