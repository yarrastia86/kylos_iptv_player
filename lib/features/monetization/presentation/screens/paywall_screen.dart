// Kylos IPTV Player - Paywall Screen
// Screen for displaying subscription options and handling purchases.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';
import 'package:kylos_iptv_player/features/monetization/domain/product_config.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/monetization_providers.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/widgets/product_card.dart';

/// Paywall screen showing subscription options.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    this.featureContext,
  });

  /// Optional context about which feature triggered the paywall.
  final String? featureContext;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    // Default to annual plan
    _selectedProductId = ProductConfig.annualSubscriptionId;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monetizationNotifierProvider);
    final theme = Theme.of(context);

    // Listen for purchase completion
    ref.listen<MonetizationState>(
      monetizationNotifierProvider,
      (previous, next) {
        if (next.purchaseStatus == PurchaseStatus.completed) {
          // Purchase completed, close paywall
          Navigator.of(context).pop(true);
          _showSuccessSnackbar(context);
        } else if (next.purchaseStatus == PurchaseStatus.error) {
          // Show error
          _showErrorDialog(context, next.lastPurchaseResult);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Feature context message
                    if (widget.featureContext != null) ...[
                      _buildContextMessage(context, widget.featureContext!),
                      const SizedBox(height: 24),
                    ],

                    // Header
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Feature comparison
                    _buildFeatureComparison(context),
                    const SizedBox(height: 24),

                    // Product options
                    if (state.isLoadingProducts)
                      const Center(child: CircularProgressIndicator())
                    else if (state.productsError != null)
                      _buildErrorState(context, state.productsError!)
                    else
                      _buildProductOptions(context, state),

                    const SizedBox(height: 16),

                    // Restore purchases
                    _buildRestoreButton(context, state),

                    const SizedBox(height: 16),

                    // Terms and privacy
                    _buildLegalText(context),
                  ],
                ),
              ),
            ),

            // Purchase button
            if (!state.isLoadingProducts && state.hasProducts)
              _buildPurchaseButton(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMessage(BuildContext context, String featureContext) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              featureContext,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          Icons.workspace_premium,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock Kylos Pro',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Get unlimited access to all premium features',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pro Features',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...ProductConfig.proFeatures.map(
          (feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductOptions(BuildContext context, MonetizationState state) {
    return Column(
      children: [
        // Annual plan (recommended)
        if (state.annualProduct != null)
          ProductCard(
            product: state.annualProduct!,
            isSelected: _selectedProductId == state.annualProduct!.id,
            isRecommended: true,
            onTap: () => setState(() {
              _selectedProductId = state.annualProduct!.id;
            }),
          ),

        const SizedBox(height: 12),

        // Monthly plan
        if (state.monthlyProduct != null)
          ProductCard(
            product: state.monthlyProduct!,
            isSelected: _selectedProductId == state.monthlyProduct!.id,
            onTap: () => setState(() {
              _selectedProductId = state.monthlyProduct!.id;
            }),
          ),

        const SizedBox(height: 12),

        // Lifetime plan (if available)
        if (state.lifetimeProduct != null)
          ProductCard(
            product: state.lifetimeProduct!,
            isSelected: _selectedProductId == state.lifetimeProduct!.id,
            onTap: () => setState(() {
              _selectedProductId = state.lifetimeProduct!.id;
            }),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load products',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => refreshProducts(ref),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context, MonetizationState state) {
    return TextButton(
      onPressed: state.isRestoringPurchases
          ? null
          : () => restorePurchases(ref),
      child: state.isRestoringPurchases
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Restore Purchases'),
    );
  }

  Widget _buildLegalText(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      'Subscriptions will automatically renew unless cancelled at least '
      '24 hours before the end of the current period. Your account will be '
      'charged for renewal within 24 hours prior to the end of the current period. '
      'You can manage and cancel your subscriptions in your device settings.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPurchaseButton(BuildContext context, MonetizationState state) {
    final theme = Theme.of(context);
    final selectedProduct = state.products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => state.products.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isPurchasing
                    ? null
                    : () => _startPurchase(selectedProduct),
                child: state.isPurchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_getPurchaseButtonText(selectedProduct)),
              ),
            ),
            if (selectedProduct.hasFreeTrial) ...[
              const SizedBox(height: 8),
              Text(
                'Start with ${selectedProduct.freeTrialDuration} free trial',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPurchaseButtonText(Product product) {
    if (product.hasFreeTrial) {
      return 'Start Free Trial';
    }

    switch (product.type) {
      case ProductType.monthlySubscription:
        return 'Subscribe for ${product.price}/month';
      case ProductType.annualSubscription:
        return 'Subscribe for ${product.price}/year';
      case ProductType.lifetime:
        return 'Buy for ${product.price}';
    }
  }

  Future<void> _startPurchase(Product product) async {
    await purchaseProduct(ref, product.id);
  }

  void _showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome to Kylos Pro!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, PurchaseResult? result) {
    if (result is! PurchaseError) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              clearPurchaseResult(ref);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Shows the paywall screen.
///
/// Returns true if a purchase was completed, false otherwise.
Future<bool> showPaywall(
  BuildContext context, {
  String? featureContext,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PaywallScreen(
        featureContext: featureContext,
      ),
    ),
  );

  return result ?? false;
}
