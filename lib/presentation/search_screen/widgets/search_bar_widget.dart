import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onBarcodePressed;
  final VoidCallback? onAIPressed;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onVoicePressed,
    this.onBarcodePressed,
    this.onAIPressed,
    this.onChanged,
    this.onSubmitted,
    this.isLoading = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        autofocus: true,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isFocused = true);
        },
        decoration: InputDecoration(
          hintText: 'Search for products, brands, categories...',
          hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'search',
              color: _isFocused
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onAIPressed?.call();
                },
                icon: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.difference,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/happy-robot-3d-ai-character-600nw-2464455965-1769833585327.jpg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                tooltip: 'AI Assistant',
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onVoicePressed?.call();
                },
                icon: CustomIconWidget(
                  iconName: 'mic',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'Voice search',
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onBarcodePressed?.call();
                },
                icon: CustomIconWidget(
                  iconName: 'qr_code_scanner',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'Scan barcode',
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.lightTheme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppTheme.lightTheme.colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
        style: AppTheme.lightTheme.textTheme.bodyMedium,
      ),
    );
  }
}
