# Kylos IPTV Player

A cross-platform IPTV media player application built with Flutter for Android, iOS, Android TV, and Fire TV.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Platforms](#supported-platforms)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [Building for Production](#building-for-production)
- [Configuration](#configuration)
- [Dependencies](#dependencies)
- [Testing](#testing)
- [Documentation](#documentation)
- [License](#license)

## Overview

Kylos IPTV Player is a feature-rich, cross-platform IPTV streaming application that supports multiple content sources including M3U/M3U8 playlists and Xtream Codes API. Built with Clean Architecture principles and powered by Riverpod for state management, it delivers a seamless viewing experience across mobile devices and smart TVs.

## Features

### Live TV Streaming
- Channel browsing by categories
- EPG (Electronic Program Guide) support
- Channel favorites and search
- Multi-source support (M3U files and Xtream Codes API)

### Video on Demand (VOD)
- Movie browsing and playback with detailed movie information
- Category-based organization with pagination
- Thumbnail/poster display with shimmer loading
- Movie details screen with synopsis, cast, director info
- Play/Resume functionality with progress tracking
- Favorites management
- Search movies by title

### Series Support
- Series and episode management with season tabs
- Episode list browsing with descriptions
- Series category filtering with pagination
- Series details screen with cover art and metadata
- Direct episode playback from season view
- Favorites management
- Search series by title

### Continue Watching
- Track playback progress for movies and episodes
- Resume from last position
- Continue watching carousel on home screen
- Progress bar indicators showing completion percentage
- Remove items from continue watching list

### Advanced Playback
- Multi-protocol support (HLS, DASH, RTMP, HTTP)
- Multiple audio track selection
- Subtitle/closed caption support
- Quality/bitrate selection
- Playback speed control
- Screen wake lock during playback
- Screen brightness adjustment
- TV remote D-pad navigation

### Playlist Management
- M3U/M3U8 format support
- Xtream Codes API integration
- Local playlist storage
- Multiple active playlists
- Playlist import/export

### User Features
- Multi-profile support
- Favorite channels, movies, and series
- Unified search for movies and series with tabs
- Settings persistence
- User preferences and customization
- Watch history tracking

### Monetization
- Freemium model with in-app purchases
- Multiple subscription tiers:
  - Pro Monthly ($2.99/month)
  - Pro Annual ($19.99/year with 7-day trial)
  - Pro Lifetime ($49.99)
- Cross-platform IAP (Google Play, App Store, Amazon Appstore)

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Android Phone | Fully Supported | minSDK 21 |
| Android Tablet | Fully Supported | Adaptive layouts |
| iOS iPhone | Fully Supported | iOS 13.0+ |
| iOS iPad | Fully Supported | Adaptive layouts |
| Android TV | Fully Supported | TV-specific UX with D-pad navigation |
| Amazon Fire TV | Fully Supported | Fire TV detection and optimization |
| Samsung Tizen | Planned | Future support |
| Apple TV | Planned | Future support |

## Architecture

Kylos IPTV Player follows **Clean Architecture** principles with a feature-first modular approach:

```
+-------------------------------------------------------------+
|                    Presentation Layer                        |
|              (Screens, Widgets, Providers)                   |
+-------------------------------------------------------------+
|                      Domain Layer                            |
|         (Entities, Use Cases, Repository Interfaces)         |
+-------------------------------------------------------------+
|                   Infrastructure Layer                       |
|      (Repository Implementations, Data Sources, APIs)        |
+-------------------------------------------------------------+
|                    External Services                         |
|         (Firebase, Local Storage, Native Channels)           |
+-------------------------------------------------------------+
```

### Key Architectural Decisions

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| State Management | Riverpod 2.x | Type-safe, testable, no BuildContext dependency (critical for TV) |
| Navigation | go_router | Declarative routing, deep linking, TV-compatible |
| Video Player | media_kit | FFmpeg/libmpv based, cross-platform, excellent IPTV codec support |
| Dependency Injection | Riverpod providers | Built-in with state management |
| Code Generation | freezed + json_serializable | Immutable models, JSON serialization |

## Project Structure

```
kylos_iptv_player/
├── lib/
│   ├── main.dart                 # Default entry point
│   ├── main_mobile.dart          # Mobile-specific entry point
│   ├── main_tv.dart              # TV-specific entry point
│   ├── bootstrap.dart            # App initialization
│   ├── app.dart                  # Root widget
│   │
│   ├── core/                     # Core modules
│   │   ├── auth/                 # Authentication service
│   │   ├── config/               # Remote configuration
│   │   ├── design_system/        # Themes, colors, typography
│   │   ├── entitlements/         # Purchase management
│   │   ├── logging/              # App-wide logging
│   │   ├── platform/             # Form factor detection
│   │   ├── security/             # Encryption, credentials
│   │   ├── tv/                   # TV focus navigation
│   │   └── user/                 # User data management
│   │
│   ├── features/                 # Feature modules
│   │   ├── home/                 # Dashboard/home screen
│   │   ├── live_tv/              # Live TV channels, EPG
│   │   ├── vod/                  # Video on Demand
│   │   ├── series/               # Series and episodes
│   │   ├── playback/             # Video player
│   │   ├── playlists/            # Playlist management
│   │   ├── onboarding/           # Welcome and setup
│   │   ├── search/               # Content search
│   │   ├── settings/             # App settings
│   │   ├── profiles/             # Multi-profile support
│   │   └── monetization/         # In-app purchases
│   │
│   ├── infrastructure/           # External integrations
│   │   ├── firebase/             # Firebase services
│   │   ├── m3u/                  # M3U parser
│   │   ├── xtream/               # Xtream Codes API client
│   │   ├── network/              # HTTP client (Dio)
│   │   ├── storage/              # Local storage
│   │   └── repositories/         # Repository implementations
│   │
│   ├── navigation/               # Routing
│   │   ├── app_router.dart       # go_router configuration
│   │   ├── routes.dart           # Route constants
│   │   └── guards/               # Navigation guards
│   │
│   └── shared/                   # Shared components
│       ├── providers/            # Cross-feature providers
│       └── widgets/              # Reusable UI components
│
├── android/                      # Android native code
├── ios/                          # iOS native code
├── assets/                       # Images and icons
├── docs/                         # Documentation
├── test/                         # Unit and widget tests
└── .github/workflows/            # CI/CD pipelines
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.19.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- For iOS: Xcode 15+ and CocoaPods
- For Android: Java 17
- Firebase project (for authentication and backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/kylos_iptv_player.git
   cd kylos_iptv_player
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (freezed models, JSON serialization, Riverpod providers)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
   - Configure Firebase: `flutterfire configure`
   - This generates `lib/firebase_options.dart`

5. **iOS-specific setup**
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Running the App

**Mobile (Android/iOS)**
```bash
flutter run
# or explicitly
flutter run -t lib/main_mobile.dart
```

**TV (Android TV/Fire TV)**
```bash
flutter run -t lib/main_tv.dart
```

**Web (development only)**
```bash
flutter run -d chrome
```

## Building for Production

### Android Mobile

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Google Play)
flutter build appbundle --release
```

### Android TV / Fire TV

```bash
# Release APK
flutter build apk --release -t lib/main_tv.dart
```

### iOS

```bash
# Debug build (no code signing)
flutter build ios --debug --no-codesign

# Release build
flutter build ios --release

# IPA for App Store
flutter build ipa --release
```

### Build Optimization

Release builds automatically include:
- R8/ProGuard code obfuscation
- Resource shrinking
- Tree shaking
- NDK symbol stripping

## Configuration

### Firebase Services

The app uses the following Firebase services:

| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication (anonymous + Google Sign-In) |
| Cloud Firestore | User data, playlists, preferences storage |
| Remote Config | Feature flags and dynamic configuration |
| Crashlytics | Crash reporting and analytics |
| App Check | API abuse prevention |

### Environment Setup

1. **Firebase Configuration**
   - Configure `firebase_options.dart` using FlutterFire CLI
   - Set up Firestore security rules
   - Enable required authentication providers

2. **Android Signing**
   - Create `android/key.properties` for release builds:
     ```properties
     storePassword=your_keystore_password
     keyPassword=your_key_password
     keyAlias=your_key_alias
     storeFile=path/to/keystore.jks
     ```

3. **iOS Signing**
   - Configure signing in Xcode
   - Set up provisioning profiles for distribution

## Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.4.9 | State management |
| go_router | ^13.0.0 | Navigation |
| media_kit | ^1.1.10 | Video playback |
| dio | ^5.4.0 | HTTP client |
| freezed | ^2.4.6 | Immutable models |

### Firebase

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^3.8.1 | Firebase SDK |
| firebase_auth | ^5.3.4 | Authentication |
| cloud_firestore | ^5.6.0 | Database |
| firebase_remote_config | ^5.1.6 | Remote configuration |
| firebase_crashlytics | ^4.2.2 | Crash reporting |

### Storage & Security

| Package | Version | Purpose |
|---------|---------|---------|
| shared_preferences | ^2.2.2 | Local key-value storage |
| flutter_secure_storage | ^9.0.0 | Encrypted credential storage |

### In-App Purchases

| Package | Version | Purpose |
|---------|---------|---------|
| in_app_purchase | ^3.1.13 | Unified IAP API |
| in_app_purchase_storekit | ^0.3.13 | iOS StoreKit 2 |
| in_app_purchase_android | ^0.3.3 | Android billing |

For a complete list, see [pubspec.yaml](pubspec.yaml).

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run with randomized ordering
flutter test --test-randomize-ordering-seed=random
```

### Test Structure

- **Unit Tests**: Service logic, utilities, parsers
- **Widget Tests**: UI components, screens
- **Integration Tests**: Full feature flows

### Code Quality

```bash
# Run analyzer
flutter analyze --fatal-infos --fatal-warnings

# Check formatting
dart format --output=none --set-exit-if-changed .

# Fix formatting
dart format .
```

## CI/CD

The project includes GitHub Actions workflows for:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| CI | Manual | Code quality, tests, build verification |
| Build Android | Manual | Android APK/AAB builds |
| Build iOS | Manual | iOS IPA builds |
| Release | Manual | Full release pipeline |

### Running Workflows

1. Go to the repository on GitHub
2. Click **Actions**
3. Select the workflow
4. Click **Run workflow**
5. Configure options and run

## Documentation

Detailed documentation is available in the `/docs` folder:

| Document | Description |
|----------|-------------|
| [01-architecture-vision](docs/01-architecture-vision-iptv-player.md) | Architecture overview and vision |
| [02-functional-spec](docs/02-functional-spec-and-ux-flows.md) | Features and UX flows |
| [03-flutter-architecture](docs/03-flutter-architecture-and-project-structure.md) | Flutter-specific architecture |
| [04-backend-architecture](docs/04-backend-architecture-and-data-model.md) | Firestore data model |
| [05-firebase-configuration](docs/05-firebase-configuration-guide.md) | Firebase setup guide |
| [06-monetization-strategy](docs/06-monetization-strategy-and-implementation.md) | Monetization implementation |
| [07-tv-build-guide](docs/07-tv-build-and-testing-guide.md) | TV platform guide |
| [09-security-hardening](docs/09-security-and-privacy-hardening.md) | Security best practices |

## Security

The app implements several security measures:

- **Secure Storage**: AES-256-GCM encryption for IPTV credentials
- **Firebase Security Rules**: Owner-only data access
- **Code Obfuscation**: R8/ProGuard for release builds
- **App Check**: API abuse prevention
- **Privacy-Aware Logging**: Sensitive data redaction

## Localization

Currently supported languages:
- English (en) - Default
- Spanish (es)

To add a new language, create the corresponding ARB file in `lib/l10n/`.

## License

This project is proprietary software. All rights reserved.

---

**Kylos IPTV Player** - Built with Flutter
