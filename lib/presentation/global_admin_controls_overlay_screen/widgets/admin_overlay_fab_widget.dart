import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class AdminOverlayFabWidget extends StatefulWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const AdminOverlayFabWidget({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  State<AdminOverlayFabWidget> createState() => _AdminOverlayFabWidgetState();
}

class _AdminOverlayFabWidgetState extends State<AdminOverlayFabWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AdminOverlayFabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 12.h,
      right: 4.w,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isActive
                      ? [
                          Colors.orange.shade600,
                          Colors.deepOrange.shade700,
                        ]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isActive
                            ? Colors.orange
                            : theme.colorScheme.primary)
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (widget.isActive)
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse animation when active
                  if (widget.isActive)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.3),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Container(
                          width: 14.w * value,
                          height: 14.w * value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5 / value),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  // Icon
                  Icon(
                    widget.isActive ? Icons.edit_off : Icons.edit,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

