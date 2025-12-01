# Monetization Configuration Guide

This guide covers the configuration steps required to enable in-app purchases for Kylos IPTV Player across Google Play, App Store, and Amazon Appstore.

## Table of Contents

1. [Overview](#overview)
2. [Product IDs Configuration](#product-ids-configuration)
3. [Google Play Console Setup](#google-play-console-setup)
4. [App Store Connect Setup](#app-store-connect-setup)
5. [Amazon Appstore Setup](#amazon-appstore-setup)
6. [Firebase Cloud Functions Setup](#firebase-cloud-functions-setup)
7. [Testing In-App Purchases](#testing-in-app-purchases)
8. [Production Checklist](#production-checklist)

---

## Overview

Kylos IPTV Player uses a freemium model with three subscription tiers:

| Tier | Price | Billing |
|------|-------|---------|
| Pro Monthly | $2.99/month | Auto-renewing subscription |
| Pro Annual | $19.99/year | Auto-renewing subscription with 7-day free trial |
| Pro Lifetime | $49.99 | One-time purchase (non-consumable) |

The client-side implementation uses:
- **Flutter `in_app_purchase` plugin** for cross-platform IAP handling
- **Firebase Cloud Functions** for server-side receipt verification
- **Firestore** for storing entitlements

---

## Product IDs Configuration

Before configuring stores, update the product IDs in your codebase:

### File: `lib/features/monetization/domain/product_config.dart`

```dart
abstract class ProductConfig {
  // TODO: Replace with your actual product IDs from each store
  static const String monthlySubscriptionId = 'kylos_pro_monthly';
  static const String annualSubscriptionId = 'kylos_pro_annual';
  static const String lifetimeProductId = 'kylos_pro_lifetime';

  // ...
}
```

> **Important**: Product IDs must match exactly between your code and the store configurations.

---

## Google Play Console Setup

### Prerequisites
- Google Play Developer account ($25 one-time fee)
- App uploaded with at least an internal test track release
- Payment profile configured

### Step 1: Create Products

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app → **Monetize** → **Products** → **Subscriptions**

#### Monthly Subscription
1. Click **Create subscription**
2. **Product ID**: `kylos_pro_monthly`
3. **Name**: Kylos Pro Monthly
4. **Description**: Monthly subscription to Kylos Pro features
5. Click **Add a base plan**:
   - **Base plan ID**: `monthly-base`
   - **Renewal type**: Auto-renewing
   - **Billing period**: 1 month
   - **Price**: $2.99 USD (configure for other regions)
6. **Activate** the base plan
7. **Save** and **Activate** the subscription

#### Annual Subscription
1. Click **Create subscription**
2. **Product ID**: `kylos_pro_annual`
3. **Name**: Kylos Pro Annual
4. **Description**: Annual subscription with 7-day free trial
5. Click **Add a base plan**:
   - **Base plan ID**: `annual-base`
   - **Renewal type**: Auto-renewing
   - **Billing period**: 1 year
   - **Price**: $19.99 USD
6. Click **Add offer** → **Free trial**:
   - **Offer ID**: `annual-trial`
   - **Eligibility**: New customers only
   - **Duration**: 7 days
7. **Activate** the base plan and offer
8. **Save** and **Activate** the subscription

#### Lifetime Purchase
1. Go to **Monetize** → **Products** → **In-app products**
2. Click **Create product**
3. **Product ID**: `kylos_pro_lifetime`
4. **Name**: Kylos Pro Lifetime
5. **Description**: One-time purchase for lifetime Pro access
6. **Price**: $49.99 USD
7. **Save** and **Activate**

### Step 2: Configure Licensing

1. Go to **Monetize** → **Monetization setup**
2. Note your **License Key** (Base64 RSA public key)
3. Add license testers:
   - Go to **License testing**
   - Add Gmail addresses of your test accounts
   - Set license response to **RESPOND_NORMALLY** for testing

### Step 3: Server-Side Verification Setup

1. Go to **Setup** → **API access**
2. Create/link a Google Cloud project
3. Create a service account with permissions:
   - **Android Publisher API** access
4. Download the JSON key file
5. Store securely for Cloud Functions (see Firebase setup)

### Google Play Billing Library Version

The `in_app_purchase_android` plugin uses Billing Library 6.x. Ensure your app's `build.gradle` is compatible:

```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34
    // ...
}
```

---

## App Store Connect Setup

### Prerequisites
- Apple Developer Program membership ($99/year)
- App created in App Store Connect
- Bundle ID registered in Apple Developer portal
- Banking and tax forms completed

### Step 1: Create App Store Connect Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **My Apps** → Your app
3. Go to **App Store** tab → **App Information**
4. Ensure your app category and bundle ID are correct

### Step 2: Configure In-App Purchases

Navigate to **Monetization** → **Subscriptions**

#### Create Subscription Group
1. Click **+** to create a subscription group
2. **Reference Name**: Kylos Pro
3. **Subscription Group Localization**: Add display name for App Store

#### Monthly Subscription
1. Click **Create** within the subscription group
2. **Reference Name**: Pro Monthly
3. **Product ID**: `kylos_pro_monthly`
4. **Subscription Duration**: 1 Month
5. **Subscription Price**: $2.99 (Tier 3)
6. Add **Localizations**:
   - Display Name: Pro Monthly
   - Description: Monthly subscription to Kylos Pro
7. Add **Review Information**:
   - Screenshot of paywall
   - Review notes explaining the subscription
8. Click **Save**

#### Annual Subscription
1. Click **Create** within the subscription group
2. **Reference Name**: Pro Annual
3. **Product ID**: `kylos_pro_annual`
4. **Subscription Duration**: 1 Year
5. **Subscription Price**: $19.99 (Tier 20)
6. Add **Promotional Offers** → **Introductory Offer**:
   - Type: Free trial
   - Duration: 1 Week
7. Add **Localizations** and **Review Information**
8. Click **Save**

#### Lifetime Purchase (Non-Consumable)
1. Go to **Monetization** → **In-App Purchases**
2. Click **+** → **Non-Consumable**
3. **Reference Name**: Pro Lifetime
4. **Product ID**: `kylos_pro_lifetime`
5. **Price**: $49.99 (Tier 50)
6. Add **Localizations** and **Review Information**
7. Click **Save**

### Step 3: App Store Server Notifications

1. Go to **App Information** → **App Store Server Notifications**
2. **Production Server URL**: `https://your-region-your-project.cloudfunctions.net/handleAppStoreNotification`
3. **Sandbox Server URL**: Same URL (handle sandbox in Cloud Function)
4. **Version**: Version 2 (recommended)

### Step 4: App-Specific Shared Secret

1. Go to **App Information** → **Manage** under Shared Secret
2. Generate or view your shared secret
3. Store securely for Cloud Functions verification

### Step 5: StoreKit Configuration (for Testing)

For local testing without sandbox accounts:

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Under **Run** → **Options**, set **StoreKit Configuration** to a local file
3. Create a StoreKit Configuration file in Xcode with your products

Alternatively, use sandbox testers:
1. Go to **Users and Access** → **Sandbox** → **Testers**
2. Create sandbox tester accounts

---

## Amazon Appstore Setup

### Prerequisites
- Amazon Developer account (free)
- App registered in Amazon Developer Portal

### Step 1: Create In-App Items

1. Go to [Amazon Developer Console](https://developer.amazon.com)
2. Select your app → **In-App Items**

#### Monthly Subscription
1. Click **Add a Subscription**
2. **Title**: Pro Monthly
3. **SKU**: `kylos_pro_monthly`
4. **Subscription Period**: Monthly
5. **Free Trial**: No
6. **List Price**: $2.99
7. Add description and icons
8. **Submit**

#### Annual Subscription
1. Click **Add a Subscription**
2. **Title**: Pro Annual
3. **SKU**: `kylos_pro_annual`
4. **Subscription Period**: Annually
5. **Free Trial**: Yes, 7 days
6. **List Price**: $19.99
7. Add description and icons
8. **Submit**

#### Lifetime Purchase
1. Click **Add an Entitlement**
2. **Title**: Pro Lifetime
3. **SKU**: `kylos_pro_lifetime`
4. **List Price**: $49.99
5. Add description and icons
6. **Submit**

### Step 2: Configure Receipt Verification

1. Go to **Apps & Services** → **Security Profiles**
2. Create a security profile if needed
3. Note your **Shared Key** for RVS (Receipt Verification Service)

### Step 3: Implement Amazon-Specific Code

The base `in_app_purchase` plugin has basic Amazon support. For full Amazon App Store support, consider adding `amazon_iap` package and implementing a separate `AmazonBillingService` that implements the `BillingService` interface.

---

## Firebase Cloud Functions Setup

Server-side verification is critical for security. Here's how to set up Cloud Functions:

### Step 1: Initialize Cloud Functions

```bash
cd firebase/functions
npm init
npm install firebase-functions firebase-admin
npm install google-auth-library  # For Google Play verification
npm install jsonwebtoken         # For App Store JWT
```

### Step 2: Create Verification Function

Create `functions/src/verifyPurchase.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface VerificationRequest {
  userId: string;
  productId: string;
  purchaseId: string;
  platform: 'google_play' | 'app_store' | 'amazon';
  receipt: string;
}

export const verifyPurchase = functions.firestore
  .document('purchase_verifications/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() as VerificationRequest;
    const docRef = snap.ref;

    try {
      let isValid = false;
      let expiresAt: Date | null = null;
      let isTrialPeriod = false;

      switch (data.platform) {
        case 'google_play':
          const gpResult = await verifyGooglePlay(data);
          isValid = gpResult.isValid;
          expiresAt = gpResult.expiresAt;
          isTrialPeriod = gpResult.isTrialPeriod;
          break;

        case 'app_store':
          const asResult = await verifyAppStore(data);
          isValid = asResult.isValid;
          expiresAt = asResult.expiresAt;
          isTrialPeriod = asResult.isTrialPeriod;
          break;

        case 'amazon':
          const amzResult = await verifyAmazon(data);
          isValid = amzResult.isValid;
          expiresAt = amzResult.expiresAt;
          break;

        default:
          throw new Error(`Unknown platform: ${data.platform}`);
      }

      if (isValid) {
        // Update user entitlement
        await updateEntitlement(data.userId, data.productId, expiresAt);

        // Mark verification as successful
        await docRef.update({
          status: 'verified',
          expiresAt: expiresAt?.toISOString(),
          isTrialPeriod,
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          status: 'failed',
          failureReason: 'Invalid receipt',
          shouldRetry: false,
        });
      }
    } catch (error) {
      console.error('Verification error:', error);
      await docRef.update({
        status: 'failed',
        failureReason: error.message,
        shouldRetry: true,
      });
    }
  });

async function verifyGooglePlay(data: VerificationRequest) {
  // Use Google Play Developer API to verify
  // See: https://developers.google.com/android-publisher/api-ref/rest

  // Implementation depends on subscription vs one-time purchase
  // Return { isValid, expiresAt, isTrialPeriod }
}

async function verifyAppStore(data: VerificationRequest) {
  // Use App Store Server API
  // See: https://developer.apple.com/documentation/appstoreserverapi

  // For StoreKit 2, verify JWS signed transactions
  // Return { isValid, expiresAt, isTrialPeriod }
}

async function verifyAmazon(data: VerificationRequest) {
  // Use Amazon RVS (Receipt Verification Service)
  // See: https://developer.amazon.com/docs/in-app-purchasing/iap-rvs-for-android-apps.html

  // Return { isValid, expiresAt }
}

async function updateEntitlement(
  userId: string,
  productId: string,
  expiresAt: Date | null
) {
  const tier = productIdToTier(productId);

  await admin.firestore()
    .collection('entitlements')
    .doc(userId)
    .set({
      userId,
      currentTier: tier,
      expiresAt: expiresAt?.toISOString(),
      isActive: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
}

function productIdToTier(productId: string): string {
  switch (productId) {
    case 'kylos_pro_monthly':
      return 'pro_monthly';
    case 'kylos_pro_annual':
      return 'pro_annual';
    case 'kylos_pro_lifetime':
      return 'pro_lifetime';
    default:
      return 'free';
  }
}
```

### Step 3: Handle Store Notifications

Create webhook handlers for real-time subscription events:

```typescript
// Google Play Real-time Developer Notifications
export const handlePlayNotification = functions.https.onRequest(async (req, res) => {
  // Verify notification authenticity
  // Process subscription state changes
  // Update entitlements accordingly
});

// App Store Server Notifications V2
export const handleAppStoreNotification = functions.https.onRequest(async (req, res) => {
  // Verify JWS signature
  // Process notification type (SUBSCRIBED, EXPIRED, etc.)
  // Update entitlements accordingly
});
```

### Step 4: Store Secrets Securely

```bash
# Google Play service account
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT

# App Store shared secret
firebase functions:secrets:set APP_STORE_SHARED_SECRET

# Amazon shared key
firebase functions:secrets:set AMAZON_SHARED_KEY
```

### Step 5: Deploy Functions

```bash
firebase deploy --only functions
```

---

## Testing In-App Purchases

### Android Testing

1. **License Testing**: Add Gmail accounts to license testers in Play Console
2. **Internal Testing Track**: Upload APK and add testers
3. **Test Cards**: Google provides test card numbers for sandbox

```dart
// Debug mode detection for test purchases
if (kDebugMode) {
  // Products may return test prices
}
```

### iOS Testing

1. **Sandbox Testers**: Create in App Store Connect
2. **Sign out of App Store** on device, sign in with sandbox account
3. **Xcode StoreKit Testing**: Use local configuration file

### Amazon Testing

1. **App Tester Tool**: Install Amazon App Tester on device
2. **JSON Configuration**: Create test IAP responses
3. **Sandbox Mode**: Enable in developer settings

---

## Production Checklist

### Before Release

- [ ] **Product IDs** match across code and all stores
- [ ] **Prices** are consistent (accounting for currency conversion)
- [ ] **Free trial** periods match in code and store configuration
- [ ] **Cloud Functions** deployed and tested
- [ ] **Webhook URLs** configured in store dashboards
- [ ] **Error handling** tested for network failures
- [ ] **Restore purchases** works correctly
- [ ] **Entitlement sync** verified between client and server
- [ ] **Subscription cancellation** flow tested
- [ ] **Grace periods** configured appropriately

### Store-Specific

#### Google Play
- [ ] Subscription products activated
- [ ] In-app products activated
- [ ] Real-time Developer Notifications configured
- [ ] Service account permissions set

#### App Store
- [ ] Products submitted for review
- [ ] Introductory offers configured
- [ ] Server notifications v2 URL set
- [ ] Shared secret stored securely

#### Amazon
- [ ] IAP items submitted
- [ ] RVS shared key configured
- [ ] Live app testing completed

### Security

- [ ] Receipt verification happens server-side
- [ ] Entitlements stored in Firestore with security rules
- [ ] No client-side validation bypasses
- [ ] Secrets not hardcoded in app

### Legal

- [ ] Subscription terms displayed in paywall
- [ ] Privacy policy updated for IAP data
- [ ] Restore purchases button present
- [ ] Price and billing cycle clearly shown

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Products not loading | Store not configured | Verify product IDs and activation status |
| Purchase fails immediately | License tester not added | Add account to license testing |
| Verification timeout | Cloud Function slow | Increase timeout or optimize |
| Entitlement not updating | Webhook not received | Check webhook URL configuration |
| iOS purchase pending | Sandbox account issue | Create new sandbox tester |

### Debug Logging

Enable verbose logging in development:

```dart
// In IapBillingService
if (kDebugMode) {
  print('IAP: Purchase details: $purchaseDetails');
  print('IAP: Verification data: ${purchaseDetails.verificationData}');
}
```

### Support Resources

- [Flutter in_app_purchase Documentation](https://pub.dev/packages/in_app_purchase)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [App Store In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Amazon IAP Documentation](https://developer.amazon.com/docs/in-app-purchasing/iap-overview.html)

---

## Summary

This guide covered the complete setup for monetization across three major app stores. Key points:

1. **Product IDs** must be consistent across your code and all store configurations
2. **Server-side verification** is essential for security
3. **Testing** should be thorough using each store's sandbox environment
4. **Webhooks** enable real-time subscription state synchronization
5. **Error handling** should gracefully handle network issues and store unavailability

For questions or issues, refer to the official documentation or the project's issue tracker.
