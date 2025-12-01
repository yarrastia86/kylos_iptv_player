# Security and Privacy Hardening

This document describes the security and privacy measures implemented in Kylos IPTV Player to protect user data and prevent abuse.

## Table of Contents

1. [Threat Model](#threat-model)
2. [Client-Side Hardening](#client-side-hardening)
3. [Secure Storage](#secure-storage)
4. [Logging and Privacy](#logging-and-privacy)
5. [Firebase Security](#firebase-security)
6. [Build Configuration](#build-configuration)
7. [Recommended Production Measures](#recommended-production-measures)
8. [Manual Setup Steps](#manual-setup-steps)
   - [1. Android Signing Keystore Setup](#1-android-signing-keystore-setup)
   - [2. iOS Code Signing Setup](#2-ios-code-signing-setup)
   - [3. Firebase Project Setup](#3-firebase-project-setup)
   - [4. Deploy Firestore Security Rules](#4-deploy-firestore-security-rules)
   - [5. Enable Firebase App Check](#5-enable-firebase-app-check)
   - [6. Enable Firebase Crashlytics](#6-enable-firebase-crashlytics)
   - [7. Initialize App Logger](#7-initialize-app-logger)
   - [8. Implement Purchase Verification Cloud Function](#8-implement-purchase-verification-cloud-function)
   - [9. Build Release with Obfuscation](#9-build-release-with-obfuscation)
   - [10. Pre-Release Verification Checklist](#10-pre-release-verification-checklist)
9. [Files Created/Modified](#files-createdmodified)
10. [Summary](#summary)

---

## Threat Model

### Key Assets

| Asset | Sensitivity | Storage Location | Protection Measures |
|-------|-------------|------------------|---------------------|
| Firebase Auth Tokens | High | Device Keychain/Keystore | Encrypted at rest, short expiry |
| IPTV Credentials (passwords) | High | Secure Storage + Firestore | AES-256-GCM encryption |
| Playlist URLs | Medium | Device + Firestore | May contain auth tokens in URL |
| User Preferences | Low | SharedPreferences + Firestore | Owner-only access rules |
| Entitlements/Purchases | High | Firestore (server-managed) | Cloud Function writes only |
| Watch History | Low | Firestore | Owner-only access rules |

### Threat Actors

1. **Casual Attacker**: Limited technical skills, uses publicly available tools
2. **Skilled Attacker**: Can reverse engineer APKs, use debugging tools
3. **Malicious User**: Legitimate user attempting to abuse backend APIs
4. **Competitor**: May attempt to scrape content or user data

### Main Threats

#### T1: App Reverse Engineering and Tampering

**Description**: Attacker decompiles the APK/IPA to extract secrets or modify app behavior.

**Impact**:
- API keys/endpoints exposed
- License checks bypassed
- App repackaged with malware

**Mitigations**:
- Code obfuscation via R8/ProGuard (implemented)
- No hardcoded secrets - use Remote Config or environment variables
- Optional integrity checking (implemented)
- Certificate pinning (recommended for production)

**Residual Risk**: Medium - Determined attackers can still reverse engineer

#### T2: Credential Leakage

**Description**: IPTV provider credentials leaked via logs, crash reports, or insecure storage.

**Impact**:
- User's IPTV subscription compromised
- Potential credential reuse attacks

**Mitigations**:
- Secure storage for credentials (implemented)
- Privacy-aware logging that redacts sensitive data (implemented)
- Firestore encryption for stored passwords (documented)

**Residual Risk**: Low

#### T3: Unauthorized Data Access

**Description**: User A accesses User B's playlists, watch history, or purchases.

**Impact**:
- Privacy violation
- Potential for targeted attacks

**Mitigations**:
- Firestore security rules enforce owner-only access (implemented)
- Server-side validation for all sensitive operations
- No direct Firestore writes for entitlements

**Residual Risk**: Low (if rules are properly deployed)

#### T4: Backend API Abuse

**Description**: Automated scripts or modified apps abuse Firebase APIs.

**Impact**:
- Increased infrastructure costs
- Denial of service
- Data scraping

**Mitigations**:
- Firebase App Check (configured)
- Rate limiting via Cloud Functions (recommended)
- Anomaly detection (recommended)

**Residual Risk**: Medium without App Check enabled

#### T5: Purchase Fraud

**Description**: Fake purchase receipts submitted to unlock premium features.

**Impact**:
- Revenue loss
- Unfair advantage for fraudulent users

**Mitigations**:
- Server-side receipt verification via Cloud Functions (documented)
- Entitlements written only by Cloud Functions (enforced via rules)
- Purchase state validated against store APIs

**Residual Risk**: Low with proper implementation

---

## Client-Side Hardening

### Code Obfuscation

Release builds are obfuscated using R8 (Android) and Apple's compiler optimizations (iOS).

#### Flutter Obfuscation

Add these flags to your release build command:

```bash
# Android release with obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# iOS release with obfuscation
flutter build ios --release --obfuscate --split-debug-info=build/debug-info

# App bundle for Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

The `--split-debug-info` flag saves symbol maps for crash report symbolication.

#### Android ProGuard/R8

R8 is configured in `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

Custom rules are in `android/app/proguard-rules.pro`.

### Integrity Checking

The `IntegrityChecker` class provides optional runtime checks:

```dart
// lib/core/security/integrity_checker.dart

final checker = IntegrityChecker(config: IntegrityConfig.permissive);
final result = await checker.checkIntegrity();

if (result.isDebugMode) {
  // Running in debug mode
}
if (result.hasRootIndicators) {
  // Root/jailbreak indicators detected
}
```

**Configuration Options**:

| Config | Debug Detection | Root Detection | Emulator Detection | Blocking |
|--------|-----------------|----------------|-------------------|----------|
| `permissive` | Yes | Yes | Yes | None |
| `strict` | Yes | Yes | Yes | Debug + Emulator |
| `disabled` | No | No | No | None |

**Important**: Root detection has false positives. Do NOT block users based solely on root detection.

### iOS Hardening Notes

iOS-specific hardening is primarily handled at build time:

1. **Bitcode** (deprecated in Xcode 14+): No longer needed
2. **App Thinning**: Enabled by default for App Store builds
3. **Keychain Access**: Configured in `SecureStorageService`

For additional iOS hardening, add to your Xcode project:
- Enable "Strip Debug Symbols During Copy" for Release
- Set "Deployment Postprocessing" to YES
- Consider Automatic Reference Counting (ARC) for native code

---

## Secure Storage

### Architecture

```
lib/core/security/
├── secure_storage_service.dart    # Abstract interface + Flutter implementation
├── credential_manager.dart        # High-level credential operations
├── integrity_checker.dart         # Device integrity verification
└── security_providers.dart        # Riverpod providers
```

### SecureStorageService

Platform-agnostic interface for encrypted storage:

```dart
abstract class SecureStorageService {
  Future<SecureStorageResult<String?>> read(String key);
  Future<SecureStorageResult<void>> write(String key, String value);
  Future<SecureStorageResult<void>> delete(String key);
  Future<SecureStorageResult<void>> deleteAll();
}
```

**Platform Implementation**:

| Platform | Storage Backend | Encryption |
|----------|-----------------|------------|
| iOS | Keychain Services | Hardware-backed (Secure Enclave on supported devices) |
| Android | EncryptedSharedPreferences | AES-256-GCM, keys in Android Keystore |
| macOS | Keychain Services | Hardware-backed |

### Credential Manager

High-level API for managing IPTV provider credentials:

```dart
final credentialManager = ref.watch(credentialManagerProvider);

// Cache credentials securely
await credentialManager.cacheCredentials(
  CachedPlaylistCredentials(
    playlistId: 'playlist-123',
    serverUrl: 'https://provider.com',
    username: 'user',
    password: 'secret',
  ),
);

// Retrieve cached credentials
final creds = await credentialManager.getCredentials('playlist-123');

// Clear on logout
await credentialManager.clearAllCredentials();

// Full wipe (logout + reset)
await credentialManager.clearAllSecureData();
```

### Data Clearing Procedures

#### User Logout

```dart
// Clear cached credentials but preserve app settings
await credentialManager.clearAllCredentials();
await authService.signOut();
```

#### Account Deletion

```dart
// Clear all secure data
await credentialManager.clearAllSecureData();

// Clear local storage
await localStorage.clear();

// Delete Firestore data (via Cloud Function)
await deleteAccountFunction();
```

#### App Reset

```dart
// Clear everything
await credentialManager.clearAllSecureData();
await localStorage.clear();
// Note: Firestore data remains until explicit deletion
```

---

## Logging and Privacy

### Privacy Guidelines

**MUST NOT Log**:
- Passwords (IPTV, Firebase, any authentication)
- Full authentication tokens (only last 4 characters if debugging)
- Playlist URLs (may contain credentials)
- User IP addresses
- Device identifiers that enable tracking
- Full email addresses (use anonymized form)

**MAY Log**:
- Error codes and types (without user data)
- Anonymous feature usage events
- Performance metrics
- App lifecycle events
- Firebase UID (opaque identifier)

### Logger Usage

```dart
// Initialize at app startup
AppLogger.initialize(
  config: kDebugMode
    ? LoggerConfig.development
    : LoggerConfig.production,
);

// Get a tagged logger
final logger = AppLogger.tagged('Playback');

// Log with automatic privacy filtering
logger.info('Stream started', metadata: {'type': 'live'});
logger.error('Playback failed', error: e, stackTrace: st);

// Sensitive data is automatically redacted:
logger.debug('Connecting to: $url');
// Outputs: "Connecting to: https://[REDACTED]@..." if URL contains credentials
```

### Crashlytics Integration

To enable Firebase Crashlytics:

1. Add to `pubspec.yaml` (already added):
```yaml
firebase_crashlytics: ^3.4.8
```

2. Initialize in `bootstrap.dart`:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// After Firebase.initializeApp()
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

3. Update `CrashlyticsLogOutput` in `app_logger.dart` to send logs.

---

## Firebase Security

### Firestore Security Rules

The rules are in `firebase/firestore.rules`. Key principles:

1. **Default Deny**: No access unless explicitly granted
2. **Owner-Only Access**: Users can only access their own documents
3. **Server-Side Entitlements**: Purchase status can only be written by Cloud Functions
4. **Data Validation**: Field types and constraints enforced at database level

#### Deploying Rules

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy rules only
firebase deploy --only firestore:rules

# Deploy rules and indexes
firebase deploy --only firestore
```

#### Testing Rules

Use the Firebase Emulator:

```bash
firebase emulators:start --only firestore

# Run security rules tests
npm test
```

### Firebase App Check

App Check verifies that requests come from legitimate app installations.

#### Android Setup

1. Register your app in Firebase Console > App Check
2. Choose Play Integrity as the attestation provider
3. Add to `android/app/build.gradle`:
```gradle
implementation 'com.google.firebase:firebase-appcheck-playintegrity'
```

4. Initialize in Dart:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
```

#### iOS Setup

1. Register your app in Firebase Console > App Check
2. Choose App Attest or DeviceCheck
3. Initialize in Dart:
```dart
await FirebaseAppCheck.instance.activate(
  appleProvider: AppleProvider.appAttest,
);
```

### Cloud Functions for Security

Sensitive operations should use Cloud Functions:

```typescript
// functions/src/verifyPurchase.ts
import * as functions from 'firebase-functions';

export const verifyPurchase = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  // Verify App Check token
  if (context.app?.appId !== 'YOUR_APP_ID') {
    throw new functions.https.HttpsError('permission-denied', 'Invalid app');
  }

  // Verify receipt with store API
  const { platform, receipt } = data;
  const isValid = await verifyWithStore(platform, receipt);

  if (isValid) {
    // Update entitlement in Firestore
    await admin.firestore()
      .collection('entitlements')
      .doc(context.auth.uid)
      .set({ isActive: true, /* ... */ });
  }

  return { success: isValid };
});
```

---

## Build Configuration

### Android

The `android/app/build.gradle` file configures:

| Setting | Debug | Release |
|---------|-------|---------|
| `minifyEnabled` | false | true |
| `shrinkResources` | false | true |
| `debuggable` | true | false |
| `applicationIdSuffix` | `.debug` | (none) |

### ProGuard Rules

Key rules in `android/app/proguard-rules.pro`:

- Flutter framework preservation
- Firebase SDK preservation
- media_kit native methods
- flutter_secure_storage reflection
- Kotlin metadata

### iOS

iOS security settings are in Xcode:

1. **Code Signing**: Use Distribution certificate for release
2. **Entitlements**: Keychain sharing for secure storage
3. **Info.plist**:
   - `NSAppTransportSecurity` - enforce TLS
   - `ITSAppUsesNonExemptEncryption` - set to NO (or YES with export compliance)

---

## Recommended Production Measures

### High Priority

1. **Enable Firebase App Check** - Prevents API abuse from unofficial clients
2. **Deploy Firestore Rules** - Essential for data protection
3. **Enable Crashlytics** - For error monitoring
4. **Use Cloud Functions** - For purchase verification

### Medium Priority

1. **Certificate Pinning** - Prevents MITM attacks
   - Use `dio_certificate_pinning` or custom implementation
   - Maintain pin backup for certificate rotation

2. **Advanced Tamper Detection** - Consider third-party SDKs:
   - FreeRASP (open source)
   - Approov (commercial)

3. **Runtime Application Self-Protection (RASP)** - For high-security needs

### Lower Priority

1. **Code Signing Verification** - Verify APK signature at runtime
2. **Anti-Debugging** - Detect and respond to debugger attachment
3. **Emulator Blocking** - Block emulator access (may harm legitimate users)

---

## Manual Setup Steps

This section provides detailed step-by-step instructions for all manual configuration required before shipping to production.

---

### 1. Android Signing Keystore Setup

The keystore is required for signing release builds. Keep this file secure - losing it means you cannot update your app on the Play Store.

#### Step 1.1: Generate a New Keystore

```bash
# Navigate to your project's android directory
cd android

# Generate a new keystore (interactive prompts)
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# You will be prompted for:
# - Keystore password (remember this!)
# - Key password (can be same as keystore password)
# - Your name, organization, location info
```

#### Step 1.2: Create key.properties File

Create `android/key.properties` (this file is gitignored):

```properties
storePassword=your_keystore_password_here
keyPassword=your_key_password_here
keyAlias=upload
storeFile=../upload-keystore.jks
```

#### Step 1.3: Secure the Keystore

```bash
# CRITICAL: Backup the keystore to a secure location
# Options:
# - Password manager (1Password, Bitwarden)
# - Encrypted cloud storage
# - Hardware security module (enterprise)

# Never commit the keystore or key.properties to git
# Verify .gitignore contains:
#   *.jks
#   *.keystore
#   key.properties
```

#### Step 1.4: Add to CI/CD (GitHub Actions)

```bash
# Encode keystore for GitHub Secrets
base64 -i android/upload-keystore.jks | pbcopy  # macOS
base64 -w 0 android/upload-keystore.jks         # Linux

# Add these secrets in GitHub repo settings:
# ANDROID_KEYSTORE_BASE64: (paste the base64 output)
# ANDROID_KEYSTORE_PASSWORD: your_keystore_password
# ANDROID_KEY_ALIAS: upload
# ANDROID_KEY_PASSWORD: your_key_password
```

---

### 2. iOS Code Signing Setup

#### Step 2.1: Create Distribution Certificate

1. Open **Keychain Access** on your Mac
2. Go to **Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority**
3. Enter your email and select "Saved to disk"
4. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
5. Click **+** to create a new certificate
6. Select **Apple Distribution** (for App Store)
7. Upload the certificate signing request
8. Download and double-click to install in Keychain

#### Step 2.2: Create Provisioning Profile

1. Go to [Apple Developer Portal > Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click **+** to create a new profile
3. Select **App Store** under Distribution
4. Select your app's Bundle ID
5. Select the distribution certificate you created
6. Name it (e.g., "Kylos IPTV App Store")
7. Download and double-click to install

#### Step 2.3: Export for CI/CD

```bash
# Export certificate as .p12 from Keychain Access:
# 1. Open Keychain Access
# 2. Find "Apple Distribution: Your Name" certificate
# 3. Right-click > Export
# 4. Save as .p12 with a strong password

# Encode for GitHub Secrets
base64 -i Certificates.p12 | pbcopy

# Encode provisioning profile
base64 -i Kylos_IPTV_App_Store.mobileprovision | pbcopy

# Add these secrets in GitHub:
# IOS_CERTIFICATE_BASE64: (certificate base64)
# IOS_CERTIFICATE_PASSWORD: (export password)
# IOS_PROVISIONING_PROFILE_BASE64: (profile base64)
```

#### Step 2.4: Configure Xcode Project

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target > **Signing & Capabilities**
3. For Release configuration:
   - Uncheck "Automatically manage signing"
   - Select your provisioning profile
   - Ensure Bundle Identifier matches the profile

---

### 3. Firebase Project Setup

#### Step 3.1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add project**
3. Name it (e.g., "Kylos IPTV Player")
4. Enable/disable Google Analytics as desired
5. Click **Create project**

#### Step 3.2: Add Android App

1. In Firebase Console, click **Add app > Android**
2. Enter package name: `com.kylos.iptvplayer`
3. Enter app nickname: "Kylos IPTV Android"
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

#### Step 3.3: Add iOS App

1. Click **Add app > iOS**
2. Enter Bundle ID: `com.kylos.iptvplayer`
3. Enter app nickname: "Kylos IPTV iOS"
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/GoogleService-Info.plist`
6. Open Xcode and add the file to the Runner target

#### Step 3.4: Enable Firebase Services

In Firebase Console, enable these services:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable: Email/Password, Google, Anonymous

2. **Cloud Firestore**
   - Go to Firestore Database
   - Create database in production mode
   - Select your preferred region

3. **Remote Config**
   - Go to Remote Config
   - Create your first parameter (can be a placeholder)

---

### 4. Deploy Firestore Security Rules

#### Step 4.1: Install Firebase CLI

```bash
# Install globally via npm
npm install -g firebase-tools

# Or via standalone installer
curl -sL https://firebase.tools | bash

# Verify installation
firebase --version
```

#### Step 4.2: Login and Initialize

```bash
# Login to Firebase
firebase login

# Initialize Firebase in project root
cd /path/to/iptv-player
firebase init

# Select:
# - Firestore (for rules and indexes)
# - Functions (if implementing Cloud Functions)

# Choose your Firebase project
# Accept default file locations
```

#### Step 4.3: Deploy Rules

```bash
# Deploy security rules only
firebase deploy --only firestore:rules

# Deploy rules and indexes
firebase deploy --only firestore

# Verify deployment in Firebase Console > Firestore > Rules
```

#### Step 4.4: Test Rules with Emulator

```bash
# Start local emulator
firebase emulators:start --only firestore

# Access emulator UI at http://localhost:4000

# Run your app against emulator by setting environment:
# In your Dart code (debug only):
# FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

---

### 5. Enable Firebase App Check

App Check protects your backend from abuse by verifying requests come from your genuine app.

#### Step 5.1: Android (Play Integrity)

1. Go to Firebase Console > App Check
2. Click **Register** for your Android app
3. Select **Play Integrity** as the attestation provider
4. Note: Play Integrity requires your app to be published on Play Store (even internal testing track)

For debug builds, register a debug token:
```bash
# Run your app in debug mode
# Look for this log: "Debug App Check token: ..."
# Register this token in Firebase Console > App Check > Apps > Manage debug tokens
```

#### Step 5.2: iOS (App Attest)

1. Go to Firebase Console > App Check
2. Click **Register** for your iOS app
3. Select **App Attest** as the attestation provider
4. App Attest requires iOS 14+ and real devices (not simulators)

For development, use DeviceCheck (supports iOS 11+) or debug tokens.

#### Step 5.3: Enforce App Check

1. Go to Firebase Console > App Check
2. For each service (Firestore, Auth, etc.):
   - Click the service
   - Click **Enforce**
   - This blocks requests without valid App Check tokens

**Warning**: Only enforce after testing thoroughly. Enforcement blocks all requests from apps without valid tokens.

#### Step 5.4: Initialize in App

Update `lib/bootstrap.dart`:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    // Use debug provider in debug builds
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttest,
  );

  // ... rest of initialization
}
```

---

### 6. Enable Firebase Crashlytics

#### Step 6.1: Enable in Firebase Console

1. Go to Firebase Console > Crashlytics
2. Click **Enable Crashlytics**
3. Follow the setup wizard

#### Step 6.2: Configure Android

Add to `android/app/build.gradle`:

```gradle
// At the top of the file
plugins {
    // ... existing plugins
    id 'com.google.firebase.crashlytics'
}

android {
    // ... existing config

    buildTypes {
        release {
            // Enable Crashlytics mapping file upload
            firebaseCrashlytics {
                mappingFileUploadEnabled true
                nativeSymbolUploadEnabled true
            }
        }
    }
}
```

Add to `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}
```

#### Step 6.3: Configure iOS

Crashlytics for iOS requires a build phase script:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Build Phases**
4. Click **+** > **New Run Script Phase**
5. Name it "Firebase Crashlytics"
6. Add this script:
```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```
7. Add input files:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)
```

#### Step 6.4: Initialize in App

Update `lib/bootstrap.dart`:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Optionally, set user identifier for crash reports
  // FirebaseCrashlytics.instance.setUserIdentifier(userId);

  // ... rest of initialization
}
```

---

### 7. Initialize App Logger

Update `lib/bootstrap.dart` to initialize the logger early:

```dart
import 'package:flutter/foundation.dart';
import 'package:kylos_iptv_player/core/logging/app_logger.dart';

Future<void> bootstrap() async {
  // Initialize logger first for early error capture
  AppLogger.initialize(
    config: kDebugMode
        ? LoggerConfig.development
        : LoggerConfig.production,
  );

  final logger = AppLogger.tagged('Bootstrap');
  logger.info('App starting');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    // ... rest of initialization
    logger.info('Initialization complete');
  } catch (e, st) {
    logger.fatal('Initialization failed', error: e, stackTrace: st);
    rethrow;
  }
}
```

---

### 8. Implement Purchase Verification Cloud Function

#### Step 8.1: Initialize Cloud Functions

```bash
cd /path/to/iptv-player
firebase init functions

# Select TypeScript
# Enable ESLint
# Install dependencies
```

#### Step 8.2: Create Verification Function

Create `functions/src/verifyPurchase.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface PurchaseRequest {
  platform: 'google_play' | 'app_store' | 'amazon';
  productId: string;
  purchaseToken: string;
  transactionId?: string;
}

export const verifyPurchase = functions.https.onCall(
  async (data: PurchaseRequest, context) => {
    // Require authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be signed in to verify purchases'
      );
    }

    // Require App Check (if enforced)
    // if (!context.app) {
    //   throw new functions.https.HttpsError(
    //     'failed-precondition',
    //     'App Check token required'
    //   );
    // }

    const userId = context.auth.uid;
    const { platform, productId, purchaseToken } = data;

    try {
      // TODO: Implement platform-specific verification
      // See:
      // - Google Play: https://developers.google.com/android-publisher/api-ref/rest
      // - App Store: https://developer.apple.com/documentation/appstoreserverapi
      // - Amazon: https://developer.amazon.com/docs/in-app-purchasing/iap-rvs.html

      const isValid = await verifyWithStore(platform, productId, purchaseToken);

      if (isValid) {
        // Update entitlement in Firestore
        await admin.firestore()
          .collection('entitlements')
          .doc(userId)
          .set({
            isActive: true,
            tier: 'pro',
            platform,
            productId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            expirationDate: calculateExpiration(productId),
          }, { merge: true });

        // Record purchase
        await admin.firestore()
          .collection('entitlements')
          .doc(userId)
          .collection('purchases')
          .add({
            productId,
            platform,
            purchaseToken,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'verified',
          });

        return { success: true, message: 'Purchase verified' };
      } else {
        return { success: false, message: 'Invalid purchase' };
      }
    } catch (error) {
      console.error('Purchase verification failed:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Purchase verification failed'
      );
    }
  }
);

async function verifyWithStore(
  platform: string,
  productId: string,
  token: string
): Promise<boolean> {
  // TODO: Implement actual store verification
  // This is a placeholder
  return true;
}

function calculateExpiration(productId: string): admin.firestore.Timestamp {
  // TODO: Calculate based on subscription duration
  const expirationDate = new Date();
  expirationDate.setMonth(expirationDate.getMonth() + 1);
  return admin.firestore.Timestamp.fromDate(expirationDate);
}
```

#### Step 8.3: Deploy Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

---

### 9. Build Release with Obfuscation

#### Step 9.1: Android Release Build

```bash
# Ensure key.properties is configured
# Build obfuscated APK
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

# Build obfuscated App Bundle (for Play Store)
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

# The symbols directory contains mapping files for crash symbolication
# Upload these to Firebase Crashlytics or archive them
```

#### Step 9.2: iOS Release Build

```bash
# Build obfuscated iOS app
flutter build ios --release \
  --obfuscate \
  --split-debug-info=build/ios/outputs/symbols

# Archive for App Store
# Open Xcode: ios/Runner.xcworkspace
# Product > Archive
# Distribute App > App Store Connect
```

#### Step 9.3: Preserve Debug Symbols

```bash
# Archive symbols with version tag
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')
zip -r "symbols-v${VERSION}.zip" build/app/outputs/symbols

# Upload to Firebase Crashlytics for symbolication
# Or archive in secure storage for later debugging
```

---

### 10. Pre-Release Verification Checklist

Run through this checklist before every release:

#### Build Verification

- [ ] Release build completes without errors
- [ ] Obfuscation flags are applied
- [ ] Debug symbols are archived
- [ ] APK/IPA size is reasonable (no unexpected bloat)

#### Security Verification

- [ ] No sensitive data in logs (test with release build)
- [ ] Secure storage works on real device
- [ ] Firebase Auth works correctly
- [ ] Firestore rules are deployed and tested

#### Functionality Verification

- [ ] App launches without crashes
- [ ] Login/logout flows work
- [ ] Playlist addition and playback work
- [ ] In-app purchases complete successfully
- [ ] Push notifications received (if applicable)

#### Store Compliance

- [ ] Privacy policy URL is valid
- [ ] App permissions are justified
- [ ] Content ratings are accurate
- [ ] Screenshots and descriptions updated

---

### Periodic Maintenance Tasks

#### Monthly

- [ ] Review Crashlytics for new crash patterns
- [ ] Check App Check metrics for abuse attempts
- [ ] Review Firebase usage and billing
- [ ] Update dependencies with security patches

#### Quarterly

- [ ] Rotate any exposed API keys
- [ ] Review Firestore security rules
- [ ] Audit user data access patterns
- [ ] Test backup and recovery procedures

#### Annually

- [ ] Renew iOS distribution certificate (before expiry)
- [ ] Review and update provisioning profiles
- [ ] Audit third-party SDK security
- [ ] Conduct penetration testing (recommended)

---

## Files Created/Modified

| File | Purpose |
|------|---------|
| `lib/core/security/secure_storage_service.dart` | Secure storage abstraction |
| `lib/core/security/credential_manager.dart` | IPTV credential management |
| `lib/core/security/integrity_checker.dart` | Device integrity verification |
| `lib/core/security/security_providers.dart` | Riverpod providers |
| `lib/core/logging/app_logger.dart` | Privacy-aware logging |
| `lib/core/logging/logging_providers.dart` | Logger providers |
| `android/app/build.gradle` | Android build configuration |
| `android/app/proguard-rules.pro` | R8 obfuscation rules |
| `firebase/firestore.rules` | Firestore security rules |
| `firebase/firestore.indexes.json` | Firestore indexes |

---

## Summary

This security hardening provides:

1. **Defense in Depth**: Multiple layers of protection
2. **Privacy by Design**: Sensitive data encrypted and redacted from logs
3. **Minimal User Impact**: Detection over blocking for most checks
4. **Auditability**: Clear documentation and commented code
5. **Production Readiness**: All major threats addressed with clear next steps

The current implementation raises the bar significantly for casual attackers while remaining user-friendly. For applications handling financial data or requiring regulatory compliance, consider the recommended advanced measures.
