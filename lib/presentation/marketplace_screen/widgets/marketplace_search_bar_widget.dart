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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'What are you looking for?',
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 6.w),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 5.w),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                )
              : Icon(Icons.mic, color: Colors.grey[600], size: 5.w),
          filled: true,
          fillColor: Colors.grey[100],
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
