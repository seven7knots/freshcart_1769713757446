import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ai_message_model.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/cart_provider.dart';
import '../../../routes/app_routes.dart';

class MessageBubbleWidget extends ConsumerWidget {
  final AIMessageModel message;
  final bool isUser;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color aiBubbleBg = isLight ? Colors.grey.shade100 : const Color(0xFF1A1A1A);
    final Color aiTextColor = isLight ? Colors.black87 : Colors.white.withOpacity(0.9);
    final Color userTextColor = Colors.white;
    final Color timestampColor = isLight ? Colors.grey.shade500 : Colors.white.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kjRed.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.kjRed,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Main message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.kjRed : aiBubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUser ? userTextColor : aiTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                // Product cards if metadata contains products
                if (!isUser && message.metadata != null)
                  _buildRichContent(context, ref),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: timestampColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildRichContent(BuildContext context, WidgetRef ref) {
    final metadata = message.metadata!;
    final List<dynamic>? products = metadata['products'] as List<dynamic>?;
    final Map<String, dynamic>? store = metadata['store'] as Map<String, dynamic>?;
    final List<dynamic>? actions = metadata['actions'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product cards
        if (products != null && products.isNotEmpty)
          ...products.map((p) => _buildProductCard(
                context,
                ref,
                Map<String, dynamic>.from(p),
              )),

        // Store card
        if (store != null) _buildStoreCard(context, store),

        // Action buttons
        if (actions != null && actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((a) {
                final action = Map<String, dynamic>.from(a);
                return _buildActionButton(context, ref, action);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> product,
  ) {
    final name = product['name'] ?? 'Unknown Product';
    final price = product['price'] ?? 0.0;
    final currency = product['currency'] ?? 'USD';
    final imageUrl = product['image_url'] as String?;
    final storeName = product['store_name'] ?? '';
    final productId = product['product_id'] ?? product['id'] ?? '';
    final isAvailable = product['is_available'] ?? true;

    final theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color cardBg = isLight ? Colors.grey.shade100 : const Color(0xFF1A1A1A);
    final Color cardBorder = isLight ? Colors.grey.shade300 : Colors.white.withOpacity(0.06);
    final Color imageBg = isLight ? Colors.grey.shade200 : const Color(0xFF2A2A2A);
    final Color nameColor = isLight ? Colors.black87 : Colors.white;
    final Color subtitleColor = isLight ? Colors.grey.shade600 : Colors.white.withOpacity(0.4);
    final Color viewBg = isLight ? Colors.grey.shade200 : Colors.white.withOpacity(0.08);
    final Color viewText = isLight ? Colors.grey.shade700 : Colors.white70;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: imageBg,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white24,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white24,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (storeName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        storeName,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency ${price is double ? price.toStringAsFixed(2) : price}',
                    style: const TextStyle(
                      color: AppTheme.kjRed,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                // View detail
                GestureDetector(
                  onTap: () {
                    if (productId.toString().isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.productDetail,
                        arguments: productId.toString(),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: viewBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(
                        color: viewText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Add to cart
                if (isAvailable)
                  GestureDetector(
                    onTap: () {
                      if (productId.toString().isNotEmpty) {
                        ref.read(cartNotifierProvider.notifier).addToCart(
                              productId: productId.toString(),
                              quantity: 1,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to cart'),
                            backgroundColor: AppTheme.kjRed,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kjRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    Map<String, dynamic> store,
  ) {
    final name = store['name'] ?? 'Unknown Store';
    final rating = store['rating'];
    final storeId = store['store_id'] ?? store['id'] ?? '';
    final category = store['category'] ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (storeId.toString().isNotEmpty) {
              Navigator.pushNamed(
                context,
                AppRoutes.storeDetail,
                arguments: {'storeId': storeId.toString()},
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.kjRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: AppTheme.kjRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.isNotEmpty)
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> action,
  ) {
    final label = action['label'] ?? 'Action';
    final route = action['route'] as String?;
    final actionType = action['type'] as String?;

    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route, arguments: action['arguments']);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actionType == 'primary'
              ? AppTheme.kjRed
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: actionType == 'primary' ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}