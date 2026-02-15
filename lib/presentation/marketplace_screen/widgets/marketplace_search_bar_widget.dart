import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MarketplaceSearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;

  const MarketplaceSearchBarWidget({super.key, required this.onSearchChanged});

  @override
  State<MarketplaceSearchBarWidget> createState() =>
      _MarketplaceSearchBarWidgetState();
}

class _MarketplaceSearchBarWidgetState
    extends State<MarketplaceSearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: 'What are you looking for?',
          hintStyle: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(Icons.search,
              color: theme.colorScheme.onSurfaceVariant, size: 6.w),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: theme.colorScheme.onSurfaceVariant, size: 5.w),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                    setState(() {});
                  },
                )
              : Icon(Icons.mic,
                  color: theme.colorScheme.onSurfaceVariant, size: 5.w),
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3.w),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
      ),
    );
  }
}