# Kylos IPTV Player - Backend Architecture and Data Model

## Document Version

| Version | Date       | Author          | Description                     |
|---------|------------|-----------------|--------------------------------|
| 1.0     | 2024-01-XX | Architecture    | Initial backend design          |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Firebase vs Custom Backend Analysis](#2-firebase-vs-custom-backend-analysis)
3. [Architecture Overview](#3-architecture-overview)
4. [Data Model Design](#4-data-model-design)
5. [Security Rules and Access Control](#5-security-rules-and-access-control)
6. [Cloud Functions](#6-cloud-functions)
7. [Flutter Client Integration](#7-flutter-client-integration)
8. [Cost Estimation](#8-cost-estimation)
9. [Monitoring and Operations](#9-monitoring-and-operations)

---

## 1. Executive Summary

This document defines the backend architecture for Kylos IPTV Player. The backend serves as a lightweight synchronization and entitlement management layer - it does NOT host, proxy, or cache any IPTV content streams.

### Core Backend Responsibilities

| Responsibility | Description |
|---------------|-------------|
| Authentication | Email/password, Google, Apple Sign-In, anonymous upgrade |
| User Data Sync | Profiles, preferences, playlist configurations |
| Entitlements | IAP verification and multi-device restore |
| Remote Config | Feature flags, A/B testing, kill switches |
| Analytics | Usage metrics (non-content-specific) |
| Push Notifications | New features, maintenance alerts |

### Key Architectural Decision

**Recommendation: Firebase** as the primary backend platform.

Firebase provides the optimal balance of development speed, cost efficiency, and feature completeness for Kylos IPTV Player's requirements. The detailed comparison follows in Section 2.

---

## 2. Firebase vs Custom Backend Analysis

### 2.1 Comparison Matrix

| Criteria | Firebase | Custom (NestJS + Postgres) |
|----------|----------|---------------------------|
| **Time-to-market** | 2-4 weeks | 8-12 weeks |
| **Initial development cost** | Low ($0-5K) | High ($15-30K) |
| **Monthly operating cost (10K users)** | ~$50-100 | ~$100-300 |
| **Monthly operating cost (100K users)** | ~$300-800 | ~$500-1500 |
| **Vendor lock-in** | Moderate | Low |
| **Scalability** | Automatic | Manual configuration |
| **Authentication** | Built-in, multi-provider | Requires implementation |
| **Real-time sync** | Built-in | Requires WebSocket setup |
| **Push notifications** | FCM included | Requires third-party |
| **Remote config** | Built-in | Requires implementation |
| **IAP verification** | Cloud Functions ready | Requires implementation |
| **Offline support** | Built-in SDK caching | Manual implementation |
| **Team expertise required** | Lower | Higher |

### 2.2 Detailed Analysis

#### Time-to-Market

**Firebase Advantage: 4-6x faster**

Firebase provides out-of-the-box solutions for:
- Multi-provider authentication (no OAuth flow implementation)
- Real-time database with offline persistence
- Cloud Functions for serverless backend logic
- FCM for cross-platform push notifications
- Remote Config for feature flags

A custom backend requires building each component from scratch or integrating multiple services.

#### Operating Cost

**Firebase Advantage at Scale**

Firebase's pay-as-you-go model aligns costs with actual usage. For a media player app where backend operations are lightweight (sync settings, verify purchases), costs remain low.

```
Firebase Cost Breakdown (estimated 50K MAU):
- Authentication: Free (unlimited)
- Firestore: ~$25-50/month (reads/writes for sync)
- Cloud Functions: ~$10-30/month (IAP verification)
- FCM: Free
- Remote Config: Free
- Hosting (if needed): ~$5/month
Total: ~$40-85/month

Custom Backend (50K MAU):
- Cloud VM (2 vCPU, 4GB): ~$40-80/month
- Managed Postgres: ~$50-100/month
- Load balancer: ~$20/month
- Push notification service: ~$25/month
- SSL/Domain: ~$10/month
- DevOps time: ~$200-500/month (maintenance)
Total: ~$345-735/month
```

#### Vendor Lock-in

**Moderate concern, mitigated by architecture**

Firebase lock-in risks:
1. **Firestore data format**: Mitigated by clean data model design
2. **Authentication**: Can export users, OAuth tokens portable
3. **Cloud Functions**: Standard Node.js, easily portable

Mitigation strategies implemented in this design:
- Repository pattern in Flutter client (abstracted data layer)
- Standard data formats (JSON-serializable)
- Business logic in Cloud Functions (not Firestore triggers)

#### Complexity vs Benefits

**Firebase wins for this use case**

Kylos IPTV Player's backend needs are straightforward:
- No complex relational queries (NoSQL is sufficient)
- No heavy computation (IAP verification is simple)
- No streaming/media processing (handled client-side)
- Real-time sync is beneficial but not critical

A custom backend would add complexity without proportional benefits.

### 2.3 Recommendation

**Use Firebase** with the following configuration:

| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication |
| Cloud Firestore | User data, profiles, settings |
| Cloud Functions | IAP verification, data cleanup |
| Firebase Remote Config | Feature flags |
| Firebase Cloud Messaging | Push notifications |
| Firebase Crashlytics | Error tracking |
| Google Analytics for Firebase | Usage analytics |

### 2.4 When to Reconsider

Consider migrating to a custom backend if:
- Monthly Firebase costs exceed $2,000
- Complex relational queries become necessary
- Multi-region data residency is legally required
- Team grows and can dedicate DevOps resources

---

## 3. Architecture Overview

### 3.1 System Architecture

```
+------------------------------------------------------------------+
|                        KYLOS IPTV PLAYER                          |
|                         (Flutter Client)                          |
+------------------+-------------------+-------------------+---------+
                   |                   |                   |
                   v                   v                   v
+------------------+-------------------+-------------------+---------+
|              FIREBASE SERVICES                                    |
|                                                                   |
|  +-------------+  +-------------+  +-------------+  +-----------+ |
|  |   Firebase  |  |   Cloud     |  |   Remote    |  |    FCM    | |
|  |    Auth     |  |  Firestore  |  |   Config    |  |           | |
|  +-------------+  +-------------+  +-------------+  +-----------+ |
|                          |                                        |
|                          v                                        |
|  +----------------------------------------------------------+    |
|  |                    CLOUD FUNCTIONS                        |    |
|  |                                                           |    |
|  |  +---------------+  +---------------+  +---------------+  |    |
|  |  |  IAP Verify   |  |  User Cleanup |  |  Analytics    |  |    |
|  |  |  (Play/Apple/ |  |  (on delete)  |  |  Aggregation  |  |    |
|  |  |   Amazon)     |  |               |  |               |  |    |
|  |  +---------------+  +---------------+  +---------------+  |    |
|  +----------------------------------------------------------+    |
|                                                                   |
+------------------------------------------------------------------+
                   |                   |
                   v                   v
+------------------+-------------------+---------------------------+
|           EXTERNAL SERVICES                                      |
|                                                                  |
|  +------------------+  +------------------+  +------------------+|
|  |  Google Play     |  |  Apple App       |  |  Amazon          ||
|  |  Developer API   |  |  Store Connect   |  |  Appstore API    ||
|  +------------------+  +------------------+  +------------------+|
+------------------------------------------------------------------+
```

### 3.2 Data Flow Diagrams

#### Authentication Flow

```
Client                    Firebase Auth              Firestore
  |                            |                         |
  |-- signInWithGoogle() ---->|                         |
  |                            |                         |
  |<-- UserCredential --------|                         |
  |                            |                         |
  |-- Check user doc exists ----------------------->|
  |                            |                         |
  |<-- (not found) ---------------------------------|
  |                            |                         |
  |-- Create user doc (Cloud Function trigger) ---->|
  |                            |                         |
  |<-- User document created ------------------------|
```

#### Purchase Verification Flow

```
Client              Cloud Function           Store API          Firestore
  |                      |                       |                   |
  |-- purchaseComplete ->|                       |                   |
  |   (receipt token)    |                       |                   |
  |                      |-- verifyReceipt ----->|                   |
  |                      |                       |                   |
  |                      |<-- receipt valid -----|                   |
  |                      |                       |                   |
  |                      |-- write entitlement ----------------->|
  |                      |                       |                   |
  |<-- success ----------|                       |                   |
```

#### Settings Sync Flow

```
Client (Device A)         Firestore            Client (Device B)
  |                          |                        |
  |-- update settings ------>|                        |
  |                          |                        |
  |                          |-- realtime update ---->|
  |                          |                        |
  |<-- confirmation ---------|                        |
```

---

## 4. Data Model Design

### 4.1 Collection Structure Overview

```
firestore-root/
├── users/                    # User accounts
│   └── {userId}/
│       ├── profiles/         # Sub-collection: user profiles
│       │   └── {profileId}
│       ├── playlists/        # Sub-collection: playlist sources
│       │   └── {playlistId}
│       └── devices/          # Sub-collection: device settings
│           └── {deviceId}
│
├── entitlements/             # Purchase entitlements (protected)
│   └── {userId}/
│       └── purchases/        # Sub-collection: individual purchases
│           └── {purchaseId}
│
├── app_config/               # Admin-managed configuration (read-only)
│   └── {configId}
│
└── analytics_events/         # Aggregated analytics (write-only from client)
    └── {eventId}
```

### 4.2 Collection: `users`

Stores core user account information.

```json
// Document: /users/{userId}
{
  // Identity
  "uid": "abc123xyz",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoURL": "https://...",

  // Account metadata
  "createdAt": "2024-01-15T10:30:00Z",      // Timestamp
  "lastLoginAt": "2024-01-20T14:22:00Z",    // Timestamp
  "lastSyncAt": "2024-01-20T14:22:00Z",     // Timestamp

  // Auth providers linked
  "providers": ["google.com", "password"],

  // Account status
  "status": "active",                        // active | suspended | deleted
  "deletionRequestedAt": null,               // Timestamp (for GDPR)

  // Global preferences (synced across devices)
  "preferences": {
    "language": "en",
    "theme": "dark",                         // dark | light | system
    "defaultProfileId": "profile_abc",
    "analyticsEnabled": true
  },

  // Subscription status (denormalized for quick access)
  "subscription": {
    "tier": "pro",                           // free | pro
    "expiresAt": "2025-01-15T10:30:00Z",     // Timestamp
    "platform": "google_play",               // google_play | app_store | amazon
    "autoRenew": true
  },

  // FCM tokens for push notifications
  "fcmTokens": {
    "device_abc123": {
      "token": "fcm_token_here",
      "platform": "android",
      "updatedAt": "2024-01-20T14:22:00Z"
    }
  }
}
```

**Indexes:**
- `email` (for admin lookup)
- `subscription.tier` + `subscription.expiresAt` (for subscription management)
- `status` (for account management)

### 4.3 Sub-collection: `users/{userId}/profiles`

Per-user profiles (e.g., "Dad", "Kids", "Guest").

```json
// Document: /users/{userId}/profiles/{profileId}
{
  "id": "profile_abc",
  "name": "Dad",
  "avatarId": "avatar_01",                   // Predefined avatar or custom
  "avatarURL": null,                         // Custom avatar URL (Pro feature)

  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-18T09:15:00Z",

  // Profile-specific settings
  "isDefault": true,
  "isKidsProfile": false,

  // Parental control (if this is a kids profile)
  "parentalControl": {
    "enabled": false,
    "pinHash": null,                         // bcrypt hash, never plain text
    "maxRating": "TV-MA",                    // TV-Y | TV-G | TV-PG | TV-14 | TV-MA
    "blockedCategories": [],                 // ["adult", "violence"]
    "timeRestrictions": null                 // Future: viewing time limits
  },

  // Viewing preferences
  "playbackSettings": {
    "defaultQuality": "auto",                // auto | 1080p | 720p | 480p
    "autoPlay": true,
    "subtitlesEnabled": false,
    "preferredAudioLanguage": "en",
    "preferredSubtitleLanguage": "en"
  },

  // UI preferences
  "uiSettings": {
    "channelGridSize": "medium",             // small | medium | large
    "showEpg": true,
    "epgDaysToShow": 3
  },

  // Content state (could be large, consider separate sub-collection for scale)
  "favorites": {
    "channels": ["channel_123", "channel_456"],
    "movies": ["movie_789"],
    "series": ["series_012"]
  },

  // Watch history (last N items, full history in separate collection if needed)
  "recentlyWatched": [
    {
      "contentId": "channel_123",
      "contentType": "channel",
      "watchedAt": "2024-01-20T14:00:00Z"
    }
  ],

  // Continue watching (for VOD/Series)
  "continueWatching": [
    {
      "contentId": "movie_789",
      "contentType": "movie",
      "position": 3600,                      // seconds
      "duration": 7200,
      "updatedAt": "2024-01-20T12:00:00Z"
    }
  ]
}
```

**Indexes:**
- `isDefault` (for quick default profile lookup)
- Composite: `parentalControl.enabled` + `parentalControl.maxRating`

### 4.4 Sub-collection: `users/{userId}/playlists`

Stores IPTV playlist source configurations.

```json
// Document: /users/{userId}/playlists/{playlistId}
{
  "id": "playlist_xyz",
  "name": "My IPTV Provider",
  "type": "xtream",                          // m3u_url | m3u_file | xtream

  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-18T09:15:00Z",
  "lastRefreshAt": "2024-01-20T06:00:00Z",
  "lastRefreshStatus": "success",            // success | failed | pending

  // Source configuration (type-specific)
  // For m3u_url:
  "m3uUrl": null,

  // For xtream:
  "xtream": {
    "serverUrl": "http://provider.example.com:8080",
    "username": "user123",
    // Password is ENCRYPTED - see Section 4.7
    "encryptedPassword": "encrypted_blob_here"
  },

  // For m3u_file (stored in Cloud Storage):
  "m3uFileRef": null,                        // gs://bucket/path/to/file.m3u

  // Playlist metadata (cached from last refresh)
  "metadata": {
    "channelCount": 1500,
    "vodCount": 5000,
    "seriesCount": 200,
    "categories": ["Sports", "News", "Movies", "Kids"],
    "expiresAt": "2025-01-15T00:00:00Z"      // From Xtream API if available
  },

  // Auto-refresh settings
  "autoRefresh": {
    "enabled": true,
    "intervalHours": 24,
    "onAppStart": true
  },

  // Status flags
  "isActive": true,                          // Currently selected playlist
  "isPinned": false,                         // Show at top of list
  "sortOrder": 0
}
```

**Indexes:**
- `isActive` (for quick active playlist lookup)
- `sortOrder` (for ordered listing)

### 4.5 Sub-collection: `users/{userId}/devices`

Per-device settings that should not sync (e.g., decoder settings).

```json
// Document: /users/{userId}/devices/{deviceId}
{
  "id": "device_abc123",
  "name": "Living Room TV",                  // User-editable or auto-detected
  "platform": "android_tv",                  // android | ios | android_tv | fire_tv
  "model": "NVIDIA Shield TV",
  "osVersion": "11",
  "appVersion": "1.2.3",

  "firstSeenAt": "2024-01-15T10:30:00Z",
  "lastSeenAt": "2024-01-20T14:22:00Z",

  // Device-specific playback settings
  "playbackSettings": {
    "decoder": "hardware",                   // hardware | software | auto
    "bufferSize": "medium",                  // low | medium | high
    "hardwareAcceleration": true,
    "audioPassthrough": true                 // For Android TV/Fire TV
  },

  // Device-specific UI settings
  "uiSettings": {
    "fontSize": "large",                     // For TV: larger text
    "animationsEnabled": true,
    "overscanAdjustment": {
      "top": 0,
      "bottom": 0,
      "left": 0,
      "right": 0
    }
  },

  // Network settings
  "networkSettings": {
    "preferWifi": true,
    "allowMobileData": false,
    "mobileDataWarning": true
  }
}
```

**Indexes:**
- `platform` (for platform-specific analytics)
- `lastSeenAt` (for inactive device cleanup)

### 4.6 Collection: `entitlements`

Stores verified purchase entitlements. This collection has stricter security rules.

```json
// Document: /entitlements/{userId}
{
  "userId": "abc123xyz",

  // Current entitlement status (denormalized for quick reads)
  "currentTier": "pro",                      // free | pro
  "currentPlatform": "google_play",
  "expiresAt": "2025-01-15T10:30:00Z",
  "graceEndAt": null,                        // Grace period end if payment failed

  // Flags
  "hasLifetime": false,                      // Lifetime purchase
  "isTrial": false,
  "trialUsed": true,

  // Aggregated from purchases sub-collection
  "totalPurchases": 2,
  "totalSpent": {
    "USD": 49.98
  },

  "updatedAt": "2024-01-15T10:30:00Z"
}

// Sub-document: /entitlements/{userId}/purchases/{purchaseId}
{
  "id": "purchase_001",
  "platform": "google_play",                 // google_play | app_store | amazon

  // Platform-specific identifiers
  "orderId": "GPA.1234-5678-9012",           // Google Play order ID
  "transactionId": null,                     // App Store transaction ID
  "receiptId": null,                         // Amazon receipt ID

  // Product info
  "productId": "kylos_pro_annual",
  "productType": "subscription",             // subscription | one_time | consumable

  // Purchase details
  "purchasedAt": "2024-01-15T10:30:00Z",
  "expiresAt": "2025-01-15T10:30:00Z",
  "price": 24.99,
  "currency": "USD",

  // Subscription state
  "state": "active",                         // active | cancelled | expired | refunded | grace_period
  "autoRenew": true,
  "cancelledAt": null,
  "refundedAt": null,

  // Verification
  "verifiedAt": "2024-01-15T10:30:05Z",
  "verificationSource": "cloud_function",
  "rawReceipt": "ENCRYPTED_RECEIPT_BLOB",    // Encrypted for audit trail

  // For subscription: renewal history
  "renewalCount": 0,
  "lastRenewalAt": null
}
```

**Indexes:**
- `currentTier` + `expiresAt` (for subscription management)
- `purchases.platform` + `purchases.state` (for platform-specific queries)
- `purchases.expiresAt` (for expiration processing)

### 4.7 Sensitive Data Encryption

#### Encryption Strategy

Sensitive fields (Xtream passwords, raw receipts) are encrypted using:

1. **At Rest**: Firestore encrypts all data at rest by default (Google-managed keys)
2. **Application-Level**: Additional AES-256-GCM encryption for sensitive fields
3. **In Transit**: TLS 1.3 for all connections

#### Implementation

```typescript
// Cloud Function: Encryption utilities

import * as crypto from 'crypto';

// Encryption key stored in Secret Manager
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY; // 32 bytes, base64

interface EncryptedData {
  ciphertext: string;  // base64
  iv: string;          // base64
  tag: string;         // base64
}

function encrypt(plaintext: string): EncryptedData {
  const key = Buffer.from(ENCRYPTION_KEY, 'base64');
  const iv = crypto.randomBytes(12);

  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

  let ciphertext = cipher.update(plaintext, 'utf8', 'base64');
  ciphertext += cipher.final('base64');

  const tag = cipher.getAuthTag();

  return {
    ciphertext,
    iv: iv.toString('base64'),
    tag: tag.toString('base64')
  };
}

function decrypt(encrypted: EncryptedData): string {
  const key = Buffer.from(ENCRYPTION_KEY, 'base64');
  const iv = Buffer.from(encrypted.iv, 'base64');
  const tag = Buffer.from(encrypted.tag, 'base64');

  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);

  let plaintext = decipher.update(encrypted.ciphertext, 'base64', 'utf8');
  plaintext += decipher.final('utf8');

  return plaintext;
}
```

#### Encrypted Fields

| Collection | Field | Encryption |
|------------|-------|------------|
| `playlists` | `xtream.encryptedPassword` | AES-256-GCM |
| `entitlements/purchases` | `rawReceipt` | AES-256-GCM |
| `profiles` | `parentalControl.pinHash` | bcrypt (one-way) |

### 4.8 Collection: `app_config`

Admin-managed configuration (read-only for clients).

```json
// Document: /app_config/products
{
  "products": {
    "kylos_pro_monthly": {
      "name": "Kylos Pro Monthly",
      "tier": "pro",
      "type": "subscription",
      "features": ["unlimited_profiles", "cloud_sync", "no_ads", "hd_playback"],
      "platforms": {
        "google_play": "kylos_pro_monthly",
        "app_store": "kylos_pro_monthly",
        "amazon": "kylos_pro_monthly_amazon"
      }
    },
    "kylos_pro_annual": {
      "name": "Kylos Pro Annual",
      "tier": "pro",
      "type": "subscription",
      "features": ["unlimited_profiles", "cloud_sync", "no_ads", "hd_playback"],
      "platforms": {
        "google_play": "kylos_pro_annual",
        "app_store": "kylos_pro_annual",
        "amazon": "kylos_pro_annual_amazon"
      }
    }
  }
}

// Document: /app_config/features
{
  "minAppVersion": {
    "android": "1.0.0",
    "ios": "1.0.0",
    "android_tv": "1.0.0"
  },
  "forceUpdate": false,
  "maintenanceMode": false,
  "maintenanceMessage": null
}

// Document: /app_config/limits
{
  "free": {
    "maxProfiles": 2,
    "maxPlaylists": 1,
    "maxFavorites": 50,
    "epgDaysAvailable": 1,
    "cloudSyncEnabled": false
  },
  "pro": {
    "maxProfiles": 10,
    "maxPlaylists": 10,
    "maxFavorites": 500,
    "epgDaysAvailable": 7,
    "cloudSyncEnabled": true
  }
}
```

### 4.9 Collection: `analytics_events`

Client-written analytics events (write-only, no read from client).

```json
// Document: /analytics_events/{eventId}
{
  "userId": "abc123xyz",                     // Optional: null for anonymous
  "sessionId": "session_456",
  "deviceId": "device_abc123",

  "event": "app_open",
  "timestamp": "2024-01-20T14:22:00Z",

  "properties": {
    "platform": "android_tv",
    "appVersion": "1.2.3",
    "tier": "pro"
  },

  // No content-specific data (privacy)
  // Good: {"event": "playback_started", "contentType": "channel"}
  // Bad:  {"event": "playback_started", "channelName": "HBO"}
}
```

---

## 5. Security Rules and Access Control

### 5.1 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Check if user has admin claim
    function isAdmin() {
      return isAuthenticated() &&
             request.auth.token.admin == true;
    }

    // Validate timestamp is server time
    function isValidTimestamp(field) {
      return request.resource.data[field] == request.time;
    }

    // Check data size limits
    function isWithinSizeLimit(field, maxSize) {
      return request.resource.data[field].size() <= maxSize;
    }

    // ============================================
    // USERS COLLECTION
    // ============================================

    match /users/{userId} {
      // Users can read their own document
      allow read: if isOwner(userId);

      // Users can create their own document (on first sign-in)
      allow create: if isOwner(userId) &&
                       request.resource.data.uid == userId &&
                       isValidTimestamp('createdAt');

      // Users can update their own document with restrictions
      allow update: if isOwner(userId) &&
                       // Cannot change uid
                       request.resource.data.uid == resource.data.uid &&
                       // Cannot directly modify subscription (use Cloud Functions)
                       request.resource.data.subscription == resource.data.subscription;

      // Users cannot delete their document directly (use Cloud Function)
      allow delete: if false;

      // ----------------------------------------
      // PROFILES SUB-COLLECTION
      // ----------------------------------------
      match /profiles/{profileId} {
        allow read: if isOwner(userId);

        allow create: if isOwner(userId) &&
                         // Enforce profile limit based on tier
                         getProfileCount(userId) < getProfileLimit(userId);

        allow update: if isOwner(userId);

        allow delete: if isOwner(userId) &&
                         // Cannot delete default profile
                         !resource.data.isDefault;

        // Helper: Get profile count
        function getProfileCount(uid) {
          return get(/databases/$(database)/documents/users/$(uid)).data.profileCount;
        }

        // Helper: Get profile limit based on subscription
        function getProfileLimit(uid) {
          let tier = get(/databases/$(database)/documents/users/$(uid)).data.subscription.tier;
          let limits = get(/databases/$(database)/documents/app_config/limits).data;
          return tier == 'pro' ? limits.pro.maxProfiles : limits.free.maxProfiles;
        }
      }

      // ----------------------------------------
      // PLAYLISTS SUB-COLLECTION
      // ----------------------------------------
      match /playlists/{playlistId} {
        allow read: if isOwner(userId);

        allow create: if isOwner(userId) &&
                         // Validate required fields
                         request.resource.data.keys().hasAll(['name', 'type']) &&
                         // Enforce playlist limit
                         getPlaylistCount(userId) < getPlaylistLimit(userId);

        allow update: if isOwner(userId);

        allow delete: if isOwner(userId);

        function getPlaylistCount(uid) {
          return get(/databases/$(database)/documents/users/$(uid)).data.playlistCount;
        }

        function getPlaylistLimit(uid) {
          let tier = get(/databases/$(database)/documents/users/$(uid)).data.subscription.tier;
          let limits = get(/databases/$(database)/documents/app_config/limits).data;
          return tier == 'pro' ? limits.pro.maxPlaylists : limits.free.maxPlaylists;
        }
      }

      // ----------------------------------------
      // DEVICES SUB-COLLECTION
      // ----------------------------------------
      match /devices/{deviceId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
      }
    }

    // ============================================
    // ENTITLEMENTS COLLECTION (PROTECTED)
    // ============================================

    match /entitlements/{userId} {
      // Users can only read their own entitlements
      allow read: if isOwner(userId);

      // NO direct writes - only Cloud Functions can modify
      allow write: if false;

      match /purchases/{purchaseId} {
        allow read: if isOwner(userId);
        allow write: if false;
      }
    }

    // ============================================
    // APP CONFIG (ADMIN READ-ONLY)
    // ============================================

    match /app_config/{document} {
      // Anyone authenticated can read config
      allow read: if isAuthenticated();

      // Only admins can write
      allow write: if isAdmin();
    }

    // ============================================
    // ANALYTICS EVENTS (WRITE-ONLY)
    // ============================================

    match /analytics_events/{eventId} {
      // No reads from client
      allow read: if false;

      // Authenticated users can write events
      allow create: if isAuthenticated() &&
                       // Must include required fields
                       request.resource.data.keys().hasAll(['event', 'timestamp', 'deviceId']) &&
                       // Timestamp must be recent (within 5 minutes)
                       request.resource.data.timestamp >= request.time - duration.value(5, 'm');

      // No updates or deletes
      allow update, delete: if false;
    }

    // ============================================
    // DEFAULT DENY
    // ============================================

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 5.2 Security Rule Summary

| Collection | Read | Create | Update | Delete |
|------------|------|--------|--------|--------|
| `users/{userId}` | Owner only | Owner only | Owner (restricted) | Never (use CF) |
| `users/{userId}/profiles` | Owner only | Owner (with limit) | Owner only | Owner (not default) |
| `users/{userId}/playlists` | Owner only | Owner (with limit) | Owner only | Owner only |
| `users/{userId}/devices` | Owner only | Owner only | Owner only | Owner only |
| `entitlements/{userId}` | Owner only | Never | Never | Never |
| `entitlements/{userId}/purchases` | Owner only | Never | Never | Never |
| `app_config/*` | Authenticated | Admin only | Admin only | Admin only |
| `analytics_events/*` | Never | Authenticated | Never | Never |

### 5.3 Additional Security Measures

1. **Firebase App Check**: Enable to verify requests come from legitimate app instances
2. **Rate Limiting**: Implement in Cloud Functions for write operations
3. **IP Blocking**: Use Cloud Armor if abuse is detected
4. **Audit Logging**: Enable Cloud Audit Logs for sensitive collections

---

## 6. Cloud Functions

### 6.1 Function Overview

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onUserCreate` | Auth onCreate | Initialize user document |
| `onUserDelete` | Auth onDelete | Clean up user data (GDPR) |
| `verifyGooglePlayPurchase` | HTTP | Verify Google Play receipts |
| `verifyAppStorePurchase` | HTTP | Verify App Store receipts |
| `verifyAmazonPurchase` | HTTP | Verify Amazon receipts |
| `processSubscriptionWebhook` | HTTP | Handle store webhooks |
| `refreshExpiredEntitlements` | Scheduled | Check and update expired subs |
| `aggregateAnalytics` | Scheduled | Aggregate daily analytics |

### 6.2 User Lifecycle Functions

```typescript
// functions/src/users/onCreate.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL, providerData } = user;

  const providers = providerData.map(p => p.providerId);

  // Create user document
  const userDoc: UserDocument = {
    uid,
    email: email || null,
    displayName: displayName || null,
    photoURL: photoURL || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    lastSyncAt: admin.firestore.FieldValue.serverTimestamp(),
    providers,
    status: 'active',
    deletionRequestedAt: null,
    preferences: {
      language: 'en',
      theme: 'dark',
      defaultProfileId: null,
      analyticsEnabled: true,
    },
    subscription: {
      tier: 'free',
      expiresAt: null,
      platform: null,
      autoRenew: false,
    },
    fcmTokens: {},
    profileCount: 0,
    playlistCount: 0,
  };

  // Create default profile
  const defaultProfile: ProfileDocument = {
    id: `profile_${uid}_default`,
    name: displayName || 'Default',
    avatarId: 'avatar_default',
    avatarURL: photoURL || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isDefault: true,
    isKidsProfile: false,
    parentalControl: {
      enabled: false,
      pinHash: null,
      maxRating: 'TV-MA',
      blockedCategories: [],
      timeRestrictions: null,
    },
    playbackSettings: {
      defaultQuality: 'auto',
      autoPlay: true,
      subtitlesEnabled: false,
      preferredAudioLanguage: 'en',
      preferredSubtitleLanguage: 'en',
    },
    uiSettings: {
      channelGridSize: 'medium',
      showEpg: true,
      epgDaysToShow: 1,
    },
    favorites: {
      channels: [],
      movies: [],
      series: [],
    },
    recentlyWatched: [],
    continueWatching: [],
  };

  // Create entitlements document
  const entitlementsDoc: EntitlementsDocument = {
    userId: uid,
    currentTier: 'free',
    currentPlatform: null,
    expiresAt: null,
    graceEndAt: null,
    hasLifetime: false,
    isTrial: false,
    trialUsed: false,
    totalPurchases: 0,
    totalSpent: {},
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Batch write
  const batch = db.batch();

  batch.set(db.collection('users').doc(uid), userDoc);
  batch.set(
    db.collection('users').doc(uid).collection('profiles').doc(defaultProfile.id),
    defaultProfile
  );
  batch.set(db.collection('entitlements').doc(uid), entitlementsDoc);

  // Update user with default profile reference
  batch.update(db.collection('users').doc(uid), {
    'preferences.defaultProfileId': defaultProfile.id,
    profileCount: 1,
  });

  await batch.commit();

  functions.logger.info(`Created user ${uid} with default profile`);
});
```

```typescript
// functions/src/users/onDelete.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const storage = admin.storage();

export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  const { uid } = user;

  functions.logger.info(`Starting cleanup for deleted user ${uid}`);

  try {
    // Delete user document and all sub-collections
    await deleteCollection(db, `users/${uid}/profiles`);
    await deleteCollection(db, `users/${uid}/playlists`);
    await deleteCollection(db, `users/${uid}/devices`);
    await db.collection('users').doc(uid).delete();

    // Delete entitlements
    await deleteCollection(db, `entitlements/${uid}/purchases`);
    await db.collection('entitlements').doc(uid).delete();

    // Delete any uploaded files (M3U files)
    const bucket = storage.bucket();
    await bucket.deleteFiles({
      prefix: `users/${uid}/`,
    });

    // Delete analytics events (optional, or anonymize)
    // For GDPR compliance, you may want to keep anonymized data
    await anonymizeAnalyticsEvents(uid);

    functions.logger.info(`Completed cleanup for user ${uid}`);
  } catch (error) {
    functions.logger.error(`Error cleaning up user ${uid}:`, error);
    throw error;
  }
});

async function deleteCollection(db: admin.firestore.Firestore, path: string) {
  const collectionRef = db.collection(path);
  const query = collectionRef.limit(500);

  return new Promise<void>((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(
  db: admin.firestore.Firestore,
  query: admin.firestore.Query,
  resolve: () => void
) {
  const snapshot = await query.get();

  if (snapshot.size === 0) {
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  // Recurse for remaining documents
  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}

async function anonymizeAnalyticsEvents(userId: string) {
  const eventsRef = db.collection('analytics_events')
    .where('userId', '==', userId);

  const snapshot = await eventsRef.get();
  const batch = db.batch();

  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {
      userId: 'deleted_user',
      anonymizedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
}
```

### 6.3 Purchase Verification Functions

```typescript
// functions/src/purchases/verifyGooglePlay.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { google } from 'googleapis';

const db = admin.firestore();

// Service account for Google Play Developer API
const auth = new google.auth.GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});

const androidPublisher = google.androidpublisher('v3');

interface VerifyGooglePlayRequest {
  productId: string;
  purchaseToken: string;
  isSubscription: boolean;
}

interface VerifyResponse {
  success: boolean;
  entitlement?: {
    tier: string;
    expiresAt: string | null;
  };
  error?: string;
}

export const verifyGooglePlayPurchase = functions.https.onCall(
  async (data: VerifyGooglePlayRequest, context): Promise<VerifyResponse> => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const { productId, purchaseToken, isSubscription } = data;

    // Validate input
    if (!productId || !purchaseToken) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing productId or purchaseToken'
      );
    }

    try {
      const authClient = await auth.getClient();
      google.options({ auth: authClient as any });

      let purchaseData: any;
      let expiresAt: Date | null = null;
      let state = 'active';

      if (isSubscription) {
        // Verify subscription
        const response = await androidPublisher.purchases.subscriptions.get({
          packageName: functions.config().app.package_name,
          subscriptionId: productId,
          token: purchaseToken,
        });

        purchaseData = response.data;

        // Check subscription state
        // 0: Payment pending, 1: Payment received, 2: Free trial, 3: Pending deferred
        if (purchaseData.paymentState !== 1 && purchaseData.paymentState !== 2) {
          return {
            success: false,
            error: 'Payment not completed',
          };
        }

        expiresAt = new Date(parseInt(purchaseData.expiryTimeMillis));

        // Check if cancelled
        if (purchaseData.cancelReason !== undefined) {
          state = 'cancelled';
        }

        // Check for grace period
        if (purchaseData.paymentState === 0) {
          state = 'grace_period';
        }
      } else {
        // Verify one-time purchase
        const response = await androidPublisher.purchases.products.get({
          packageName: functions.config().app.package_name,
          productId: productId,
          token: purchaseToken,
        });

        purchaseData = response.data;

        // Check purchase state (0: Purchased, 1: Cancelled)
        if (purchaseData.purchaseState !== 0) {
          return {
            success: false,
            error: 'Purchase not valid',
          };
        }
      }

      // Determine tier from product ID
      const tier = getTierFromProductId(productId);

      // Store purchase record
      const purchaseDoc = {
        id: purchaseToken.substring(0, 32), // Use token prefix as ID
        platform: 'google_play',
        orderId: purchaseData.orderId || null,
        productId,
        productType: isSubscription ? 'subscription' : 'one_time',
        purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        price: null, // Google Play doesn't return price in verification
        currency: null,
        state,
        autoRenew: isSubscription ? purchaseData.autoRenewing : false,
        cancelledAt: purchaseData.userCancellationTimeMillis
          ? admin.firestore.Timestamp.fromMillis(parseInt(purchaseData.userCancellationTimeMillis))
          : null,
        refundedAt: null,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        verificationSource: 'cloud_function',
        rawReceipt: encrypt(JSON.stringify(purchaseData)),
        renewalCount: 0,
        lastRenewalAt: null,
      };

      // Update entitlements
      const batch = db.batch();

      // Add purchase record
      batch.set(
        db.collection('entitlements').doc(userId)
          .collection('purchases').doc(purchaseDoc.id),
        purchaseDoc
      );

      // Update main entitlements document
      batch.update(db.collection('entitlements').doc(userId), {
        currentTier: tier,
        currentPlatform: 'google_play',
        expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        totalPurchases: admin.firestore.FieldValue.increment(1),
      });

      // Update user document (denormalized)
      batch.update(db.collection('users').doc(userId), {
        'subscription.tier': tier,
        'subscription.expiresAt': expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        'subscription.platform': 'google_play',
        'subscription.autoRenew': purchaseData.autoRenewing || false,
      });

      await batch.commit();

      functions.logger.info(`Verified Google Play purchase for user ${userId}`, {
        productId,
        tier,
        expiresAt: expiresAt?.toISOString(),
      });

      return {
        success: true,
        entitlement: {
          tier,
          expiresAt: expiresAt?.toISOString() || null,
        },
      };
    } catch (error: any) {
      functions.logger.error('Google Play verification failed:', error);

      if (error.code === 404) {
        return {
          success: false,
          error: 'Purchase not found',
        };
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to verify purchase'
      );
    }
  }
);

function getTierFromProductId(productId: string): string {
  // Map product IDs to tiers
  const proProducts = [
    'kylos_pro_monthly',
    'kylos_pro_annual',
    'kylos_pro_lifetime',
  ];

  return proProducts.includes(productId) ? 'pro' : 'free';
}

function encrypt(data: string): string {
  // Use encryption utility from Section 4.7
  // Implementation depends on your encryption setup
  return data; // Placeholder
}
```

```typescript
// functions/src/purchases/verifyAppStore.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

// App Store endpoints
const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt';
const PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt';

interface VerifyAppStoreRequest {
  receiptData: string; // Base64 encoded receipt
}

interface VerifyResponse {
  success: boolean;
  entitlement?: {
    tier: string;
    expiresAt: string | null;
  };
  error?: string;
}

export const verifyAppStorePurchase = functions.https.onCall(
  async (data: VerifyAppStoreRequest, context): Promise<VerifyResponse> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const { receiptData } = data;

    if (!receiptData) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing receiptData'
      );
    }

    try {
      // Try production first, fallback to sandbox
      let response = await verifyWithApple(PRODUCTION_URL, receiptData);

      // Status 21007 means receipt is from sandbox
      if (response.status === 21007) {
        response = await verifyWithApple(SANDBOX_URL, receiptData);
      }

      // Check for valid status
      if (response.status !== 0) {
        return {
          success: false,
          error: `Invalid receipt: status ${response.status}`,
        };
      }

      // Find the latest subscription info
      const latestReceipt = response.latest_receipt_info?.[0];
      if (!latestReceipt) {
        return {
          success: false,
          error: 'No purchase found in receipt',
        };
      }

      const productId = latestReceipt.product_id;
      const transactionId = latestReceipt.original_transaction_id;
      const expiresAt = latestReceipt.expires_date_ms
        ? new Date(parseInt(latestReceipt.expires_date_ms))
        : null;

      // Check if expired
      if (expiresAt && expiresAt < new Date()) {
        // Check for grace period in pending_renewal_info
        const pendingRenewal = response.pending_renewal_info?.find(
          (p: any) => p.original_transaction_id === transactionId
        );

        if (!pendingRenewal || pendingRenewal.is_in_billing_retry_period !== '1') {
          return {
            success: false,
            error: 'Subscription expired',
          };
        }
      }

      const tier = getTierFromProductId(productId);

      // Check for cancellation
      const isCancelled = latestReceipt.cancellation_date_ms !== undefined;
      const state = isCancelled ? 'cancelled' : 'active';

      // Store purchase record
      const purchaseDoc = {
        id: transactionId,
        platform: 'app_store',
        transactionId,
        productId,
        productType: 'subscription',
        purchasedAt: admin.firestore.Timestamp.fromMillis(
          parseInt(latestReceipt.original_purchase_date_ms)
        ),
        expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        price: null,
        currency: null,
        state,
        autoRenew: response.pending_renewal_info?.[0]?.auto_renew_status === '1',
        cancelledAt: latestReceipt.cancellation_date_ms
          ? admin.firestore.Timestamp.fromMillis(parseInt(latestReceipt.cancellation_date_ms))
          : null,
        refundedAt: null,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        verificationSource: 'cloud_function',
        rawReceipt: encrypt(JSON.stringify(response)),
        renewalCount: 0,
        lastRenewalAt: null,
      };

      // Update entitlements (same pattern as Google Play)
      const batch = db.batch();

      batch.set(
        db.collection('entitlements').doc(userId)
          .collection('purchases').doc(purchaseDoc.id),
        purchaseDoc
      );

      batch.update(db.collection('entitlements').doc(userId), {
        currentTier: tier,
        currentPlatform: 'app_store',
        expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        totalPurchases: admin.firestore.FieldValue.increment(1),
      });

      batch.update(db.collection('users').doc(userId), {
        'subscription.tier': tier,
        'subscription.expiresAt': expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        'subscription.platform': 'app_store',
        'subscription.autoRenew': purchaseDoc.autoRenew,
      });

      await batch.commit();

      functions.logger.info(`Verified App Store purchase for user ${userId}`, {
        productId,
        tier,
        expiresAt: expiresAt?.toISOString(),
      });

      return {
        success: true,
        entitlement: {
          tier,
          expiresAt: expiresAt?.toISOString() || null,
        },
      };
    } catch (error) {
      functions.logger.error('App Store verification failed:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to verify purchase'
      );
    }
  }
);

async function verifyWithApple(url: string, receiptData: string) {
  const response = await axios.post(url, {
    'receipt-data': receiptData,
    'password': functions.config().apple.shared_secret,
    'exclude-old-transactions': true,
  });

  return response.data;
}

function getTierFromProductId(productId: string): string {
  const proProducts = [
    'kylos_pro_monthly',
    'kylos_pro_annual',
    'kylos_pro_lifetime',
  ];

  return proProducts.includes(productId) ? 'pro' : 'free';
}

function encrypt(data: string): string {
  return data; // Placeholder - use encryption utility
}
```

```typescript
// functions/src/purchases/verifyAmazon.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

// Amazon RVS (Receipt Verification Service) endpoints
const SANDBOX_URL = 'https://appstore-sdk.amazon.com/sandbox';
const PRODUCTION_URL = 'https://appstore-sdk.amazon.com/version/1.0';

interface VerifyAmazonRequest {
  userId: string;      // Amazon user ID from SDK
  receiptId: string;   // Receipt ID from purchase
}

interface VerifyResponse {
  success: boolean;
  entitlement?: {
    tier: string;
    expiresAt: string | null;
  };
  error?: string;
}

export const verifyAmazonPurchase = functions.https.onCall(
  async (data: VerifyAmazonRequest, context): Promise<VerifyResponse> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const firebaseUserId = context.auth.uid;
    const { userId: amazonUserId, receiptId } = data;

    if (!amazonUserId || !receiptId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing userId or receiptId'
      );
    }

    try {
      const developerSecret = functions.config().amazon.developer_secret;
      const baseUrl = functions.config().amazon.sandbox === 'true'
        ? SANDBOX_URL
        : PRODUCTION_URL;

      // Verify receipt with Amazon RVS
      const response = await axios.get(
        `${baseUrl}/verifyReceiptId/developer/${developerSecret}/user/${amazonUserId}/receiptId/${receiptId}`
      );

      const receiptData = response.data;

      // Check receipt validity
      if (receiptData.receiptId !== receiptId) {
        return {
          success: false,
          error: 'Receipt ID mismatch',
        };
      }

      // Check cancellation
      if (receiptData.cancelDate) {
        return {
          success: false,
          error: 'Purchase was cancelled',
        };
      }

      const productId = receiptData.productId;
      const tier = getTierFromProductId(productId);

      // For subscriptions, get term info
      let expiresAt: Date | null = null;
      if (receiptData.productType === 'SUBSCRIPTION') {
        // Amazon provides termSku which indicates subscription duration
        // Calculate expiry based on purchaseDate and term
        const purchaseDate = new Date(receiptData.purchaseDate);
        expiresAt = calculateExpiryDate(purchaseDate, receiptData.termSku);
      }

      // Store purchase record
      const purchaseDoc = {
        id: receiptId,
        platform: 'amazon',
        receiptId,
        amazonUserId,
        productId,
        productType: receiptData.productType === 'SUBSCRIPTION' ? 'subscription' : 'one_time',
        purchasedAt: admin.firestore.Timestamp.fromDate(new Date(receiptData.purchaseDate)),
        expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        price: null,
        currency: null,
        state: 'active',
        autoRenew: receiptData.productType === 'SUBSCRIPTION', // Amazon auto-renews by default
        cancelledAt: null,
        refundedAt: null,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        verificationSource: 'cloud_function',
        rawReceipt: encrypt(JSON.stringify(receiptData)),
        renewalCount: 0,
        lastRenewalAt: null,
      };

      // Update entitlements
      const batch = db.batch();

      batch.set(
        db.collection('entitlements').doc(firebaseUserId)
          .collection('purchases').doc(purchaseDoc.id),
        purchaseDoc
      );

      batch.update(db.collection('entitlements').doc(firebaseUserId), {
        currentTier: tier,
        currentPlatform: 'amazon',
        expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        totalPurchases: admin.firestore.FieldValue.increment(1),
      });

      batch.update(db.collection('users').doc(firebaseUserId), {
        'subscription.tier': tier,
        'subscription.expiresAt': expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
        'subscription.platform': 'amazon',
        'subscription.autoRenew': true,
      });

      await batch.commit();

      functions.logger.info(`Verified Amazon purchase for user ${firebaseUserId}`, {
        productId,
        tier,
        expiresAt: expiresAt?.toISOString(),
      });

      return {
        success: true,
        entitlement: {
          tier,
          expiresAt: expiresAt?.toISOString() || null,
        },
      };
    } catch (error: any) {
      functions.logger.error('Amazon verification failed:', error);

      if (error.response?.status === 400) {
        return {
          success: false,
          error: 'Invalid receipt',
        };
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to verify purchase'
      );
    }
  }
);

