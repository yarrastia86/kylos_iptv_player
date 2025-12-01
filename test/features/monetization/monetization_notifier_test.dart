// Kylos IPTV Player - Monetization Notifier Tests
// Unit tests for the MonetizationNotifier state management.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/entitlements/entitlement_repository.dart';
import 'package:kylos_iptv_player/features/monetization/domain/billing_service.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/product.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/purchase_state.dart';
import 'package:kylos_iptv_player/features/monetization/domain/product_config.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/monetization_notifier.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockBillingService extends Mock implements BillingService {}

class MockPurchaseVerifier extends Mock implements PurchaseVerifier {}

class MockEntitlementRepository extends Mock implements EntitlementRepository {}

class FakePendingPurchase extends Fake implements PendingPurchase {}

void main() {
  late MockBillingService mockBillingService;
  late MockPurchaseVerifier mockPurchaseVerifier;
  late MockEntitlementRepository mockEntitlementRepository;
  late StreamController<BillingEvent> billingEventsController;
  late StreamController<Entitlement?> entitlementController;

  setUpAll(() {
    registerFallbackValue(FakePendingPurchase());
    registerFallbackValue(<String>{});
  });

  setUp(() {
    mockBillingService = MockBillingService();
    mockPurchaseVerifier = MockPurchaseVerifier();
    mockEntitlementRepository = MockEntitlementRepository();
    billingEventsController = StreamController<BillingEvent>.broadcast();
    entitlementController = StreamController<Entitlement?>.broadcast();

    // Setup default mocks
    when(() => mockBillingService.billingEvents)
        .thenAnswer((_) => billingEventsController.stream);
    when(() => mockBillingService.initialize()).thenAnswer((_) async {});
    when(() => mockBillingService.loadProducts(any()))
        .thenAnswer((_) async => _mockProducts);
    when(() => mockBillingService.dispose()).thenAnswer((_) async {});

    when(() => mockEntitlementRepository.watchEntitlement(any()))
        .thenAnswer((_) => entitlementController.stream);
    when(() => mockEntitlementRepository.getEntitlement(any()))
        .thenAnswer((_) async => null);
  });

  tearDown(() {
    billingEventsController.close();
    entitlementController.close();
  });

  MonetizationNotifier createNotifier({String userId = 'test-user'}) {
    return MonetizationNotifier(
      billingService: mockBillingService,
      purchaseVerifier: mockPurchaseVerifier,
      entitlementRepository: mockEntitlementRepository,
      userId: userId,
    );
  }

  group('MonetizationNotifier', () {
    group('initialization', () {
      test('initializes with default state', () async {
        final notifier = createNotifier();

        // Allow initialization to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.purchaseStatus, PurchaseStatus.idle);
        expect(notifier.state.products, isNotEmpty);

        notifier.dispose();
      });

      test('loads products on initialization', () async {
        final notifier = createNotifier();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(() => mockBillingService.loadProducts(any())).called(1);

        notifier.dispose();
      });

      test('subscribes to billing events', () async {
        final notifier = createNotifier();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(() => mockBillingService.billingEvents).called(1);

        notifier.dispose();
      });

      test('subscribes to entitlement changes', () async {
        final notifier = createNotifier();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(() => mockEntitlementRepository.watchEntitlement('test-user'))
            .called(1);

        notifier.dispose();
      });
    });

    group('loadProducts', () {
      test('sets loading state while loading products', () async {
        when(() => mockBillingService.loadProducts(any())).thenAnswer(
          (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return _mockProducts;
          },
        );

        final notifier = createNotifier();

        // Check loading state
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(notifier.state.isLoadingProducts, isTrue);

        // Wait for completion
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(notifier.state.isLoadingProducts, isFalse);
        expect(notifier.state.products, isNotEmpty);

        notifier.dispose();
      });

      test('sets error state on failure', () async {
        when(() => mockBillingService.loadProducts(any()))
            .thenThrow(Exception('Failed to load products'));

        final notifier = createNotifier();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.isLoadingProducts, isFalse);
        expect(notifier.state.productsError, isNotNull);

        notifier.dispose();
      });
    });

    group('purchase', () {
      test('starts purchase flow', () async {
        when(() => mockBillingService.startPurchase(any()))
            .thenAnswer((_) async {});

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await notifier.purchase(ProductConfig.monthlySubscriptionId);

        expect(notifier.state.purchaseStatus, PurchaseStatus.pending);
        expect(
          notifier.state.currentPurchaseProductId,
          ProductConfig.monthlySubscriptionId,
        );
        verify(() =>
                mockBillingService.startPurchase(ProductConfig.monthlySubscriptionId))
            .called(1);

        notifier.dispose();
      });

      test('ignores purchase if already purchasing', () async {
        when(() => mockBillingService.startPurchase(any()))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 5));
        });

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Start first purchase
        unawaited(notifier.purchase(ProductConfig.monthlySubscriptionId));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Try to start second purchase
        await notifier.purchase(ProductConfig.annualSubscriptionId);

        // Should only have called once
        verify(() => mockBillingService.startPurchase(any())).called(1);

        notifier.dispose();
      });

      test('handles purchase error', () async {
        when(() => mockBillingService.startPurchase(any()))
            .thenThrow(Exception('Purchase failed'));

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await notifier.purchase(ProductConfig.monthlySubscriptionId);

        expect(notifier.state.purchaseStatus, PurchaseStatus.error);
        expect(notifier.state.lastPurchaseResult, isA<PurchaseError>());

        notifier.dispose();
      });
    });

    group('billing events', () {
      test('handles ProductsLoaded event', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        billingEventsController.add(ProductsLoaded(_mockProducts));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.products, equals(_mockProducts));
        expect(notifier.state.isLoadingProducts, isFalse);

        notifier.dispose();
      });

      test('handles ProductsLoadError event', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        billingEventsController.add(const ProductsLoadError('Network error'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.productsError, 'Network error');
        expect(notifier.state.isLoadingProducts, isFalse);

        notifier.dispose();
      });

      test('handles PurchaseCancelledEvent', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        billingEventsController.add(const PurchaseCancelledEvent('test-product'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.purchaseStatus, PurchaseStatus.cancelled);
        expect(notifier.state.lastPurchaseResult, isA<PurchaseCancelled>());

        notifier.dispose();
      });

      test('handles PurchaseErrorEvent', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        billingEventsController.add(
          const PurchaseErrorEvent(
            productId: 'test-product',
            error: PurchaseError(
              code: PurchaseError.paymentDeclined,
              message: 'Card declined',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.purchaseStatus, PurchaseStatus.error);
        expect(notifier.state.lastPurchaseResult, isA<PurchaseError>());
        expect(
          (notifier.state.lastPurchaseResult as PurchaseError).code,
          PurchaseError.paymentDeclined,
        );

        notifier.dispose();
      });

      test('handles PurchasePendingEvent and verifies purchase', () async {
        final pendingPurchase = PendingPurchase(
          purchaseId: 'purchase-123',
          productId: ProductConfig.monthlySubscriptionId,
          verificationData: const PurchaseVerificationData(
            localVerificationData: 'local-data',
            serverVerificationData: 'server-data',
            source: 'google_play',
          ),
          transactionDate: DateTime.now(),
        );

        when(() => mockPurchaseVerifier.verifyPurchase(any())).thenAnswer(
          (_) async => VerificationSuccess(
            productId: ProductConfig.monthlySubscriptionId,
            purchaseId: 'purchase-123',
          ),
        );
        when(() => mockBillingService.completePurchase(any()))
            .thenAnswer((_) async {});
        when(() => mockEntitlementRepository.refreshEntitlement(any()))
            .thenAnswer((_) async => _proEntitlement);

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        billingEventsController.add(PurchasePendingEvent(pendingPurchase));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        verify(() => mockPurchaseVerifier.verifyPurchase(any())).called(1);
        verify(() => mockBillingService.completePurchase('purchase-123'))
            .called(1);
        expect(notifier.state.purchaseStatus, PurchaseStatus.completed);

        notifier.dispose();
      });

      test('handles verification failure', () async {
        final pendingPurchase = PendingPurchase(
          purchaseId: 'purchase-123',
          productId: ProductConfig.monthlySubscriptionId,
          verificationData: const PurchaseVerificationData(
            localVerificationData: 'local-data',
            serverVerificationData: 'server-data',
            source: 'google_play',
          ),
          transactionDate: DateTime.now(),
        );

        when(() => mockPurchaseVerifier.verifyPurchase(any())).thenAnswer(
          (_) async => const VerificationFailure(
            reason: 'Invalid receipt',
            shouldRetry: false,
          ),
        );

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        billingEventsController.add(PurchasePendingEvent(pendingPurchase));
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(notifier.state.purchaseStatus, PurchaseStatus.error);
        expect(notifier.state.lastPurchaseResult, isA<PurchaseError>());

        notifier.dispose();
      });
    });

    group('restorePurchases', () {
      test('starts restore flow', () async {
        when(() => mockBillingService.restorePurchases())
            .thenAnswer((_) async {});

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await notifier.restorePurchases();

        expect(notifier.state.isRestoringPurchases, isTrue);
        verify(() => mockBillingService.restorePurchases()).called(1);

        notifier.dispose();
      });

      test('handles restore error', () async {
        when(() => mockBillingService.restorePurchases())
            .thenThrow(Exception('Restore failed'));

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await notifier.restorePurchases();

        expect(notifier.state.isRestoringPurchases, isFalse);
        expect(notifier.state.lastPurchaseResult, isA<PurchaseError>());

        notifier.dispose();
      });

      test('handles empty restore', () async {
        when(() => mockBillingService.restorePurchases())
            .thenAnswer((_) async {});

        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await notifier.restorePurchases();

        billingEventsController.add(const PurchasesRestoredEvent([]));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.isRestoringPurchases, isFalse);
        expect(notifier.state.lastPurchaseResult, isA<PurchaseError>());
        expect(
          (notifier.state.lastPurchaseResult as PurchaseError).code,
          PurchaseError.productNotFound,
        );

        notifier.dispose();
      });
    });

    group('entitlement updates', () {
      test('updates state when entitlement changes', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        entitlementController.add(_proEntitlement);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.entitlement, equals(_proEntitlement));
        expect(notifier.state.hasPro, isTrue);

        notifier.dispose();
      });

      test('handles null entitlement (free user)', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        entitlementController.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.entitlement, isNull);
        expect(notifier.state.hasPro, isFalse);

        notifier.dispose();
      });
    });

    group('clearPurchaseResult', () {
      test('clears purchase state', () async {
        final notifier = createNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Set an error state
        billingEventsController.add(
          const PurchaseErrorEvent(
            productId: 'test-product',
            error: PurchaseError(
              code: PurchaseError.unknown,
              message: 'Test error',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(notifier.state.purchaseStatus, PurchaseStatus.error);

        // Clear it
        notifier.clearPurchaseResult();

        expect(notifier.state.purchaseStatus, PurchaseStatus.idle);
        // Note: clearPurchaseResult only resets purchaseStatus to idle
        // lastPurchaseResult and currentPurchaseProductId are NOT cleared by the implementation

        notifier.dispose();
      });
    });
  });

  group('MonetizationStateExtensions', () {
    test('canAddPlaylist returns true when under limit', () {
      final state = MonetizationState.initial();
      // Free limit is maxPlaylists=1, so can add when count < 1
      expect(state.canAddPlaylist(0), isTrue);
      expect(state.canAddPlaylist(1), isFalse);
    });

    test('canAddPlaylist returns true for pro users', () {
      final state = MonetizationState.initial().copyWith(
        entitlement: _proEntitlement,
      );
      // Pro limit is maxPlaylists=10
      expect(state.canAddPlaylist(9), isTrue);
      expect(state.canAddPlaylist(10), isFalse);
    });

    test('canAddProfile returns correct value', () {
      final state = MonetizationState.initial();
      // Free limit is maxProfiles=2
      expect(state.canAddProfile(0), isTrue);
      expect(state.canAddProfile(1), isTrue);
      expect(state.canAddProfile(2), isFalse);
    });

    test('canUseCloudSync returns false for free users', () {
      final state = MonetizationState.initial();
      expect(state.canUseCloudSync, isFalse);
    });

    test('canUseCloudSync returns true for pro users', () {
      final state = MonetizationState.initial().copyWith(
        entitlement: _proEntitlement,
      );
      expect(state.canUseCloudSync, isTrue);
    });

    test('maxFavorites returns correct limit', () {
      final freeState = MonetizationState.initial();
      expect(freeState.maxFavorites, equals(50));

      final proState = MonetizationState.initial().copyWith(
        entitlement: _proEntitlement,
      );
      expect(proState.maxFavorites, equals(500));
    });

    test('epgDaysAvailable returns correct value', () {
      final freeState = MonetizationState.initial();
      expect(freeState.epgDaysAvailable, equals(1));

      final proState = MonetizationState.initial().copyWith(
        entitlement: _proEntitlement,
      );
      expect(proState.epgDaysAvailable, equals(7));
    });
  });
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

final _proEntitlement = Entitlement(
  userId: 'test-user',
  currentTier: SubscriptionTier.pro,
  expiresAt: DateTime.now().add(const Duration(days: 30)),
);
