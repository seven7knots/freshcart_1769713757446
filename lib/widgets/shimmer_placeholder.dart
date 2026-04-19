import 'package:flutter/material.dart';

/// Base shimmer animation widget.
/// Wraps any child with a left-to-right shimmer sweep.
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(2.0, 0.3),
              colors: [base, highlight, base],
              stops: [
                (_ctrl.value - 0.3).clamp(0.0, 1.0),
                _ctrl.value,
                (_ctrl.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single shimmer box — building block for all skeletons.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// SKELETON LAYOUTS — match real content shapes
// ─────────────────────────────────────────────────────────

/// Hero banner skeleton — matches the ad carousel area.
class ShimmerHeroBanner extends StatelessWidget {
  const ShimmerHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const ShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
        ),
      ),
    );
  }
}

/// Categories row skeleton — matches horizontal category chips/icons.
class ShimmerCategoriesRow extends StatelessWidget {
  final int count;
  const ShimmerCategoriesRow({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return Column(
              children: const [
                ShimmerBox(width: 56, height: 56, borderRadius: 28),
                SizedBox(height: 6),
                ShimmerBox(width: 48, height: 10, borderRadius: 4),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Horizontal store/product row skeleton.
class ShimmerProductRow extends StatelessWidget {
  final int count;
  const ShimmerProductRow({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 150,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 134, height: 110, borderRadius: 12),
                SizedBox(height: 8),
                ShimmerBox(width: 100, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Store list skeleton — vertical list of store card skeletons.
class ShimmerStoreList extends StatelessWidget {
  final int count;
  const ShimmerStoreList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) {
        return ShimmerEffect(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const ShimmerBox(width: 64, height: 64, borderRadius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 120, height: 10, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Order card skeleton — matches an order history tile.
class ShimmerOrderCard extends StatelessWidget {
  const ShimmerOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF5F5F5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  ShimmerBox(width: 70, height: 14, borderRadius: 4),
                ],
              ),
              const SizedBox(height: 12),
              const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
              const SizedBox(height: 8),
              const ShimmerBox(width: 140, height: 12, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic full-screen skeleton — replaces Center(child: CircularProgressIndicator()).
class ShimmerFullPage extends StatelessWidget {
  const ShimmerFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
            SizedBox(height: 20),
            ShimmerBox(width: 200, height: 16, borderRadius: 4),
            SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 10),
            ShimmerBox(width: 250, height: 12, borderRadius: 4),
            SizedBox(height: 24),
            ShimmerBox(width: 160, height: 16, borderRadius: 4),
            SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
