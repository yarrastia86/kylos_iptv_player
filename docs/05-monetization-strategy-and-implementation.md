# Kylos IPTV Player - Monetization Strategy and Implementation

## Document Version

| Version | Date       | Author          | Description                     |
|---------|------------|-----------------|--------------------------------|
| 1.0     | 2024-01-XX | Product Strategy| Initial monetization design     |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Monetization Models Analysis](#2-monetization-models-analysis)
3. [Recommended Strategy](#3-recommended-strategy)
4. [Technical Implementation](#4-technical-implementation)
5. [UX Patterns and Compliance](#5-ux-patterns-and-compliance)
6. [Flutter Implementation Guidelines](#6-flutter-implementation-guidelines)
7. [Revenue Projections](#7-revenue-projections)
8. [Appendices](#8-appendices)

---

## 1. Executive Summary

### Product Positioning

Kylos IPTV Player is a **media player utility** that allows users to play their own IPTV playlists. The app:
- Does NOT provide, sell, or host any IPTV content
- Does NOT endorse any specific IPTV provider
- Acts purely as a player/organizer for user-supplied M3U/Xtream playlists

This positioning is critical for store compliance and monetization strategy.

### Monetization Philosophy

| Principle | Implementation |
|-----------|----------------|
| Ethical | No dark patterns, clear value proposition |
| Store-compliant | Follow all Google, Apple, and Amazon guidelines |
| User-friendly | Generous free tier, fair upgrade prompts |
| Sustainable | Predictable recurring revenue over one-time |

### Recommended Model

**Freemium + Annual/Monthly Subscription** with a generous free tier and clear Pro value.

---

## 2. Monetization Models Analysis

### 2.1 Model A: Freemium + One-Time Purchase

#### Feature Breakdown

| Feature | Free | Pro (One-Time) |
|---------|------|----------------|
| Playlists | 1 | Unlimited |
| Profiles | 2 | 10 |
| Channels per playlist | 500 | Unlimited |
| EPG guide | 1 day | 7 days |
| Favorites | 50 | Unlimited |
| Cloud sync | No | Yes |
| Multi-device | No | Yes |
| Parental controls | Basic | Advanced |
| Player skins/themes | 1 | All |
| Picture-in-Picture | No | Yes |
| Chromecast | No | Yes |
| Priority support | No | Yes |

#### Pricing

- **Pro Unlock**: $14.99 (one-time)

#### Pros

- Simple for users to understand
- No recurring commitment concerns
- Higher conversion rate per paying user
- Works well for TV platforms where subscriptions are awkward

#### Cons

- No recurring revenue (requires constant new user acquisition)
- Harder to fund ongoing development
- No "relationship" with paying customers
- Refund abuse potential higher

#### Revenue Potential: Medium

```
Assumptions:
- 100K downloads/month
- 3% conversion to paid
- $14.99 one-time

Monthly revenue: 100,000 x 0.03 x $14.99 = $44,970
Annual revenue: ~$540K

After Year 1: Revenue dependent entirely on new downloads
```

---

### 2.2 Model B: Freemium + Subscription (Monthly/Annual)

#### Feature Breakdown

| Feature | Free | Pro Monthly | Pro Annual |
|---------|------|-------------|------------|
| Playlists | 1 | Unlimited | Unlimited |
| Profiles | 2 | 10 | 10 |
| Channels per playlist | 500 | Unlimited | Unlimited |
| EPG guide | 1 day | 7 days | 7 days |
| Favorites | 50 | Unlimited | Unlimited |
| Cloud sync | No | Yes | Yes |
| Multi-device restore | No | Yes | Yes |
| Parental controls | Basic | Advanced | Advanced |
| Player themes | 1 | All | All |
| Picture-in-Picture | No | Yes | Yes |
| Chromecast/AirPlay | No | Yes | Yes |
| Auto EPG refresh | Manual only | Automatic | Automatic |
| Playback history | 7 days | Unlimited | Unlimited |
| Priority support | No | Yes | Yes |
| Early access features | No | No | Yes |

#### Pricing

- **Pro Monthly**: $2.99/month
- **Pro Annual**: $19.99/year (save 44%)
- **7-day free trial** for annual plan

#### Pros

- Predictable recurring revenue (MRR/ARR)
- Higher lifetime value (LTV) per customer
- Sustainable funding for development
- Better customer relationship
- Annual plan reduces churn

#### Cons

- Lower initial conversion rate
- Subscription fatigue among users
- More complex to implement (renewals, cancellations)
- Grace period handling required

#### Revenue Potential: High

```
Assumptions:
- 100K MAU after Year 1
- 5% conversion to paid
- 70% annual, 30% monthly
- 15% annual churn, 8% monthly churn

Monthly subscribers: 100,000 x 0.05 x 0.30 = 1,500 at $2.99
Annual subscribers: 100,000 x 0.05 x 0.70 = 3,500 at $19.99

Monthly MRR: (1,500 x $2.99) + (3,500 x $19.99/12) = $4,485 + $5,830 = $10,315
Annual ARR: ~$124K

Year 2 with growth and retention:
- Lower acquisition cost (organic growth)
- Compounding subscriber base
- Estimated ARR: $200-300K
```

---

### 2.3 Model C: Ad-Supported Free + Ad-Free Pro

#### Feature Breakdown

| Feature | Free (Ads) | Pro (No Ads) |
|---------|------------|--------------|
| Playlists | 1 | Unlimited |
| Profiles | 2 | 10 |
| **Banner ads** | Yes | No |
| **Interstitial ads** | On channel change | No |
| **Pre-roll video ads** | 5-15 sec | No |
| EPG guide | 1 day | 7 days |
| Cloud sync | No | Yes |
| All other Pro features | No | Yes |

#### Pricing

- **Pro Monthly**: $2.99/month (ad-free + features)
- **Pro Annual**: $19.99/year

#### Ad Implementation

- Banner ads: Bottom of channel list screens
- Interstitials: After every 10 channel changes
- Pre-roll: 5-15 second video before playback starts (skippable after 5s)

#### Pros

- Revenue from non-paying users
- Stronger motivation to upgrade (ad annoyance)
- Higher overall revenue potential
- Works globally (ads available everywhere)

#### Cons

- **Significant UX degradation** for free users
- Risk of 1-star reviews ("too many ads")
- Ad networks may flag IPTV apps (content concerns)
- Complex ad mediation required
- May violate IPTV content provider ToS
- **Store review risk**: Ads in media players can be contentious

#### Revenue Potential: Medium-High (but risky)

```
Ad Revenue (100K MAU):
- DAU: ~30% of MAU = 30,000
- Ad impressions/user/day: ~5
- eCPM: ~$2-5 (media app)
- Daily ad revenue: 30,000 x 5 x $3.50 / 1000 = $525
- Monthly ad revenue: ~$15,750

Subscription revenue: ~$10,000 (same as Model B)
Total: ~$25,750/month

Risk: Ad network bans could eliminate this overnight
```

---

### 2.4 Model Comparison Matrix

| Criteria | Model A (One-Time) | Model B (Subscription) | Model C (Ads + Sub) |
|----------|-------------------|----------------------|-------------------|
| Revenue predictability | Low | High | Medium |
| User experience | Good | Good | Poor |
| Store compliance risk | Low | Low | Medium |
| Implementation complexity | Low | Medium | High |
| Customer LTV | Low | High | Medium |
| Churn management | N/A | Required | Required |
| Global availability | Yes | Yes | Varies |
| TV platform fit | Excellent | Good | Poor |
| Long-term sustainability | Poor | Excellent | Medium |

---

## 3. Recommended Strategy

### 3.1 Primary Model: Freemium + Subscription (Model B)

**Rationale:**

1. **Sustainable Revenue**: Recurring subscriptions provide predictable cash flow for ongoing development
2. **Store Compliance**: Clean monetization without ad-related complications
3. **User Trust**: No ads means better reviews and organic growth
4. **Fair Exchange**: Users pay for ongoing value (cloud sync, updates, support)
5. **TV Platform Fit**: Subscriptions work on Fire TV via Amazon accounts

### 3.2 Fallback Model: One-Time Purchase (Model A)

**When to use:**

- If subscription conversion is below 2% after 6 months
- If a specific platform (e.g., Fire TV) shows strong one-time preference
- As an alternative offer for users who explicitly refuse subscriptions

**Implementation**: Offer both options, with subscription as default/highlighted.

### 3.3 Final Feature Matrix

```
+------------------------------------------------------------------+
|                    KYLOS IPTV PLAYER TIERS                        |
+------------------------------------------------------------------+

FREE TIER (Kylos Basic)
├── 1 playlist source
├── 2 profiles
├── 500 channels max per playlist
├── 1-day EPG guide
├── 50 favorites
├── Manual EPG refresh
├── 7-day playback history
├── Basic parental controls (on/off)
├── Default player theme
├── Local storage only (no cloud)
└── Community support (forums)

PRO TIER (Kylos Pro)
├── Unlimited playlists
├── 10 profiles
├── Unlimited channels
├── 7-day EPG guide
├── Unlimited favorites
├── Auto EPG refresh (background)
├── Unlimited playback history
├── Advanced parental controls (PIN, ratings, time limits)
├── All player themes
├── Cloud backup & sync
├── Multi-device restore
├── Picture-in-Picture mode
├── Chromecast / AirPlay support
├── Priority email support
└── Early access to new features
```

### 3.4 Pricing Strategy

| Product | Price | Notes |
|---------|-------|-------|
| Pro Monthly | $2.99/month | No trial |
| Pro Annual | $19.99/year | 7-day free trial |
| Pro Lifetime | $49.99 | Limited availability |

**Regional Pricing:**
- US/Canada/EU: Full price
- Latin America: 50% discount
- India/Southeast Asia: 70% discount
- Other regions: 30-50% discount

**Lifetime Option:**
- Available as "hidden" option for users who explicitly ask
- Not promoted (to protect subscription revenue)
- Equivalent to ~2.5 years of annual subscription

---

## 4. Technical Implementation

### 4.1 Product Configuration

#### Google Play Billing

```
Product ID: kylos_pro_monthly
Type: Subscription
Base Plan ID: monthly-base
Billing Period: P1M
Price: $2.99 USD

Product ID: kylos_pro_annual
Type: Subscription
Base Plan ID: annual-base
Billing Period: P1Y
Price: $19.99 USD
Free Trial: P7D (7 days)

Product ID: kylos_pro_lifetime
Type: In-app product (non-consumable)
Price: $49.99 USD
```

**Google Play Console Setup:**

```json
// Subscription configuration
{
  "packageName": "com.kylos.iptvplayer",
  "subscriptions": [
    {
      "productId": "kylos_pro_monthly",
      "basePlans": [
        {
          "basePlanId": "monthly-base",
          "regionalConfigs": [
            {
              "regionCode": "US",
              "price": {
                "currencyCode": "USD",
                "units": "2",
                "nanos": 990000000
              }
            }
          ],
          "autoRenewingBasePlanType": {
            "billingPeriodDuration": "P1M",
            "gracePeriodDuration": "P3D",
            "resubscribeState": "RESUBSCRIBE_STATE_ACTIVE",
            "accountHoldDuration": "P30D"
          }
        }
      ]
    },
    {
      "productId": "kylos_pro_annual",
      "basePlans": [
        {
          "basePlanId": "annual-base",
          "regionalConfigs": [
            {
              "regionCode": "US",
              "price": {
                "currencyCode": "USD",
                "units": "19",
                "nanos": 990000000
              }
            }
          ],
          "autoRenewingBasePlanType": {
            "billingPeriodDuration": "P1Y",
            "gracePeriodDuration": "P7D",
            "resubscribeState": "RESUBSCRIBE_STATE_ACTIVE"
          },
          "offers": [
            {
              "offerId": "free-trial",
              "offerTags": ["trial"],
              "phases": [
                {
                  "phaseDuration": "P7D",
                  "pricingType": "PRICING_TYPE_FREE"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

#### Apple App Store (StoreKit 2)

```
Product ID: kylos_pro_monthly
Type: Auto-Renewable Subscription
Subscription Group: Kylos Pro
Duration: 1 Month
Price: $2.99 USD

Product ID: kylos_pro_annual
Type: Auto-Renewable Subscription
Subscription Group: Kylos Pro
Duration: 1 Year
Price: $19.99 USD
Introductory Offer: Free Trial, 7 days

Product ID: kylos_pro_lifetime
Type: Non-Consumable
Price: $49.99 USD
```

**App Store Connect Configuration:**

```swift
// StoreKit configuration file (for testing)
{
  "identifier": "com.kylos.iptvplayer.storekit",
  "subscriptions": [
    {
      "id": "kylos_pro_monthly",
      "type": "auto-renewable",
      "referenceName": "Kylos Pro Monthly",
      "subscriptionGroupID": "kylos_pro_group",
      "subscriptionPeriod": "P1M",
      "localizations": [
        {
          "locale": "en_US",
          "displayName": "Kylos Pro Monthly",
          "description": "Unlock all premium features with monthly billing"
        }
      ],
      "prices": [
        {
          "price": "2.99",
          "locale": "en_US"
        }
      ]
    },
    {
      "id": "kylos_pro_annual",
      "type": "auto-renewable",
      "referenceName": "Kylos Pro Annual",
      "subscriptionGroupID": "kylos_pro_group",
      "subscriptionPeriod": "P1Y",
      "introductoryOffer": {
        "type": "free",
        "duration": "P7D"
      },
      "localizations": [
        {
          "locale": "en_US",
          "displayName": "Kylos Pro Annual",
          "description": "Best value! Save 44% with annual billing"
        }
      ],
      "prices": [
        {
          "price": "19.99",
          "locale": "en_US"
        }
      ]
    }
  ],
  "products": [
    {
      "id": "kylos_pro_lifetime",
      "type": "non-consumable",
      "referenceName": "Kylos Pro Lifetime",
      "localizations": [
        {
          "locale": "en_US",
          "displayName": "Kylos Pro Lifetime",
          "description": "One-time purchase for permanent Pro access"
        }
      ],
      "prices": [
        {
          "price": "49.99",
          "locale": "en_US"
        }
      ]
    }
  ]
}
```

#### Amazon Appstore

```
Product ID: kylos_pro_monthly_amazon
Type: Subscription
Term: Monthly
Price: $2.99 USD

Product ID: kylos_pro_annual_amazon
Type: Subscription
Term: Annual
Price: $19.99 USD

Product ID: kylos_pro_lifetime_amazon
Type: Entitlement
Price: $49.99 USD
```

**Amazon IAP Configuration (JSON):**

```json
{
  "amazonIAP": {
    "products": [
      {
        "sku": "kylos_pro_monthly_amazon",
        "type": "SUBSCRIPTION",
        "title": "Kylos Pro Monthly",
        "description": "Unlock all premium features",
        "subscriptionPeriod": "Monthly",
        "freeTrialPeriod": null,
        "price": 2.99
      },
      {
        "sku": "kylos_pro_annual_amazon",
        "type": "SUBSCRIPTION",
        "title": "Kylos Pro Annual",
        "description": "Best value - Save 44%",
        "subscriptionPeriod": "Annually",
        "freeTrialPeriod": "7 Days",
        "price": 19.99
      },
      {
        "sku": "kylos_pro_lifetime_amazon",
        "type": "ENTITLEMENT",
        "title": "Kylos Pro Lifetime",
        "description": "One-time purchase for permanent access",
        "price": 49.99
      }
    ]
  }
}
```

### 4.2 Backend Data Model

Extending the previously defined Firestore schema:

```json
// Document: /entitlements/{userId}
{
  "userId": "abc123xyz",

  // Current active entitlement
  "currentTier": "pro",                      // free | pro
  "currentPlatform": "google_play",          // google_play | app_store | amazon | promo
  "currentProductId": "kylos_pro_annual",    // Active product

  // Expiration handling
  "expiresAt": "2025-01-15T10:30:00Z",       // Null for lifetime
  "graceEndAt": null,                        // Grace period end
  "accountHoldEndAt": null,                  // Account hold end (Google Play)

  // Lifetime flag
  "hasLifetime": false,

  // Trial tracking
  "trialUsed": true,
  "trialStartedAt": "2024-01-08T10:30:00Z",
  "trialEndedAt": "2024-01-15T10:30:00Z",

  // Cross-platform info
  "originalPurchasePlatform": "google_play",
  "linkedPlatforms": ["google_play"],        // Platforms with verified purchases

  // Promo/admin granted
  "promoGrantedAt": null,
  "promoExpiresAt": null,
  "promoReason": null,

  // Metadata
  "totalPurchases": 1,
  "totalSpent": { "USD": 19.99 },
  "firstPurchaseAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}

// Sub-collection: /entitlements/{userId}/purchases/{purchaseId}
{
  "id": "GPA.3374-1234-5678-90123",
  "platform": "google_play",

  // Identifiers
  "orderId": "GPA.3374-1234-5678-90123",
  "transactionId": null,                     // App Store
  "receiptId": null,                         // Amazon

  // Product
  "productId": "kylos_pro_annual",
  "basePlanId": "annual-base",               // Google Play
  "offerId": "free-trial",                   // Applied offer

  // Type
  "productType": "subscription",             // subscription | one_time
  "isTrialPeriod": false,
  "isIntroductoryPeriod": false,

  // Financial
  "price": 19.99,
  "currency": "USD",
  "priceAmountMicros": 19990000,

  // Dates
  "purchasedAt": "2024-01-15T10:30:00Z",
  "expiresAt": "2025-01-15T10:30:00Z",
  "originalPurchaseAt": "2024-01-15T10:30:00Z",

  // State
  "state": "active",                         // active | cancelled | expired | refunded | grace | hold | paused
  "autoRenew": true,
  "cancelledAt": null,
  "cancelReason": null,                      // user | billing | developer | replaced | unknown
  "refundedAt": null,
  "pausedAt": null,
  "resumeAt": null,

  // Verification
  "verifiedAt": "2024-01-15T10:30:05Z",
  "lastVerifiedAt": "2024-01-20T06:00:00Z",
  "verificationSource": "rtdn",              // cloud_function | rtdn | webhook | manual

  // Renewal tracking
  "renewalCount": 0,
  "lastRenewalAt": null,
  "nextRenewalAt": "2025-01-15T10:30:00Z",

  // Encrypted raw data (for auditing)
  "rawReceiptEncrypted": "...",

  // Metadata
  "deviceId": "device_abc123",
  "appVersion": "1.2.3",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:05Z"
}
```

### 4.3 Purchase Flow

```
+------------------------------------------------------------------+
|                      PURCHASE FLOW DIAGRAM                        |
+------------------------------------------------------------------+

User taps "Upgrade"
        |
        v
+------------------+
| Show Paywall UI  |
| (Product options)|
+------------------+
        |
        v
User selects product
        |
        v
+------------------+
| Platform Store   |
| Payment Sheet    |
+------------------+
        |
        +-------- Payment Failed ---------> Show Error, Retry Option
        |
        v
Payment Successful (Store returns receipt/token)
        |
        v
+------------------+
| Send to Backend  |
| Cloud Function   |
| verifyPurchase() |
+------------------+
        |
        +-------- Verification Failed ----> Retry, Manual Review
        |
        v
+------------------+
| Backend Updates  |
| - entitlements   |
| - users.sub      |
| - purchases      |
+------------------+
        |
        v
+------------------+
| Client Receives  |
| Updated State    |
| (Firestore RT)   |
+------------------+
        |
        v
+------------------+
| UI Updates       |
| - Unlock Pro     |
| - Success Toast  |
| - Analytics      |
+------------------+
        |
        v
+------------------+
| Acknowledge      |
| Purchase (Store) |
+------------------+
        |
        v
       DONE
```

### 4.4 Restore Purchases Flow

```
+------------------------------------------------------------------+
|                   RESTORE PURCHASES FLOW                          |
+------------------------------------------------------------------+

User taps "Restore Purchases"
        |
        v
+------------------+
| Query Store for  |
| Past Purchases   |
+------------------+
        |
        +-------- No Purchases Found -----> Show "No purchases" message
        |
        v
Found N purchases
        |
        v
+------------------+
| For each purchase|
| Call Backend     |
| verifyPurchase() |
+------------------+
        |
        +-------- All Invalid ------------> Show "Unable to restore"
        |
        v
At least one valid
        |
        v
+------------------+
| Backend Updates  |
| Entitlements     |
+------------------+
        |
        v
+------------------+
| UI Shows         |
| "Restored!"      |
| Unlock Pro       |
+------------------+
        |
        v
       DONE

Note: On iOS, this triggers an App Store sign-in prompt.
      On Google Play, it queries purchases for the signed-in Google account.
      On Amazon, it requires the Amazon account linked to the Fire TV.
```

### 4.5 Server-Side Verification

```typescript
// functions/src/purchases/verifyAndStore.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface VerifyPurchaseRequest {
  platform: 'google_play' | 'app_store' | 'amazon';
  productId: string;
  purchaseToken?: string;      // Google Play
  receiptData?: string;        // App Store
  amazonUserId?: string;       // Amazon
  amazonReceiptId?: string;    // Amazon
}

interface VerifyPurchaseResponse {
  success: boolean;
  entitlement?: {
    tier: 'free' | 'pro';
    expiresAt: string | null;
    isLifetime: boolean;
  };
  error?: string;
}

export const verifyPurchase = functions.https.onCall(
  async (data: VerifyPurchaseRequest, context): Promise<VerifyPurchaseResponse> => {
    // 1. Validate authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;

    // 2. Verify with appropriate store
    let storeResult: StoreVerificationResult;

    switch (data.platform) {
      case 'google_play':
        storeResult = await verifyGooglePlay(data.productId, data.purchaseToken!);
        break;
      case 'app_store':
        storeResult = await verifyAppStore(data.receiptData!);
        break;
      case 'amazon':
        storeResult = await verifyAmazon(data.amazonUserId!, data.amazonReceiptId!);
        break;
      default:
        throw new functions.https.HttpsError('invalid-argument', 'Unknown platform');
    }

    if (!storeResult.valid) {
      return { success: false, error: storeResult.error };
    }

    // 3. Determine tier and expiration
    const tier = getTierFromProduct(data.productId);
    const isLifetime = isLifetimeProduct(data.productId);
    const expiresAt = isLifetime ? null : storeResult.expiresAt;

    // 4. Update Firestore
    const batch = admin.firestore().batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    // Create/update purchase record
    const purchaseRef = admin.firestore()
      .collection('entitlements')
      .doc(userId)
      .collection('purchases')
      .doc(storeResult.orderId);

    batch.set(purchaseRef, {
      id: storeResult.orderId,
      platform: data.platform,
      orderId: storeResult.orderId,
      productId: data.productId,
      productType: isLifetime ? 'one_time' : 'subscription',
      purchasedAt: storeResult.purchaseDate,
      expiresAt: expiresAt,
      price: storeResult.price,
      currency: storeResult.currency,
      state: 'active',
      autoRenew: storeResult.autoRenew,
      verifiedAt: now,
      lastVerifiedAt: now,
      verificationSource: 'cloud_function',
      rawReceiptEncrypted: encryptReceipt(storeResult.rawReceipt),
      createdAt: now,
      updatedAt: now,
    }, { merge: true });

    // Update main entitlements document
    const entitlementsRef = admin.firestore()
      .collection('entitlements')
      .doc(userId);

    batch.set(entitlementsRef, {
      currentTier: tier,
      currentPlatform: data.platform,
      currentProductId: data.productId,
      expiresAt: expiresAt,
      hasLifetime: isLifetime,
      graceEndAt: null,
      accountHoldEndAt: null,
      updatedAt: now,
      totalPurchases: admin.firestore.FieldValue.increment(1),
      [`totalSpent.${storeResult.currency}`]: admin.firestore.FieldValue.increment(storeResult.price || 0),
    }, { merge: true });

    // Update user document (denormalized)
    const userRef = admin.firestore().collection('users').doc(userId);
    batch.update(userRef, {
      'subscription.tier': tier,
      'subscription.expiresAt': expiresAt,
      'subscription.platform': data.platform,
      'subscription.autoRenew': storeResult.autoRenew,
    });

    await batch.commit();

    // 5. Log analytics event
    await logPurchaseEvent(userId, data.productId, data.platform, storeResult.price);

    return {
      success: true,
      entitlement: {
        tier,
        expiresAt: expiresAt?.toDate().toISOString() || null,
        isLifetime,
      },
    };
  }
);

function getTierFromProduct(productId: string): 'free' | 'pro' {
  const proProducts = [
    'kylos_pro_monthly',
    'kylos_pro_annual',
    'kylos_pro_lifetime',
    'kylos_pro_monthly_amazon',
    'kylos_pro_annual_amazon',
    'kylos_pro_lifetime_amazon',
  ];
  return proProducts.includes(productId) ? 'pro' : 'free';
}

function isLifetimeProduct(productId: string): boolean {
  return productId.includes('lifetime');
}
```

### 4.6 Handling Refunds and Cancellations

```typescript
// functions/src/webhooks/handleGooglePlayRTDN.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Google Play Real-time Developer Notifications (RTDN)
 *
 * Notification Types:
 * 1  - SUBSCRIPTION_RECOVERED
 * 2  - SUBSCRIPTION_RENEWED
 * 3  - SUBSCRIPTION_CANCELED
 * 4  - SUBSCRIPTION_PURCHASED
 * 5  - SUBSCRIPTION_ON_HOLD
 * 6  - SUBSCRIPTION_IN_GRACE_PERIOD
 * 7  - SUBSCRIPTION_RESTARTED
 * 8  - SUBSCRIPTION_PRICE_CHANGE_CONFIRMED
 * 9  - SUBSCRIPTION_DEFERRED
 * 10 - SUBSCRIPTION_PAUSED
 * 11 - SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED
 * 12 - SUBSCRIPTION_REVOKED
 * 13 - SUBSCRIPTION_EXPIRED
 */

export const handleGooglePlayRTDN = functions.pubsub
  .topic('play-rtdn')
  .onPublish(async (message) => {
    const data = JSON.parse(Buffer.from(message.data, 'base64').toString());
    const notification = data.subscriptionNotification;

    if (!notification) {
      functions.logger.warn('No subscription notification in message');
      return;
    }

    const { notificationType, purchaseToken, subscriptionId } = notification;

    functions.logger.info('RTDN received', { notificationType, subscriptionId });

    // Find user by purchase token
    const purchasesQuery = await admin.firestore()
      .collectionGroup('purchases')
      .where('platform', '==', 'google_play')
      .where('orderId', '==', purchaseToken.substring(0, 50))
      .limit(1)
      .get();

    if (purchasesQuery.empty) {
      functions.logger.warn('Purchase not found for RTDN');
      return;
    }

    const purchaseDoc = purchasesQuery.docs[0];
    const userId = purchaseDoc.ref.parent.parent!.id;

    const batch = admin.firestore().batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    switch (notificationType) {
      case 1: // RECOVERED
      case 2: // RENEWED
      case 7: // RESTARTED
        // Subscription is active again
        await handleSubscriptionActive(batch, userId, purchaseDoc.id, subscriptionId);
        break;

      case 3: // CANCELED
        // User canceled, but still has access until expiresAt
        batch.update(purchaseDoc.ref, {
          autoRenew: false,
          cancelledAt: now,
          cancelReason: 'user',
          state: 'cancelled',
          updatedAt: now,
        });
        batch.update(admin.firestore().collection('users').doc(userId), {
          'subscription.autoRenew': false,
        });
        break;

      case 5: // ON_HOLD
        // Payment failed, account on hold (up to 30 days)
        const holdEnd = new Date();
        holdEnd.setDate(holdEnd.getDate() + 30);

        batch.update(purchaseDoc.ref, {
          state: 'hold',
          updatedAt: now,
        });
        batch.update(admin.firestore().collection('entitlements').doc(userId), {
          accountHoldEndAt: admin.firestore.Timestamp.fromDate(holdEnd),
          updatedAt: now,
        });
        // User LOSES access during hold
        await downgradeUser(batch, userId);
        break;

      case 6: // IN_GRACE_PERIOD
        // Payment failed, grace period (keep access)
        const graceEnd = new Date();
        graceEnd.setDate(graceEnd.getDate() + 7);

        batch.update(purchaseDoc.ref, {
          state: 'grace',
          updatedAt: now,
        });
        batch.update(admin.firestore().collection('entitlements').doc(userId), {
          graceEndAt: admin.firestore.Timestamp.fromDate(graceEnd),
          updatedAt: now,
        });
        // Send push notification to update payment
        await sendPaymentFailedNotification(userId);
        break;

      case 10: // PAUSED
        // User paused subscription
        batch.update(purchaseDoc.ref, {
          state: 'paused',
          pausedAt: now,
          updatedAt: now,
        });
        // User loses access while paused
        await downgradeUser(batch, userId);
        break;

      case 12: // REVOKED (refund)
        batch.update(purchaseDoc.ref, {
          state: 'refunded',
          refundedAt: now,
          updatedAt: now,
        });
        await downgradeUser(batch, userId);
        functions.logger.warn('Subscription revoked (refund)', { userId });
        break;

      case 13: // EXPIRED
        batch.update(purchaseDoc.ref, {
          state: 'expired',
          updatedAt: now,
        });
        await downgradeUser(batch, userId);
        break;
    }

    await batch.commit();
  });

async function handleSubscriptionActive(
  batch: admin.firestore.WriteBatch,
  userId: string,
  purchaseId: string,
  productId: string
) {
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Re-verify with Google Play to get latest expiry
  const verificationResult = await verifyGooglePlaySubscription(productId, purchaseId);

  batch.update(
    admin.firestore().collection('entitlements').doc(userId).collection('purchases').doc(purchaseId),
    {
      state: 'active',
      autoRenew: verificationResult.autoRenew,
      expiresAt: verificationResult.expiresAt,
      lastRenewalAt: now,
      renewalCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    }
  );

  batch.update(admin.firestore().collection('entitlements').doc(userId), {
    currentTier: 'pro',
    expiresAt: verificationResult.expiresAt,
    graceEndAt: null,
    accountHoldEndAt: null,
    updatedAt: now,
  });

  batch.update(admin.firestore().collection('users').doc(userId), {
    'subscription.tier': 'pro',
    'subscription.expiresAt': verificationResult.expiresAt,
    'subscription.autoRenew': verificationResult.autoRenew,
  });
}

async function downgradeUser(batch: admin.firestore.WriteBatch, userId: string) {
  batch.update(admin.firestore().collection('entitlements').doc(userId), {
    currentTier: 'free',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.update(admin.firestore().collection('users').doc(userId), {
    'subscription.tier': 'free',
    'subscription.autoRenew': false,
  });
}
```

---

## 5. UX Patterns and Compliance

### 5.1 Paywall Placement Strategy

```
+------------------------------------------------------------------+
|                    PAYWALL PLACEMENT MAP                          |
+------------------------------------------------------------------+

SOFT GATES (informational, non-blocking)
├── Settings > Subscription status banner
├── Profile creation (after hitting free limit)
├── Playlist addition (after hitting free limit)
└── EPG guide (day 2+ locked with overlay)

HARD GATES (blocking access)
├── Cloud backup feature
├── Picture-in-Picture activation
├── Chromecast/AirPlay button
├── Advanced parental controls
└── Premium themes selection

CONTEXTUAL PROMPTS (shown at relevant moment)
├── After 7 days of use: "Enjoying Kylos? Unlock Pro"
├── After adding 50 favorites: "Unlock unlimited favorites"
├── After first playlist refresh fail: "Auto-refresh with Pro"
└── After viewing EPG day 1: "See the full week with Pro"

NEVER SHOW PAYWALL
├── During active playback
├── On first app open
├── More than once per session for same feature
└── When user has dismissed < 24 hours ago
```

### 5.2 Paywall Design

```
+------------------------------------------------------------------+
|                       PAYWALL SCREEN                              |
+------------------------------------------------------------------+

┌─────────────────────────────────────────────────────────────────┐
│  [X Close]                                                       │
│                                                                  │
│                    🎬 Kylos Pro                                  │
│                                                                  │
│     Unlock the full power of your IPTV experience               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ✓ Unlimited playlists & channels                       │    │
│  │  ✓ 7-day EPG guide with auto-refresh                    │    │
│  │  ✓ Cloud backup & multi-device sync                     │    │
│  │  ✓ Picture-in-Picture & Chromecast                      │    │
│  │  ✓ Advanced parental controls                           │    │
│  │  ✓ Priority support                                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │    MONTHLY          │  │    ANNUAL ⭐        │               │
│  │    $2.99/mo         │  │    $19.99/yr        │               │
│  │                     │  │    SAVE 44%         │               │
│  │                     │  │    7-day free trial │               │
│  └─────────────────────┘  └─────────────────────┘               │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           [ Start Free Trial ]                          │    │
│  │                 (then $19.99/year)                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│         [ Restore Purchases ]    [ Terms ]    [ Privacy ]        │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  ℹ️ Kylos is a media player app. We do not provide any          │
│     IPTV content. You must supply your own playlists.           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Store Compliance Guidelines

#### Apple App Store

| Requirement | Implementation |
|-------------|----------------|
| Clear pricing | Show localized price before purchase |
| Subscription terms | Display billing period and auto-renewal info |
| Restore purchases | Prominent "Restore Purchases" button |
| Cancel instructions | Link to Apple subscription management |
| Free trial clarity | "7-day free trial, then $X.XX/year" |
| No external payment | Only use StoreKit, no web payment links |

**Required Text (iOS):**
```
Payment will be charged to your Apple ID account at confirmation
of purchase. Subscription automatically renews unless canceled at
least 24 hours before the end of the current period. Your account
will be charged for renewal within 24 hours prior to the end of
the current period. You can manage and cancel your subscriptions
by going to your account settings on the App Store after purchase.
```

#### Google Play

| Requirement | Implementation |
|-------------|----------------|
| Price disclosure | Show price before purchase flow |
| Subscription disclosure | Clearly state auto-renewal |
| Grace period | Honor 3-7 day grace period |
| Account hold | Support 30-day account hold |
| Acknowledge purchases | Call acknowledgePurchase within 3 days |

**Required Text (Android):**
```
By subscribing, you agree to the subscription terms. Your subscription
will automatically renew and your payment method will be charged at
the start of each billing period unless you cancel. You can cancel
anytime in Google Play Store > Subscriptions.
```

#### Amazon Appstore

| Requirement | Implementation |
|-------------|----------------|
| Use Amazon IAP | No external payment for Fire TV |
| Receipt verification | Server-side RVS verification |
| Entitlement sync | Handle Amazon user ID mapping |

### 5.4 Content Disclaimer

**CRITICAL**: Always display this disclaimer prominently.

```
+------------------------------------------------------------------+
|                    CONTENT DISCLAIMER                             |
+------------------------------------------------------------------+

Location:
- App Store listing
- Onboarding screen
- Paywall screen
- About/Settings screen

Text:

"Kylos IPTV Player is a media player application that allows you
to play your own IPTV playlists (M3U, Xtream Codes API).

IMPORTANT: Kylos does NOT provide, sell, host, or endorse any
IPTV content or streaming services. You are solely responsible
for ensuring that any playlists you add are legally obtained
and that you have the right to access the content.

Kylos is not affiliated with any IPTV provider. We are a player
utility only, similar to VLC or other media players."
```

### 5.5 Avoiding Dark Patterns

| Dark Pattern | Compliant Alternative |
|--------------|----------------------|
| Hiding close button | Prominent [X] always visible |
| Confusing pricing | Clear "$X.XX/period" format |
| Pre-selected annual | No pre-selection, user chooses |
| Forced upsells | Max 1 contextual prompt per session |
| Hidden cancellation | Direct links to store subscription settings |
| Fake scarcity | Never use "Limited time!" unless true |
| Guilt tripping | Neutral "Maybe later" dismiss option |
| Bait and switch | Same features described in paywall as delivered |

---

## 6. Flutter Implementation Guidelines

### 6.1 Recommended Packages

```yaml
# pubspec.yaml

dependencies:
  # In-app purchases (cross-platform)
  in_app_purchase: ^3.1.0              # Official Flutter plugin
  # OR
  purchases_flutter: ^6.0.0            # RevenueCat (simpler, adds cost)

  # For direct store access (if needed)
  in_app_purchase_android: ^0.3.0      # Android-specific features
  in_app_purchase_storekit: ^0.3.0     # iOS-specific features

  # Amazon IAP (Fire TV)
  # No official Flutter plugin - use platform channels
```

### 6.2 Purchase Service Architecture

```dart
// lib/infrastructure/purchases/purchase_service.dart

import 'dart:async';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Platform-agnostic purchase service
abstract class PurchaseService {
  /// Initialize the purchase service
  Future<void> initialize();

  /// Dispose resources
  Future<void> dispose();

  /// Get available products
  Future<List<ProductDetails>> getProducts();

  /// Purchase a product
  Future<PurchaseResult> purchase(String productId);

  /// Restore previous purchases
  Future<List<PurchaseResult>> restorePurchases();

  /// Stream of purchase updates
  Stream<List<PurchaseDetails>> get purchaseStream;

  /// Current platform
  StorePlatform get platform;

  /// Factory to get appropriate implementation
  factory PurchaseService.create({
    required FirebaseFunctions functions,
  }) {
    if (Platform.isAndroid) {
      // Check if Fire TV
      if (_isFireTV()) {
        return AmazonPurchaseService(functions: functions);
      }
      return GooglePlayPurchaseService(functions: functions);
    } else if (Platform.isIOS) {
      return AppStorePurchaseService(functions: functions);
    }
    throw UnsupportedError('Platform not supported');
  }

  static bool _isFireTV() {
    // Detect Fire TV via platform channel or package info
    return false; // Implement actual detection
  }
}

enum StorePlatform {
  googlePlay,
  appStore,
  amazon,
}

class PurchaseResult {
  final bool success;
  final String? productId;
  final String? transactionId;
  final String? errorMessage;
  final PurchaseErrorCode? errorCode;

  const PurchaseResult({
    required this.success,
    this.productId,
    this.transactionId,
    this.errorMessage,
    this.errorCode,
  });

  factory PurchaseResult.success({
    required String productId,
    required String transactionId,
  }) {
    return PurchaseResult(
      success: true,
      productId: productId,
      transactionId: transactionId,
    );
  }

  factory PurchaseResult.error({
    required String message,
    PurchaseErrorCode? code,
  }) {
    return PurchaseResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }
}

enum PurchaseErrorCode {
  cancelled,
  paymentFailed,
  productNotFound,
  networkError,
  verificationFailed,
  unknown,
}
```

### 6.3 Google Play Implementation

```dart
// lib/infrastructure/purchases/google_play_purchase_service.dart

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'purchase_service.dart';

class GooglePlayPurchaseService implements PurchaseService {
  GooglePlayPurchaseService({required this.functions});

  final FirebaseFunctions functions;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const _productIds = {
    'kylos_pro_monthly',
    'kylos_pro_annual',
    'kylos_pro_lifetime',
  };

  @override
  StorePlatform get platform => StorePlatform.googlePlay;

  @override
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw PurchaseServiceException('Store not available');
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        // Log error
      },
    );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      throw PurchaseServiceException(response.error!.message);
    }

    if (response.notFoundIDs.isNotEmpty) {
      // Log missing products
    }

    return response.productDetails;
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final products = await getProducts();
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw PurchaseServiceException('Product not found'),
    );

    final purchaseParam = GooglePlayPurchaseParam(
      productDetails: product,
      applicationUserName: null, // Set if using user-specific purchases
    );

    final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

    if (!success) {
      return PurchaseResult.error(
        message: 'Purchase could not be initiated',
        code: PurchaseErrorCode.unknown,
      );
    }

    // Result will come via purchaseStream
    // Return pending result; actual result handled in _handlePurchaseUpdates
    return PurchaseResult(success: true, productId: productId);
  }

  @override
  Future<List<PurchaseResult>> restorePurchases() async {
    await _iap.restorePurchases();
    // Results come via purchaseStream
    return [];
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Show loading UI
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify with backend
          await _verifyAndDeliver(purchase);
          break;

        case PurchaseStatus.error:
          // Handle error
          if (purchase.error != null) {
            // Log error
          }
          break;

        case PurchaseStatus.canceled:
          // User cancelled
          break;
      }

      // Complete the purchase (acknowledge)
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final callable = functions.httpsCallable('verifyPurchase');

      final result = await callable.call({
        'platform': 'google_play',
        'productId': purchase.productID,
        'purchaseToken': (purchase as GooglePlayPurchaseDetails)
            .billingClientPurchase
            .purchaseToken,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // Entitlements will update via Firestore listener
        // Show success UI
      } else {
        // Show error
      }
    } catch (e) {
      // Handle verification error
    }
  }
}
```

### 6.4 Apple App Store Implementation

```dart
// lib/infrastructure/purchases/app_store_purchase_service.dart

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'purchase_service.dart';

class AppStorePurchaseService implements PurchaseService {
  AppStorePurchaseService({required this.functions});

  final FirebaseFunctions functions;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const _productIds = {
    'kylos_pro_monthly',
    'kylos_pro_annual',
    'kylos_pro_lifetime',
  };

  @override
  StorePlatform get platform => StorePlatform.appStore;

  @override
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw PurchaseServiceException('Store not available');
    }

    // Set StoreKit delegate for promotional offers
    final iosPlatformAddition = _iap
        .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    await iosPlatformAddition.setDelegate(PaymentQueueDelegate());

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {},
    );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      throw PurchaseServiceException(response.error!.message);
    }

    return response.productDetails;
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final products = await getProducts();
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw PurchaseServiceException('Product not found'),
    );

    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: null,
    );

    // For subscriptions
    if (productId.contains('monthly') || productId.contains('annual')) {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // For one-time purchases
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }

    return PurchaseResult(success: true, productId: productId);
  }

  @override
  Future<List<PurchaseResult>> restorePurchases() async {
    await _iap.restorePurchases();
    return [];
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Show loading
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
          break;

        case PurchaseStatus.error:
          // Handle error
          break;

        case PurchaseStatus.canceled:
          // User cancelled
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final callable = functions.httpsCallable('verifyPurchase');

      // Get receipt data
      final appStorePurchase = purchase as AppStorePurchaseDetails;

      final result = await callable.call({
        'platform': 'app_store',
        'receiptData': appStorePurchase.verificationData.serverVerificationData,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // Success
      } else {
        // Error
      }
    } catch (e) {
      // Handle error
    }
  }
}

/// StoreKit delegate for handling promotional offers
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
```

### 6.5 Amazon Fire TV Implementation

```dart
// lib/infrastructure/purchases/amazon_purchase_service.dart

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'purchase_service.dart';

/// Amazon IAP implementation using platform channels
/// (No official Flutter plugin available)
class AmazonPurchaseService implements PurchaseService {
  AmazonPurchaseService({required this.functions});

  final FirebaseFunctions functions;

  static const _channel = MethodChannel('com.kylos.iptvplayer/amazon_iap');
  static const _eventChannel = EventChannel('com.kylos.iptvplayer/amazon_iap_events');

  StreamSubscription? _eventSubscription;

  final _purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  StorePlatform get platform => StorePlatform.amazon;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  Future<void> initialize() async {
    // Initialize Amazon IAP SDK via platform channel
    await _channel.invokeMethod('initialize');

    // Listen for purchase events
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleAmazonEvent);
  }

  @override
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _purchaseController.close();
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    final result = await _channel.invokeMethod<List>('getProducts', {
      'skus': [
        'kylos_pro_monthly_amazon',
        'kylos_pro_annual_amazon',
        'kylos_pro_lifetime_amazon',
      ],
    });

    return result?.map((p) => _mapToProductDetails(p)).toList() ?? [];
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    try {
      await _channel.invokeMethod('purchase', {'sku': productId});
      return PurchaseResult(success: true, productId: productId);
    } on PlatformException catch (e) {
      return PurchaseResult.error(
        message: e.message ?? 'Purchase failed',
        code: PurchaseErrorCode.unknown,
      );
    }
  }

  @override
  Future<List<PurchaseResult>> restorePurchases() async {
    await _channel.invokeMethod('restorePurchases');
    return [];
  }

  void _handleAmazonEvent(dynamic event) async {
    final type = event['type'] as String;
    final data = event['data'] as Map<String, dynamic>;

    switch (type) {
      case 'purchaseResponse':
        await _handlePurchaseResponse(data);
        break;
      case 'purchaseUpdates':
        await _handlePurchaseUpdates(data);
        break;
    }
  }

  Future<void> _handlePurchaseResponse(Map<String, dynamic> data) async {
    final status = data['status'] as String;

    if (status == 'SUCCESSFUL') {
      final receipt = data['receipt'] as Map<String, dynamic>;
      await _verifyAndDeliver(
        receipt['receiptId'] as String,
        data['userId'] as String,
        receipt['sku'] as String,
      );
    }
  }

  Future<void> _handlePurchaseUpdates(Map<String, dynamic> data) async {
    final receipts = data['receipts'] as List;

    for (final receipt in receipts) {
      if (receipt['canceled'] != true) {
        await _verifyAndDeliver(
          receipt['receiptId'] as String,
          data['userId'] as String,
          receipt['sku'] as String,
        );
      }
    }
  }

  Future<void> _verifyAndDeliver(
    String receiptId,
    String amazonUserId,
    String productId,
  ) async {
    try {
      final callable = functions.httpsCallable('verifyPurchase');

      final result = await callable.call({
        'platform': 'amazon',
        'amazonReceiptId': receiptId,
        'amazonUserId': amazonUserId,
        'productId': productId,
      });

      final response = result.data as Map<String, dynamic>;

      if (response['success'] == true) {
        // Notify Amazon that we've fulfilled the purchase
        await _channel.invokeMethod('notifyFulfillment', {
          'receiptId': receiptId,
          'fulfillmentResult': 'FULFILLED',
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  ProductDetails _mapToProductDetails(Map<String, dynamic> p) {
    // Map Amazon product to Flutter ProductDetails
    return ProductDetails(
      id: p['sku'] as String,
      title: p['title'] as String,
      description: p['description'] as String,
      price: p['price'] as String,
      rawPrice: (p['priceAmount'] as num).toDouble(),
      currencyCode: p['currency'] as String,
    );
  }
}
```

### 6.6 State Management

```dart
// lib/features/monetization/presentation/providers/monetization_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_player/infrastructure/firebase/firebase_service.dart';
import 'package:kylos_player/infrastructure/purchases/purchase_service.dart';

/// Purchase service provider (singleton)
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  return PurchaseService.create(functions: firebase.functions);
});

/// Current entitlements (real-time from Firestore)
final entitlementsProvider = StreamProvider<Entitlements>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final userId = firebase.currentUserId;

  if (userId == null) {
    return Stream.value(Entitlements.free());
  }

  return firebase.firestore
      .collection('entitlements')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return Entitlements.free();

    final data = doc.data()!;
    return Entitlements(
      tier: SubscriptionTier.values.byName(data['currentTier'] ?? 'free'),
      platform: data['currentPlatform'],
      productId: data['currentProductId'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      graceEndAt: (data['graceEndAt'] as Timestamp?)?.toDate(),
      hasLifetime: data['hasLifetime'] ?? false,
      trialUsed: data['trialUsed'] ?? false,
    );
  });
});

/// Quick check for Pro status
final isProProvider = Provider<bool>((ref) {
  return ref.watch(entitlementsProvider).maybeWhen(
    data: (e) => e.isPro,
    orElse: () => false,
  );
});

/// Check if user can use free trial
final canUseTrialProvider = Provider<bool>((ref) {
  return ref.watch(entitlementsProvider).maybeWhen(
    data: (e) => !e.trialUsed && e.tier == SubscriptionTier.free,
    orElse: () => false,
  );
});

/// Available products for purchase
final productsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.getProducts();
});

/// Purchase controller for managing purchase flow
final purchaseControllerProvider =
    StateNotifierProvider<PurchaseController, PurchaseState>((ref) {
  return PurchaseController(
    purchaseService: ref.watch(purchaseServiceProvider),
  );
});

/// Entitlements domain model
class Entitlements {
  final SubscriptionTier tier;
  final String? platform;
  final String? productId;
  final DateTime? expiresAt;
  final DateTime? graceEndAt;
  final bool hasLifetime;
  final bool trialUsed;

  const Entitlements({
    required this.tier,
    this.platform,
    this.productId,
    this.expiresAt,
    this.graceEndAt,
    this.hasLifetime = false,
    this.trialUsed = false,
  });

  factory Entitlements.free() => const Entitlements(tier: SubscriptionTier.free);

  bool get isPro => tier == SubscriptionTier.pro;

  bool get isInGracePeriod =>
      graceEndAt != null && DateTime.now().isBefore(graceEndAt!);

  bool get isExpired =>
      !hasLifetime && expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check access with offline grace period
  bool hasAccess({Duration offlineGrace = const Duration(days: 7)}) {
    if (hasLifetime) return true;
    if (tier != SubscriptionTier.pro) return false;

    // If we have a valid expiry date, check it
    if (expiresAt != null) {
      final effectiveExpiry = expiresAt!.add(offlineGrace);
      return DateTime.now().isBefore(effectiveExpiry);
    }

    // No expiry means we trust the tier
    return true;
  }
}

enum SubscriptionTier { free, pro }

/// Purchase state
sealed class PurchaseState {
  const PurchaseState();
}

class PurchaseStateIdle extends PurchaseState {
  const PurchaseStateIdle();
}

class PurchaseStateLoading extends PurchaseState {
  final String? productId;
  const PurchaseStateLoading({this.productId});
}

class PurchaseStateVerifying extends PurchaseState {
  const PurchaseStateVerifying();
}

class PurchaseStateSuccess extends PurchaseState {
  final String tier;
  final DateTime? expiresAt;
  const PurchaseStateSuccess({required this.tier, this.expiresAt});
}

class PurchaseStateError extends PurchaseState {
  final String message;
  final PurchaseErrorCode? code;
  const PurchaseStateError({required this.message, this.code});
}

class PurchaseStateRestored extends PurchaseState {
  final int count;
  const PurchaseStateRestored({required this.count});
}

/// Purchase controller
class PurchaseController extends StateNotifier<PurchaseState> {
  PurchaseController({required this.purchaseService})
      : super(const PurchaseStateIdle());

  final PurchaseService purchaseService;

  Future<void> purchase(String productId) async {
    state = PurchaseStateLoading(productId: productId);

    try {
      final result = await purchaseService.purchase(productId);

      if (result.success) {
        state = const PurchaseStateVerifying();
        // Actual success will come via Firestore listener
        // after backend verification completes
      } else {
        state = PurchaseStateError(
          message: result.errorMessage ?? 'Purchase failed',
          code: result.errorCode,
        );
      }
    } catch (e) {
      state = PurchaseStateError(message: e.toString());
    }
  }

  Future<void> restorePurchases() async {
    state = const PurchaseStateLoading();

    try {
      await purchaseService.restorePurchases();
      // Results come via purchase stream and Firestore
      state = const PurchaseStateRestored(count: 0);
    } catch (e) {
      state = PurchaseStateError(message: e.toString());
    }
  }

  void reset() {
    state = const PurchaseStateIdle();
  }
}
```

### 6.7 Offline Grace Period Handling

```dart
// lib/features/monetization/domain/services/entitlement_checker.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_player/core/storage/local_storage.dart';
import 'package:kylos_player/features/monetization/presentation/providers/monetization_providers.dart';

/// Service to check entitlements with offline support
final entitlementCheckerProvider = Provider<EntitlementChecker>((ref) {
  return EntitlementChecker(
    entitlementsAsync: ref.watch(entitlementsProvider),
    localStorage: ref.watch(localStorageProvider),
  );
});

class EntitlementChecker {
  EntitlementChecker({
    required this.entitlementsAsync,
    required this.localStorage,
  });

  final AsyncValue<Entitlements> entitlementsAsync;
  final LocalStorage localStorage;

  /// Offline grace period (allow Pro access for N days without network)
  static const offlineGracePeriod = Duration(days: 7);

  /// Check if user has Pro access (with offline handling)
  Future<bool> hasProAccess() async {
    // Try to get live entitlements
    final liveEntitlements = entitlementsAsync.valueOrNull;

    if (liveEntitlements != null) {
      // We have network data - update cache and use it
      await _cacheEntitlements(liveEntitlements);
      return liveEntitlements.isPro;
    }

    // No network - check cached entitlements
    final cached = await _getCachedEntitlements();
    if (cached == null) {
      // No cache, default to free
      return false;
    }

    // Check if cached entitlements are within grace period
    return cached.hasAccess(offlineGrace: offlineGracePeriod);
  }

  /// Check specific feature access
  Future<bool> canAccessFeature(ProFeature feature) async {
    // Some features require network (e.g., cloud sync)
    if (feature.requiresNetwork && entitlementsAsync.hasError) {
      return false;
    }

    return await hasProAccess();
  }

  Future<void> _cacheEntitlements(Entitlements entitlements) async {
    await localStorage.cacheEntitlements(
      tier: entitlements.tier.name,
      expiresAt: entitlements.expiresAt,
      hasLifetime: entitlements.hasLifetime,
      cachedAt: DateTime.now(),
    );
  }

  Future<Entitlements?> _getCachedEntitlements() async {
    final cached = await localStorage.getCachedEntitlements();
    if (cached == null) return null;

    return Entitlements(
      tier: SubscriptionTier.values.byName(cached['tier']),
      expiresAt: cached['expiresAt'] != null
          ? DateTime.parse(cached['expiresAt'])
          : null,
      hasLifetime: cached['hasLifetime'] ?? false,
    );
  }
}

enum ProFeature {
  unlimitedPlaylists(requiresNetwork: false),
  cloudSync(requiresNetwork: true),
  multiDevice(requiresNetwork: true),
  advancedEpg(requiresNetwork: false),
  pictureInPicture(requiresNetwork: false),
  chromecast(requiresNetwork: false),
  parentalControls(requiresNetwork: false),
  themes(requiresNetwork: false);

  const ProFeature({required this.requiresNetwork});
  final bool requiresNetwork;
}
```

### 6.8 Feature Gating Widget

```dart
// lib/shared/widgets/pro_feature_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_player/features/monetization/presentation/providers/monetization_providers.dart';
import 'package:kylos_player/navigation/routes.dart';

/// Widget that gates Pro features with appropriate UX
class ProFeatureGate extends ConsumerWidget {
  const ProFeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedChild,
    this.onLockedTap,
    this.showPaywallOnTap = true,
  });

  /// The Pro feature being gated
  final ProFeature feature;

  /// Widget to show when user has access
  final Widget child;

  /// Optional widget to show when locked (defaults to child with lock overlay)
  final Widget? lockedChild;

  /// Optional callback when locked item is tapped
  final VoidCallback? onLockedTap;

  /// Whether to show paywall on tap (default true)
  final bool showPaywallOnTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    if (isPro) {
      return child;
    }

    // Show locked state
    return GestureDetector(
      onTap: () {
        onLockedTap?.call();
        if (showPaywallOnTap) {
          context.push(Routes.paywall, extra: {
            'feature': feature.name,
            'source': 'feature_gate',
          });
        }
      },
      child: lockedChild ?? _DefaultLockedWidget(child: child),
    );
  }
}

class _DefaultLockedWidget extends StatelessWidget {
  const _DefaultLockedWidget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed original widget
        Opacity(
          opacity: 0.5,
          child: IgnorePointer(child: child),
        ),
        // Lock overlay
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Extension for easy Pro checks in widgets
extension ProFeatureGateExtension on Widget {
  Widget proGated(ProFeature feature) {
    return ProFeatureGate(
      feature: feature,
      child: this,
    );
  }
}
```

---

## 7. Revenue Projections

### 7.1 Conservative Scenario

```
Year 1 Assumptions:
- Downloads: 50,000 total
- Active users (MAU): 20,000
- Free trial start rate: 10%
- Trial to paid conversion: 30%
- Direct paid conversion: 2%
- Annual vs Monthly split: 70/30

Calculations:
- Trial starters: 20,000 x 10% = 2,000
- Trial conversions: 2,000 x 30% = 600
- Direct conversions: 20,000 x 2% = 400
- Total paid users: 1,000

Revenue breakdown:
- Annual (70%): 700 x $19.99 = $13,993
- Monthly (30%): 300 x $2.99 x 12 = $10,764

Year 1 Revenue: ~$25,000
After store fees (30%): ~$17,500
```

### 7.2 Moderate Scenario

```
Year 1 Assumptions:
- Downloads: 150,000 total
- Active users (MAU): 60,000
- Free trial start rate: 12%
- Trial to paid conversion: 35%
- Direct paid conversion: 3%
- Annual vs Monthly split: 65/35

Calculations:
- Trial starters: 60,000 x 12% = 7,200
- Trial conversions: 7,200 x 35% = 2,520
- Direct conversions: 60,000 x 3% = 1,800
- Total paid users: 4,320

Revenue breakdown:
- Annual (65%): 2,808 x $19.99 = $56,132
- Monthly (35%): 1,512 x $2.99 x 12 = $54,240

Year 1 Revenue: ~$110,000
After store fees (30%): ~$77,000
```

### 7.3 Optimistic Scenario

```
Year 1 Assumptions:
- Downloads: 300,000 total
- Active users (MAU): 120,000
- Free trial start rate: 15%
- Trial to paid conversion: 40%
- Direct paid conversion: 4%
- Annual vs Monthly split: 60/40

Calculations:
- Trial starters: 120,000 x 15% = 18,000
- Trial conversions: 18,000 x 40% = 7,200
- Direct conversions: 120,000 x 4% = 4,800
- Total paid users: 12,000

Revenue breakdown:
- Annual (60%): 7,200 x $19.99 = $143,928
- Monthly (40%): 4,800 x $2.99 x 12 = $172,224

Year 1 Revenue: ~$316,000
After store fees (30%): ~$221,000
```

---

## 8. Appendices

### 8.1 Store Review Checklist

#### Google Play

- [ ] Products configured in Play Console
- [ ] Real-time Developer Notifications (RTDN) set up
- [ ] License testing enabled for test accounts
- [ ] Subscription terms displayed in app
- [ ] Privacy policy linked
- [ ] "No content provided" disclaimer present

#### Apple App Store

- [ ] Products configured in App Store Connect
- [ ] Subscription group created
- [ ] StoreKit configuration file for testing
- [ ] App Store Server Notifications configured
- [ ] Required subscription text present
- [ ] Restore Purchases button visible
- [ ] Sign-in with Apple offered (if using accounts)

#### Amazon Appstore

- [ ] Products configured in Amazon Developer Console
- [ ] Amazon AppTester installed on test devices
- [ ] Receipt Verification Service (RVS) integration tested
- [ ] Fire TV remote navigation tested

### 8.2 Testing Matrix

| Test Case | Google Play | App Store | Amazon |
|-----------|-------------|-----------|--------|
| New subscription purchase | | | |
| Subscription renewal | | | |
| Subscription cancellation | | | |
| Grace period handling | | | |
| Account hold (Google only) | | N/A | N/A |
| Restore purchases | | | |
| Cross-device restore | | | |
| Refund handling | | | |
| Upgrade (monthly → annual) | | | |
| Downgrade handling | | | |
| Free trial start | | | |
| Free trial conversion | | | |
| Free trial expiration | | | |
| Lifetime purchase | | | |
| Offline access | | | |
| Offline grace expiration | | | |

### 8.3 Analytics Events

```dart
// Purchase funnel events
enum PurchaseAnalyticsEvent {
  paywallViewed,           // User saw paywall
  paywallDismissed,        // User closed paywall without action
  productSelected,         // User selected a product
  purchaseInitiated,       // Purchase flow started
  purchaseCompleted,       // Purchase successful
  purchaseFailed,          // Purchase failed
  purchaseCancelled,       // User cancelled
  trialStarted,            // Free trial began
  trialConverted,          // Trial converted to paid
  trialExpired,            // Trial ended without conversion
  restoreInitiated,        // Restore button tapped
  restoreCompleted,        // Restore successful
  restoreFailed,           // Restore failed
  subscriptionCancelled,   // User cancelled subscription
  subscriptionReactivated, // Cancelled user resubscribed
}
```

---

## Summary

This monetization strategy provides:

1. **Ethical approach**: Generous free tier, no dark patterns, clear value proposition
2. **Store compliance**: Follows all Apple, Google, and Amazon guidelines
3. **Technical robustness**: Server-side verification, webhook handling, offline support
4. **Revenue sustainability**: Subscription model with annual focus for predictable ARR
5. **User trust**: Clear content disclaimers, transparent pricing

The implementation is designed to be maintainable, testable, and adaptable as the app grows.
