import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SubcategoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> subcategory;
  final VoidCallback onTap;

  const SubcategoryCardWidget({
    super.key,
    required this.subcategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = (subcategory['name'] as String?) ?? 'Category';
    final desc = (subcategory['description'] as String?) ?? '';
    final imageUrl = (subcategory['image_url'] as String?) ?? '';
    final hasChildren =
        (subcategory['has_children'] == true) ||
            ((subcategory['children_count'] ?? 0) as int > 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Image row
              Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.category,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.category,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const Spacer(),
                  Icon(
                    hasChildren ? Icons.chevron_right : Icons.arrow_forward_ios,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              SizedBox(height: 1.2.h),

              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (desc.trim().isNotEmpty) ...[
                SizedBox(height: 0.8.h),
                Text(
                  desc.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
