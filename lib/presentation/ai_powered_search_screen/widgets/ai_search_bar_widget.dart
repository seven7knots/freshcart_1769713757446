import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AISearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final bool isProcessing;

  const AISearchBarWidget({
    required this.controller,
    required this.onSearch,
    this.isProcessing = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask AI: "cheap Italian food open now"',
                  hintStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: 12.sp,
                  ),
                  prefixIcon: isProcessing
                      ? Padding(
                          padding: EdgeInsets.all(3.w),
                          child: SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE50914),
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(3.w),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.difference,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/happy-robot-3d-ai-character-600nw-2464455965-1769833585327.jpg',
                                width: 6.w,
                                height: 6.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 2.h,
                  ),
                ),
                onSubmitted: onSearch,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: () {
              if (controller.text.isNotEmpty) {
                onSearch(controller.text);
              }
            },
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914),
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Icon(
                Icons.search,
                color: Colors.white,
                size: 6.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
