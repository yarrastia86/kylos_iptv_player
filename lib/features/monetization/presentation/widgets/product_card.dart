// Kylos IPTV Player - Product Card Widget
// Widget displaying a purchasable product option.

import 'package:flutter/material.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';

/// Card widget displaying a product option.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isSelected,
    this.isRecommended = false,
    this.onTap,
  });

  final Product product;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Selection indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                      color: isSelected ? colorScheme.primary : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: colorScheme.onPrimary,
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getProductTitle(product),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getProductSubtitle(product),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (product.billingPeriod != null)
                        Text(
                          '/${_formatBillingPeriod(product.billingPeriod!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Recommended badge
        if (isRecommended)
          Positioned(
            top: -10,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'BEST VALUE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Savings badge
        if (product.savingsPercent != null && product.savingsPercent! > 0)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SAVE ${product.savingsPercent}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getProductTitle(Product product) {
    switch (product.type) {
      case ProductType.monthlySubscription:
        return 'Monthly';
      case ProductType.annualSubscription:
        return 'Annual';
      case ProductType.lifetime:
        return 'Lifetime';
    }
  }

  String _getProductSubtitle(Product product) {
    if (product.hasFreeTrial) {
      return '${product.freeTrialDuration} free trial';
    }

    switch (product.type) {
      case ProductType.monthlySubscription:
        return 'Billed monthly';
      case ProductType.annualSubscription:
        return 'Billed annually';
      case ProductType.lifetime:
        return 'One-time purchase';
    }
  }

  String _formatBillingPeriod(String period) {
    if (period.contains('month')) return 'mo';
    if (period.contains('year')) return 'yr';
    return period;
  }
}