function getTierFromProductId(productId: string): string {
  const proProducts = [
    'kylos_pro_monthly_amazon',
    'kylos_pro_annual_amazon',
    'kylos_pro_lifetime_amazon',
  ];

  return proProducts.includes(productId) ? 'pro' : 'free';
}

function calculateExpiryDate(purchaseDate: Date, termSku: string): Date {
  const expiry = new Date(purchaseDate);

  if (termSku.includes('monthly')) {
    expiry.setMonth(expiry.getMonth() + 1);
  } else if (termSku.includes('annual')) {
    expiry.setFullYear(expiry.getFullYear() + 1);
  }

  return expiry;
}

function encrypt(data: string): string {
  return data; // Placeholder
}
```

### 6.4 Scheduled Functions

```typescript
// functions/src/scheduled/refreshEntitlements.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Runs daily to check and update expired entitlements
 */
export const refreshExpiredEntitlements = functions.pubsub
  .schedule('0 2 * * *') // Run at 2 AM UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Find entitlements expiring in the next 24 hours or already expired
    const expiringQuery = db.collection('entitlements')
      .where('currentTier', '==', 'pro')
      .where('expiresAt', '<=', admin.firestore.Timestamp.fromDate(
        new Date(now.toDate().getTime() + 24 * 60 * 60 * 1000)
      ));

    const snapshot = await expiringQuery.get();

    functions.logger.info(`Found ${snapshot.size} entitlements to check`);

    const batch = db.batch();
    let processedCount = 0;

    for (const doc of snapshot.docs) {
      const entitlement = doc.data();
      const userId = doc.id;

      // Check if actually expired
      if (entitlement.expiresAt.toDate() < now.toDate()) {
        // Check for grace period (e.g., 3 days)
        const graceEnd = new Date(entitlement.expiresAt.toDate().getTime() + 3 * 24 * 60 * 60 * 1000);

        if (new Date() > graceEnd) {
          // Grace period ended, downgrade to free
          batch.update(doc.ref, {
            currentTier: 'free',
            updatedAt: now,
          });

          batch.update(db.collection('users').doc(userId), {
            'subscription.tier': 'free',
          });

          // Send push notification
          await sendExpirationNotification(userId, 'expired');

          processedCount++;
        } else if (!entitlement.graceEndAt) {
          // Enter grace period
          batch.update(doc.ref, {
            graceEndAt: admin.firestore.Timestamp.fromDate(graceEnd),
            updatedAt: now,
          });

          await sendExpirationNotification(userId, 'grace_period');
        }
      } else {
        // Expiring soon, send reminder
        await sendExpirationNotification(userId, 'expiring_soon');
      }
    }

    if (processedCount > 0) {
      await batch.commit();
    }

    functions.logger.info(`Processed ${processedCount} expired entitlements`);
  });

