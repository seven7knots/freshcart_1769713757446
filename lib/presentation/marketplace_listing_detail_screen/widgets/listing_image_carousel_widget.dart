import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_image_widget.dart';

class ListingImageCarouselWidget extends StatefulWidget {
  final List<String> images;

  const ListingImageCarouselWidget({super.key, required this.images});

  @override
  State<ListingImageCarouselWidget> createState() =>
      _ListingImageCarouselWidgetState();
}

class _ListingImageCarouselWidgetState
    extends State<ListingImageCarouselWidget> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 40.h,
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_not_supported,
              size: 60, color: Colors.grey[400]),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 40.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return CustomImageWidget(
                imageUrl: widget.images[index],
                width: double.infinity,
                height: 40.h,
                fit: BoxFit.cover,
                semanticLabel: 'Listing image ${index + 1}',
              );
            },
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 2.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  width: _currentIndex == index ? 8.w : 2.w,
                  height: 1.h,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
