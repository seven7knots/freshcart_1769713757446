// SESSION 34: ProductReviewsSection removed — store ratings handled via store_ratings table
import 'package:flutter/material.dart';

class ProductReviewsSection extends StatelessWidget {
  final String productId;
  const ProductReviewsSection({super.key, required this.productId});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