async function sendExpirationNotification(userId: string, type: string) {
  const userDoc = await db.collection('users').doc(userId).get();
  const fcmTokens = userDoc.data()?.fcmTokens;

  if (!fcmTokens || Object.keys(fcmTokens).length === 0) {
    return;
  }

  const messages: { [key: string]: string } = {
    'expiring_soon': 'Your Kylos Pro subscription expires soon. Renew to keep your premium features.',
    'grace_period': 'Your Kylos Pro subscription has expired. You have 3 days to renew before losing access.',
    'expired': 'Your Kylos Pro subscription has ended. Upgrade to restore your premium features.',
  };

  const tokens = Object.values(fcmTokens).map((t: any) => t.token);

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'Kylos IPTV Player',
      body: messages[type],
    },
    data: {
      type: 'subscription_status',
      status: type,
    },
  });
}
```

```typescript
// functions/src/scheduled/aggregateAnalytics.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Aggregates daily analytics for reporting
 * Runs at 3 AM UTC daily
 */
export const aggregateAnalytics = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Query yesterday's events
    const eventsQuery = db.collection('analytics_events')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(today));

    const snapshot = await eventsQuery.get();

    // Aggregate by event type
    const aggregates: { [key: string]: number } = {};
    const platforms: { [key: string]: number } = {};
    const tiers: { [key: string]: number } = {};
    const uniqueUsers = new Set<string>();
    const uniqueDevices = new Set<string>();

    snapshot.docs.forEach((doc) => {
      const event = doc.data();

      // Count by event type
      aggregates[event.event] = (aggregates[event.event] || 0) + 1;

      // Count by platform
      const platform = event.properties?.platform || 'unknown';
      platforms[platform] = (platforms[platform] || 0) + 1;

      // Count by tier
      const tier = event.properties?.tier || 'unknown';
      tiers[tier] = (tiers[tier] || 0) + 1;

      // Track unique users/devices
      if (event.userId) uniqueUsers.add(event.userId);
      if (event.deviceId) uniqueDevices.add(event.deviceId);
    });

    // Store aggregated data
    const dateStr = yesterday.toISOString().split('T')[0];

    await db.collection('analytics_daily').doc(dateStr).set({
      date: admin.firestore.Timestamp.fromDate(yesterday),
      totalEvents: snapshot.size,
      uniqueUsers: uniqueUsers.size,
      uniqueDevices: uniqueDevices.size,
      eventCounts: aggregates,
      platformCounts: platforms,
      tierCounts: tiers,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Aggregated analytics for ${dateStr}`, {
      totalEvents: snapshot.size,
      uniqueUsers: uniqueUsers.size,
    });

    // Optionally: Delete raw events older than 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldEventsQuery = db.collection('analytics_events')
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .limit(500);

    const oldEvents = await oldEventsQuery.get();

    if (oldEvents.size > 0) {
      const batch = db.batch();
      oldEvents.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();

      functions.logger.info(`Deleted ${oldEvents.size} old analytics events`);
    }
  });
```

### 6.5 Webhook Handler

```typescript
// functions/src/webhooks/storeWebhook.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

const db = admin.firestore();

/**
 * Handle webhooks from app stores for subscription updates
 *
 * Google Play: Real-time Developer Notifications (RTDN)
 * App Store: App Store Server Notifications V2
 */
export const processSubscriptionWebhook = functions.https.onRequest(
  async (req, res) => {
    const platform = req.query.platform as string;

    try {
      switch (platform) {
        case 'google_play':
          await handleGooglePlayNotification(req.body);
          break;
        case 'app_store':
          await handleAppStoreNotification(req.body);
          break;
        default:
          res.status(400).send('Unknown platform');
          return;
      }

      res.status(200).send('OK');
    } catch (error) {
      functions.logger.error('Webhook processing failed:', error);
      res.status(500).send('Error');
    }
  }
);

async function handleGooglePlayNotification(data: any) {
  // Decode the Pub/Sub message
  const message = JSON.parse(
    Buffer.from(data.message.data, 'base64').toString()
  );

  const notification = message.subscriptionNotification;
  if (!notification) return;

  const { notificationType, purchaseToken, subscriptionId } = notification;

  functions.logger.info('Google Play notification:', {
    type: notificationType,
    subscriptionId,
  });

  // Find the user by purchase token (stored in purchases)
  const purchasesQuery = db.collectionGroup('purchases')
    .where('platform', '==', 'google_play')
    .where('id', '==', purchaseToken.substring(0, 32));

  const snapshot = await purchasesQuery.get();
  if (snapshot.empty) {
    functions.logger.warn('Purchase not found for token');
    return;
  }

  const purchaseDoc = snapshot.docs[0];
  const userId = purchaseDoc.ref.parent.parent!.id;

  // Handle notification types
  // https://developer.android.com/google/play/billing/rtdn-reference
  switch (notificationType) {
    case 1: // SUBSCRIPTION_RECOVERED
    case 2: // SUBSCRIPTION_RENEWED
      await updateSubscriptionActive(userId, subscriptionId);
      break;
    case 3: // SUBSCRIPTION_CANCELED
      await updateSubscriptionCancelled(userId, purchaseDoc.id);
      break;
    case 4: // SUBSCRIPTION_PURCHASED
      // Already handled in verifyGooglePlayPurchase
      break;
    case 5: // SUBSCRIPTION_ON_HOLD
    case 6: // SUBSCRIPTION_IN_GRACE_PERIOD
      await updateSubscriptionGracePeriod(userId);
      break;
    case 12: // SUBSCRIPTION_REVOKED
    case 13: // SUBSCRIPTION_EXPIRED
      await updateSubscriptionExpired(userId);
      break;
  }
}

async function handleAppStoreNotification(data: any) {
  // Verify signature (App Store Server Notifications V2)
  // Implementation depends on your signing setup

  const { notificationType, subtype, data: notificationData } = data;

  functions.logger.info('App Store notification:', {
    type: notificationType,
    subtype,
  });

  // Decode the signed transaction info
  // This requires JWT verification with Apple's public key

  // Find user and update accordingly
  // Similar pattern to Google Play
}

async function updateSubscriptionActive(userId: string, productId: string) {
  const batch = db.batch();

  batch.update(db.collection('entitlements').doc(userId), {
    currentTier: 'pro',
    graceEndAt: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.update(db.collection('users').doc(userId), {
    'subscription.tier': 'pro',
  });

  await batch.commit();
}

async function updateSubscriptionCancelled(userId: string, purchaseId: string) {
  const batch = db.batch();

  batch.update(
    db.collection('entitlements').doc(userId).collection('purchases').doc(purchaseId),
    {
      state: 'cancelled',
      autoRenew: false,
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    }
  );

  batch.update(db.collection('users').doc(userId), {
    'subscription.autoRenew': false,
  });

  await batch.commit();
}

async function updateSubscriptionGracePeriod(userId: string) {
  const graceEnd = new Date();
  graceEnd.setDate(graceEnd.getDate() + 3);

  await db.collection('entitlements').doc(userId).update({
    graceEndAt: admin.firestore.Timestamp.fromDate(graceEnd),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function updateSubscriptionExpired(userId: string) {
  const batch = db.batch();

  batch.update(db.collection('entitlements').doc(userId), {
    currentTier: 'free',
    graceEndAt: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.update(db.collection('users').doc(userId), {
    'subscription.tier': 'free',
    'subscription.autoRenew': false,
  });

  await batch.commit();
}
```

---

## 7. Flutter Client Integration

### 7.1 Repository Layer Architecture

```dart
// lib/infrastructure/firebase/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Central Firebase service provider
class FirebaseService {
  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseFunctions get functions => _functions;

  /// Current authenticated user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// User document reference
  DocumentReference<Map<String, dynamic>>? get userDocRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  /// Entitlements document reference
  DocumentReference<Map<String, dynamic>>? get entitlementsDocRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('entitlements').doc(uid);
  }
}
```

### 7.2 Playlist Sync Strategy

```dart
// lib/features/playlists/data/repositories/playlist_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kylos_player/core/storage/local_storage.dart';
import 'package:kylos_player/features/playlists/domain/entities/playlist_source.dart';
import 'package:kylos_player/features/playlists/domain/repositories/playlist_repository.dart';

/// Playlist repository with local-first, sync-on-demand strategy
class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl({
    required this.firebaseService,
    required this.localStorage,
    required this.encryptionService,
  });

  final FirebaseService firebaseService;
  final LocalStorage localStorage;
  final EncryptionService encryptionService;

  /// Get all playlists - local first, then sync
  @override
  Future<List<PlaylistSource>> getAllPlaylists() async {
    // 1. Return local data immediately
    final localPlaylists = await localStorage.getPlaylists();

    // 2. Check if sync is needed (based on last sync time)
    final lastSync = await localStorage.getLastPlaylistSync();
    final syncNeeded = lastSync == null ||
        DateTime.now().difference(lastSync) > const Duration(minutes: 5);

    if (syncNeeded && firebaseService.currentUserId != null) {
      // 3. Sync in background
      _syncWithRemote();
    }

    return localPlaylists;
  }

  /// Add a new playlist
  @override
  Future<PlaylistSource> addPlaylist(PlaylistSource playlist) async {
    // 1. Save locally first
    final saved = await localStorage.savePlaylist(playlist);

    // 2. Queue for remote sync
    await _queueForSync(playlist.id, SyncOperation.create);

    // 3. Attempt immediate sync if online
    await _syncPlaylist(playlist);

    return saved;
  }

  /// Update an existing playlist
  @override
  Future<void> updatePlaylist(PlaylistSource playlist) async {
    await localStorage.updatePlaylist(playlist);
    await _queueForSync(playlist.id, SyncOperation.update);
    await _syncPlaylist(playlist);
  }

  /// Delete a playlist
  @override
  Future<void> deletePlaylist(String id) async {
    await localStorage.deletePlaylist(id);
    await _queueForSync(id, SyncOperation.delete);
    await _syncDelete(id);
  }

  /// Force sync with remote
  @override
  Future<void> forcSync() async {
    await _syncWithRemote();
  }

  /// Background sync with Firestore
  Future<void> _syncWithRemote() async {
    final userId = firebaseService.currentUserId;
    if (userId == null) return;

    try {
      // Get remote playlists
      final remoteSnapshot = await firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .get();

      final remotePlaylists = remoteSnapshot.docs.map((doc) {
        return _playlistFromFirestore(doc.data(), doc.id);
      }).toList();

      // Get local playlists
      final localPlaylists = await localStorage.getPlaylists();

      // Merge strategy: remote wins for conflicts, but preserve local-only
      final merged = _mergePlaylists(localPlaylists, remotePlaylists);

      // Update local storage
      await localStorage.savePlaylists(merged);
      await localStorage.setLastPlaylistSync(DateTime.now());

      // Process pending sync queue
      await _processSyncQueue();
    } catch (e) {
      // Log error, but don't throw - local data is still valid
      print('Playlist sync failed: $e');
    }
  }

  /// Sync a single playlist to Firestore
  Future<void> _syncPlaylist(PlaylistSource playlist) async {
    final userId = firebaseService.currentUserId;
    if (userId == null) return;

    try {
      final data = _playlistToFirestore(playlist);

      await firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .doc(playlist.id)
          .set(data, SetOptions(merge: true));

      await _removeFromSyncQueue(playlist.id);
    } catch (e) {
      // Keep in sync queue for retry
      print('Playlist sync failed: $e');
    }
  }

  /// Convert playlist to Firestore document
  Map<String, dynamic> _playlistToFirestore(PlaylistSource playlist) {
    final data = {
      'id': playlist.id,
      'name': playlist.name,
      'type': playlist.type.name,
      'createdAt': playlist.createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': playlist.isActive,
      'sortOrder': playlist.sortOrder,
    };

    // Handle type-specific fields
    switch (playlist.type) {
      case PlaylistType.m3uUrl:
        data['m3uUrl'] = playlist.m3uUrl;
        break;
      case PlaylistType.xtream:
        data['xtream'] = {
          'serverUrl': playlist.xtreamConfig!.serverUrl,
          'username': playlist.xtreamConfig!.username,
          // Encrypt password before sending
          'encryptedPassword': encryptionService.encrypt(
            playlist.xtreamConfig!.password,
          ),
        };
        break;
      case PlaylistType.m3uFile:
        data['m3uFileRef'] = playlist.m3uFileRef;
        break;
    }

    return data;
  }

  /// Convert Firestore document to playlist
  PlaylistSource _playlistFromFirestore(Map<String, dynamic> data, String id) {
    XtreamConfig? xtreamConfig;

    if (data['xtream'] != null) {
      final xtream = data['xtream'] as Map<String, dynamic>;
      xtreamConfig = XtreamConfig(
        serverUrl: xtream['serverUrl'],
        username: xtream['username'],
        // Decrypt password after receiving
        password: encryptionService.decrypt(xtream['encryptedPassword']),
      );
    }

    return PlaylistSource(
      id: id,
      name: data['name'],
      type: PlaylistType.values.byName(data['type']),
      m3uUrl: data['m3uUrl'],
      xtreamConfig: xtreamConfig,
      m3uFileRef: data['m3uFileRef'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  // ... sync queue management methods
}
```

### 7.3 Entitlements Provider

```dart
// lib/features/monetization/presentation/providers/entitlements_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_player/features/monetization/domain/entities/entitlements.dart';

/// Provider for current user entitlements
final entitlementsProvider = StreamProvider<Entitlements>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final userId = firebase.currentUserId;

  if (userId == null) {
    return Stream.value(Entitlements.free());
  }

  // Listen to real-time entitlements updates
  return firebase.firestore
      .collection('entitlements')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) {
      return Entitlements.free();
    }

    final data = snapshot.data()!;
    return Entitlements(
      tier: SubscriptionTier.values.byName(data['currentTier'] ?? 'free'),
      platform: data['currentPlatform'],
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      graceEndAt: (data['graceEndAt'] as Timestamp?)?.toDate(),
      hasLifetime: data['hasLifetime'] ?? false,
      isTrial: data['isTrial'] ?? false,
    );
  });
});

/// Check if user has Pro tier
final isProProvider = Provider<bool>((ref) {
  final entitlements = ref.watch(entitlementsProvider);
  return entitlements.maybeWhen(
    data: (e) => e.isPro,
    orElse: () => false,
  );
});

/// Check if user can access a specific feature
final canAccessFeatureProvider = Provider.family<bool, ProFeature>((ref, feature) {
  final entitlements = ref.watch(entitlementsProvider);
  return entitlements.maybeWhen(
    data: (e) => e.hasFeature(feature),
    orElse: () => false,
  );
});

/// Controller for purchase operations
class PurchaseController extends StateNotifier<PurchaseState> {
  PurchaseController(this._firebase, this._iapService)
      : super(const PurchaseState.idle());

  final FirebaseService _firebase;
  final IAPService _iapService;

  /// Purchase a product and verify with backend
  Future<void> purchase(String productId) async {
    state = const PurchaseState.loading();

    try {
      // 1. Complete purchase through store
      final result = await _iapService.purchase(productId);

      if (!result.success) {
        state = PurchaseState.error(result.error!);
        return;
      }

      // 2. Verify with Cloud Function
      state = const PurchaseState.verifying();

      final HttpsCallable callable;
      final Map<String, dynamic> params;

      switch (_iapService.platform) {
        case StorePlatform.googlePlay:
          callable = _firebase.functions.httpsCallable('verifyGooglePlayPurchase');
          params = {
            'productId': productId,
            'purchaseToken': result.purchaseToken,
            'isSubscription': result.isSubscription,
          };
          break;
        case StorePlatform.appStore:
          callable = _firebase.functions.httpsCallable('verifyAppStorePurchase');
          params = {
            'receiptData': result.receiptData,
          };
          break;
        case StorePlatform.amazon:
          callable = _firebase.functions.httpsCallable('verifyAmazonPurchase');
          params = {
            'userId': result.amazonUserId,
            'receiptId': result.receiptId,
          };
          break;
      }

      final response = await callable.call(params);
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        // 3. Acknowledge the purchase (important for Google Play)
        await _iapService.acknowledgePurchase(result.purchaseToken);

        state = PurchaseState.success(
          tier: data['entitlement']['tier'],
          expiresAt: data['entitlement']['expiresAt'] != null
              ? DateTime.parse(data['entitlement']['expiresAt'])
              : null,
        );
      } else {
        state = PurchaseState.error(data['error'] ?? 'Verification failed');
      }
    } catch (e) {
      state = PurchaseState.error(e.toString());
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    state = const PurchaseState.loading();

    try {
      final purchases = await _iapService.restorePurchases();

      for (final purchase in purchases) {
        // Verify each purchase with backend
        // This ensures entitlements are updated even on new devices
        await _verifyPurchase(purchase);
      }

      state = const PurchaseState.restored();
    } catch (e) {
      state = PurchaseState.error(e.toString());
    }
  }
}
```

### 7.4 Remote Config Integration

```dart
// lib/infrastructure/remote_config/remote_config_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags available in Remote Config
enum FeatureFlag {
  tvProfileEnabled('tv_profile_enabled', false),
  newPlayerEngine('new_player_engine', false),
  epgV2('epg_v2', false),
  cloudSyncEnabled('cloud_sync_enabled', true),
  maxFreeChannels('max_free_channels', 100),
  adFrequencyMinutes('ad_frequency_minutes', 15),
  maintenanceMode('maintenance_mode', false),
  minAppVersion('min_app_version', '1.0.0'),
  forceUpdate('force_update', false);

  const FeatureFlag(this.key, this.defaultValue);

  final String key;
  final dynamic defaultValue;
}

/// Remote Config service provider
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

class RemoteConfigService {
  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with defaults
  Future<void> initialize() async {
    if (_initialized) return;

    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set defaults
    final defaults = <String, dynamic>{};
    for (final flag in FeatureFlag.values) {
      defaults[flag.key] = flag.defaultValue;
    }

    await _remoteConfig.setDefaults(defaults);

    // Configure settings
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Fetch and activate
    await _remoteConfig.fetchAndActivate();

    _initialized = true;
  }

  /// Get boolean flag
  bool getBool(FeatureFlag flag) {
    return _remoteConfig.getBool(flag.key);
  }

  /// Get integer flag
  int getInt(FeatureFlag flag) {
    return _remoteConfig.getInt(flag.key);
  }

  /// Get string flag
  String getString(FeatureFlag flag) {
    return _remoteConfig.getString(flag.key);
  }

  /// Check if app needs force update
  bool needsForceUpdate(String currentVersion) {
    if (!getBool(FeatureFlag.forceUpdate)) return false;

    final minVersion = getString(FeatureFlag.minAppVersion);
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Check if maintenance mode is active
  bool get isMaintenanceMode => getBool(FeatureFlag.maintenanceMode);

  /// Refresh config (call on app resume)
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Ignore errors, use cached values
    }
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }
}

/// Provider for individual feature flags
final featureFlagProvider = Provider.family<bool, FeatureFlag>((ref, flag) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.getBool(flag);
});

/// Provider for maintenance mode check
final maintenanceModeProvider = Provider<bool>((ref) {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.isMaintenanceMode;
});
```

### 7.5 Analytics Service

```dart
// lib/infrastructure/analytics/analytics_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Analytics events (privacy-conscious, no content details)
enum AnalyticsEvent {
  appOpen,
  appClose,
  playbackStarted,
  playbackEnded,
  playlistAdded,
  playlistRemoved,
  profileCreated,
  profileSwitched,
  searchPerformed,
  settingsChanged,
  purchaseInitiated,
  purchaseCompleted,
  purchaseFailed,
  errorOccurred,
}

/// Analytics service for privacy-conscious tracking
class AnalyticsService {
  AnalyticsService({
    required this.firebaseAnalytics,
    required this.firestore,
    required this.deviceId,
  });

  final FirebaseAnalytics firebaseAnalytics;
  final FirebaseFirestore firestore;
  final String deviceId;

  String? _userId;
  String _sessionId = const Uuid().v4();
  String? _currentTier;

  /// Set user ID for analytics
  void setUserId(String? userId) {
    _userId = userId;
    firebaseAnalytics.setUserId(id: userId);
  }

  /// Set user tier for segmentation
  void setUserTier(String tier) {
    _currentTier = tier;
    firebaseAnalytics.setUserProperty(name: 'tier', value: tier);
  }

  /// Log event (to both Firebase Analytics and Firestore)
  Future<void> logEvent(
    AnalyticsEvent event, {
    Map<String, dynamic>? properties,
  }) async {
    final eventName = event.name;

    // Log to Firebase Analytics
    await firebaseAnalytics.logEvent(
      name: eventName,
      parameters: properties,
    );

    // Log to Firestore for custom analytics
    // Only log if user has analytics enabled
    if (_userId != null) {
      await firestore.collection('analytics_events').add({
        'userId': _userId,
        'sessionId': _sessionId,
        'deviceId': deviceId,
        'event': eventName,
        'timestamp': FieldValue.serverTimestamp(),
        'properties': {
          ...?properties,
          'platform': _getPlatform(),
          'appVersion': _getAppVersion(),
          'tier': _currentTier,
        },
      });
    }
  }

  /// Log playback start (without content details for privacy)
  Future<void> logPlaybackStarted({
    required String contentType, // 'channel', 'movie', 'episode'
    bool isLive = false,
  }) async {
    await logEvent(AnalyticsEvent.playbackStarted, properties: {
      'content_type': contentType,
      'is_live': isLive,
    });
  }

  /// Log error (without sensitive details)
  Future<void> logError({
    required String errorType,
    String? errorCode,
    String? screen,
  }) async {
    await logEvent(AnalyticsEvent.errorOccurred, properties: {
      'error_type': errorType,
      'error_code': errorCode,
      'screen': screen,
    });
  }

  /// Start new session
  void startSession() {
    _sessionId = const Uuid().v4();
    logEvent(AnalyticsEvent.appOpen);
  }

  /// End session
  void endSession() {
    logEvent(AnalyticsEvent.appClose);
  }

  String _getPlatform() {
    // Return platform identifier
    return 'android'; // Implement platform detection
  }

  String _getAppVersion() {
    // Return app version
    return '1.0.0'; // Implement version detection
  }
}
```

---

## 8. Cost Estimation

### 8.1 Firebase Pricing Model

| Service | Free Tier | Paid Pricing |
|---------|-----------|--------------|
| Authentication | Unlimited | $0.0055/verification (phone) |
| Firestore | 1GB storage, 50K reads/day | $0.18/100K reads, $0.18/100K writes |
| Cloud Functions | 2M invocations/month | $0.40/million invocations |
| Cloud Storage | 5GB | $0.026/GB/month |
| FCM | Unlimited | Free |
| Remote Config | Unlimited | Free |

### 8.2 Cost Projections

#### 10,000 Monthly Active Users (MAU)

```
Authentication: Free
Firestore:
  - Reads: ~500K/month (50 reads/user/day) = ~$0.90
  - Writes: ~100K/month (10 writes/user/day) = ~$0.18
  - Storage: ~1GB = Free tier
Cloud Functions:
  - IAP verifications: ~1K/month = Free tier
  - Scheduled jobs: ~1K/month = Free tier
FCM: Free
Remote Config: Free

Total: ~$1-5/month
```

#### 100,000 MAU

```
Authentication: Free
Firestore:
  - Reads: ~5M/month = ~$9
  - Writes: ~1M/month = ~$1.80
  - Storage: ~10GB = ~$0.26
Cloud Functions:
  - IAP verifications: ~10K/month = Free tier
  - Scheduled jobs: ~1K/month = Free tier
  - Other: ~50K/month = Free tier
FCM: Free
Remote Config: Free

Total: ~$10-20/month
```

#### 1,000,000 MAU

```
Authentication: Free
Firestore:
  - Reads: ~50M/month = ~$90
  - Writes: ~10M/month = ~$18
  - Storage: ~100GB = ~$2.60
Cloud Functions:
  - All invocations: ~500K/month = ~$0.20
FCM: Free
Remote Config: Free

Total: ~$100-150/month
```

### 8.3 Cost Optimization Strategies

1. **Aggressive caching**: Use local storage to minimize Firestore reads
2. **Batch writes**: Combine multiple updates into single writes
3. **Selective sync**: Only sync changed data, not full documents
4. **Pagination**: Load data in chunks, not all at once
5. **Offline-first**: Minimize network calls for frequently accessed data

---

## 9. Monitoring and Operations

### 9.1 Monitoring Setup

| Tool | Purpose |
|------|---------|
| Firebase Console | Real-time monitoring, usage metrics |
| Cloud Monitoring | Custom dashboards, alerts |
| Crashlytics | Error tracking, crash reports |
| Performance Monitoring | App performance metrics |

### 9.2 Alerts Configuration

```yaml
# Example Cloud Monitoring alert policies

alerts:
  - name: "High Error Rate"
    condition: "error_count > 100 in 5 minutes"
    notification: "email, slack"

  - name: "Firestore Quota Warning"
    condition: "firestore_reads > 80% of quota"
    notification: "email"

  - name: "Cloud Function Failures"
    condition: "function_error_rate > 5%"
    notification: "email, slack"

  - name: "Authentication Failures"
    condition: "auth_failure_rate > 10%"
    notification: "email"
```

### 9.3 Backup Strategy

1. **Firestore exports**: Daily automated exports to Cloud Storage
2. **Retention**: Keep 30 days of backups
3. **Point-in-time recovery**: Enabled for production database

### 9.4 Security Checklist

- [ ] Firebase App Check enabled
- [ ] Security rules deployed and tested
- [ ] Cloud Functions use least-privilege service accounts
- [ ] Encryption keys stored in Secret Manager
- [ ] Audit logging enabled
- [ ] Regular security rule reviews scheduled

---

## Summary

This backend architecture provides:

1. **Scalable authentication** with multiple providers and anonymous upgrade path
2. **Secure data storage** with proper encryption for sensitive credentials
3. **Robust entitlements** system with multi-store IAP verification
4. **Privacy-conscious analytics** without tracking sensitive content
5. **Flexible feature flags** for gradual rollouts and A/B testing
6. **Cost-effective operations** with Firebase's pay-as-you-go model

The design prioritizes security, privacy, and compliance while remaining simple enough for a small team to maintain and scale as the user base grows.
