// Kylos IPTV Player - Paywall Screen Tests
// Widget tests for the PaywallScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';
import 'package:kylos_iptv_player/features/monetization/domain/product_config.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/monetization_notifier.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/monetization_providers.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/screens/paywall_screen.dart';

void main() {
  late MonetizationState mockState;

  setUp(() {
    mockState = MonetizationState.initial().copyWith(
      products: _mockProducts,
      isLoadingProducts: false,
    );
  });

  Widget createTestWidget({
    MonetizationState? state,
    String? featureContext,
  }) {
    return ProviderScope(
      overrides: [
        monetizationNotifierProvider.overrideWith(
          (ref) => MockMonetizationNotifier(state ?? mockState),
        ),
      ],
      child: MaterialApp(
        home: PaywallScreen(featureContext: featureContext),
      ),
    );
  }

  group('PaywallScreen', () {
    testWidgets('displays header with title and description', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Unlock Kylos Pro'), findsOneWidget);
      expect(
        find.text('Get unlimited access to all premium features'),
        findsOneWidget,
      );
    });

    testWidgets('displays pro features list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pro Features'), findsOneWidget);

      // Check that features are displayed
      for (final feature in ProductConfig.proFeatures) {
        expect(find.text(feature), findsOneWidget);
      }
    });

    testWidgets('displays loading indicator when products are loading',
        (tester) async {
      final loadingState = MonetizationState.initial().copyWith(
        isLoadingProducts: true,
      );

      await tester.pumpWidget(createTestWidget(state: loadingState));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state when products fail to load',
        (tester) async {
      final errorState = MonetizationState.initial().copyWith(
        isLoadingProducts: false,
        productsError: 'Network error',
      );

      await tester.pumpWidget(createTestWidget(state: errorState));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load products'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays product cards when products are loaded',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for product titles
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);
    });

    testWidgets('annual product is marked as recommended', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The "BEST VALUE" badge should be visible
      expect(find.text('BEST VALUE'), findsOneWidget);
    });

    testWidgets('displays savings badge for annual product', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The savings badge should show 44% for annual
      expect(find.text('SAVE 44%'), findsOneWidget);
    });

    testWidgets('annual product is selected by default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The purchase button should show annual price
      expect(find.text('Start Free Trial'), findsOneWidget);
    });

    testWidgets('tapping product card changes selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make monthly card visible, then tap
      final monthlyCard = find.text('Monthly');
      await tester.ensureVisible(monthlyCard);
      await tester.pumpAndSettle();
      await tester.tap(monthlyCard);
      await tester.pumpAndSettle();

      // Purchase button should now show monthly price
      expect(find.text('Subscribe for \$2.99/month'), findsOneWidget);
    });

    testWidgets('displays restore purchases button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Restore Purchases'), findsOneWidget);
    });

    testWidgets('displays legal text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Subscriptions will automatically renew'),
        findsOneWidget,
      );
    });

    testWidgets('displays feature context message when provided',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        featureContext: 'Cloud sync requires Pro',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cloud sync requires Pro'), findsOneWidget);
    });

    testWidgets('purchase button shows loading state when purchasing',
        (tester) async {
      final purchasingState = mockState.copyWith(
        purchaseStatus: PurchaseStatus.purchasing,
      );

      await tester.pumpWidget(createTestWidget(state: purchasingState));
      await tester.pump();

      // Should show loading indicator instead of text
      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);

      // The button should contain a CircularProgressIndicator
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    });

    testWidgets('restore button shows loading state when restoring',
        (tester) async {
      final restoringState = mockState.copyWith(
        isRestoringPurchases: true,
      );

      await tester.pumpWidget(createTestWidget(state: restoringState));
      await tester.pump();

      // Should show loading indicator in restore button
      final textButton = find.byType(TextButton);
      expect(
        find.descendant(
          of: textButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    });

    testWidgets('close button navigates back', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monetizationNotifierProvider.overrideWith(
              (ref) => MockMonetizationNotifier(mockState),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaywallScreen(),
                      ),
                    ),
                    child: const Text('Open Paywall'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open paywall
      await tester.tap(find.text('Open Paywall'));
      await tester.pumpAndSettle();

      // Verify paywall is shown
      expect(find.text('Unlock Kylos Pro'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should be back to original screen
      expect(find.text('Open Paywall'), findsOneWidget);
    });

    testWidgets('displays free trial message for products with trial',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to ensure annual product card is visible
      final annualCard = find.text('Annual');
      await tester.ensureVisible(annualCard);
      await tester.pumpAndSettle();

      // Annual product has 7-day trial (could appear in product card and/or purchase button)
      expect(find.textContaining('7 days free trial'), findsWidgets);
    });
  });

  group('PaywallScreen product selection', () {
    testWidgets('selecting monthly product updates button text',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make monthly product visible and tap
      final monthlyCard = find.text('Monthly');
      await tester.ensureVisible(monthlyCard);
      await tester.pumpAndSettle();
      await tester.tap(monthlyCard);
      await tester.pumpAndSettle();

      expect(find.text('Subscribe for \$2.99/month'), findsOneWidget);
    });

    testWidgets('selecting lifetime product updates button text',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make lifetime product visible and tap
      final lifetimeCard = find.text('Lifetime');
      await tester.ensureVisible(lifetimeCard);
      await tester.pumpAndSettle();
      await tester.tap(lifetimeCard);
      await tester.pumpAndSettle();

      expect(find.text('Buy for \$49.99'), findsOneWidget);
    });

    testWidgets('selecting annual product shows free trial button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make monthly product visible and tap first to deselect annual
      final monthlyCard = find.text('Monthly');
      await tester.ensureVisible(monthlyCard);
      await tester.pumpAndSettle();
      await tester.tap(monthlyCard);
      await tester.pumpAndSettle();

      // Scroll to make annual product visible and tap to select it
      final annualCard = find.text('Annual');
      await tester.ensureVisible(annualCard);
      await tester.pumpAndSettle();
      await tester.tap(annualCard);
      await tester.pumpAndSettle();

      expect(find.text('Start Free Trial'), findsOneWidget);
    });
  });
}

// Mock notifier for testing
class MockMonetizationNotifier extends StateNotifier<MonetizationState>
    implements MonetizationNotifier {
  MockMonetizationNotifier(super.initialState);

  @override
  Future<void> purchase(String productId) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> loadProducts() async {}

  @override
  Future<void> refreshEntitlement() async {}

  @override
  void clearPurchaseResult() {}
}

// Test data

final _mockProducts = [
  Product(
    id: ProductConfig.monthlySubscriptionId,
    type: ProductType.monthlySubscription,
    title: 'Pro Monthly',
    description: 'Monthly subscription',
    price: '\$2.99',
    currencyCode: 'USD',
    rawPrice: 2.99,
    billingPeriod: 'P1M',
  ),
  Product(
    id: ProductConfig.annualSubscriptionId,
    type: ProductType.annualSubscription,
    title: 'Pro Annual',
    description: 'Annual subscription',
    price: '\$19.99',
    currencyCode: 'USD',
    rawPrice: 19.99,
    billingPeriod: 'P1Y',
    freeTrialDuration: '7 days',
    savingsPercent: 44,
  ),
  Product(
    id: ProductConfig.lifetimeProductId,
    type: ProductType.lifetime,
    title: 'Pro Lifetime',
    description: 'One-time purchase',
    price: '\$49.99',
    currencyCode: 'USD',
    rawPrice: 49.99,
  ),
];
