import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onBarcodeSearch;
  final VoidCallback? onBarcodePressed;
  final VoidCallback? onAIPressed;
  final VoidCallback? onClear;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search products, stores, categories...',
    this.onChanged,
    this.onSubmitted,
    this.onVoiceSearch,
    this.onVoicePressed,
    this.onBarcodeSearch,
    this.onBarcodePressed,
    this.onAIPressed,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isListening = false;

  // Support both old (onVoiceSearch) and new (onVoicePressed) parameter names
  VoidCallback? get _effectiveVoiceCallback =>
      widget.onVoicePressed ?? widget.onVoiceSearch;

  VoidCallback? get _effectiveBarcodeCallback =>
      widget.onBarcodePressed ?? widget.onBarcodeSearch;

  void _handleVoiceSearch() {
    final callback = _effectiveVoiceCallback;
    if (callback == null) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isListening = !_isListening;
    });

    // Simulate voice search toggle
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    });

    callback();
  }

  void _handleBarcodeSearch() {
    final callback = _effectiveBarcodeCallback;
    if (callback == null) return;

    HapticFeedback.lightImpact();
    callback();
  }

  void _handleClear() {
    HapticFeedback.lightImpact();
    widget.controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVoice = _effectiveVoiceCallback != null;
    final hasBarcode = _effectiveBarcodeCallback != null;
    final hasAI = widget.onAIPressed != null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : CustomIconWidget(
                          iconName: 'search',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _handleClear,
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'clear',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 2.h,
                ),
              ),
            ),
          ),
          // Divider before action buttons
          if (hasVoice || hasBarcode || hasAI)
            Container(
              width: 1,
              height: 6.h,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          // AI button
          if (hasAI)
            GestureDetector(
              onTap: widget.onAIPressed,
              child: Container(
                padding: EdgeInsets.all(3.w),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: 'auto_awesome',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          // Voice search button
          if (hasVoice)
            GestureDetector(
              onTap: _handleVoiceSearch,
              child: Container(
                padding: EdgeInsets.all(3.w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomIconWidget(
                    iconName: _isListening ? 'mic' : 'mic_none',
                    color: _isListening
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
          // Barcode scanner button
          if (hasBarcode)
            GestureDetector(
              onTap: _handleBarcodeSearch,
              child: Container(
                padding: EdgeInsets.all(3.w),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: 'qr_code_scanner',
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}