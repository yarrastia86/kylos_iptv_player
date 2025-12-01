# CI/CD and Release Process

This document describes the continuous integration, continuous deployment, and release processes for Kylos IPTV Player.

## Table of Contents

1. [Overview](#overview)
2. [Branching Strategy](#branching-strategy)
3. [CI Workflows](#ci-workflows)
4. [Build Workflows](#build-workflows)
5. [Release Process](#release-process)
6. [Local Development Commands](#local-development-commands)
7. [GitHub Secrets Configuration](#github-secrets-configuration)
8. [Signing Artifacts Setup](#signing-artifacts-setup)
9. [Store Deployment](#store-deployment)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The CI/CD pipeline is built with GitHub Actions and consists of:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR to main, develop | Quality checks, tests, debug builds |
| `build-android.yml` | Manual, called by release | Android APK/AAB builds |
| `build-ios.yml` | Manual, called by release | iOS IPA builds |
| `release.yml` | Version tag push, manual | Full release with store deployment |

### Pipeline Architecture

```
[Push/PR] --> [ci.yml]
                |
                +--> Quality Check (format, analyze)
                +--> Unit & Widget Tests
                +--> Debug Builds (verify compilation)

[Tag v*.*.*] --> [release.yml]
                    |
                    +--> Validate version
                    +--> Quality Check
                    +--> [build-android.yml] --> Play Store (optional)
                    +--> [build-ios.yml] --> TestFlight (optional)
                    +--> Create GitHub Release
```

---

## Branching Strategy

We use a **modified GitFlow** branching model:

### Branches

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready code | Protected, requires PR |
| `develop` | Integration branch for features | Protected, requires PR |
| `feature/*` | New features | - |
| `bugfix/*` | Bug fixes | - |
| `release/*` | Release preparation | - |
| `hotfix/*` | Production hotfixes | - |

### Workflow

1. **Feature Development**:
   ```
   develop --> feature/my-feature --> PR --> develop
   ```

2. **Release Preparation**:
   ```
   develop --> release/v1.0.0 --> PR --> main
                                    |
                                    +--> Tag v1.0.0
   ```

3. **Hotfix**:
   ```
   main --> hotfix/critical-fix --> PR --> main
                                      |
                                      +--> PR --> develop
   ```

---

## CI Workflows

### ci.yml - Continuous Integration

Runs on every push and pull request to `main` or `develop`.

#### Jobs

1. **Quality Check** (ubuntu-latest, ~5 min)
   - `flutter pub get`
   - `dart format --set-exit-if-changed .`
   - `flutter analyze --fatal-infos --fatal-warnings`

2. **Tests** (ubuntu-latest, ~10 min)
   - Runs code generators (build_runner)
   - `flutter test --coverage`
   - Uploads coverage to Codecov

3. **Build Android** (ubuntu-latest, ~15 min)
   - Debug APK for mobile
   - Debug APK for TV

4. **Build iOS** (macos-latest, ~20 min)
   - Debug build (no codesign)

#### Quality Gates

The CI fails if:
- Code formatting differs from `dart format`
- `flutter analyze` reports any warnings or errors
- Any test fails
- Build compilation fails

---

## Build Workflows

### build-android.yml

Builds Android artifacts for different distributions.

#### Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `build_type` | choice | debug | debug or release |
| `target_platform` | choice | mobile | mobile, tv, or all |
| `upload_to_play_store` | boolean | false | Deploy to Play Store |
| `play_store_track` | choice | internal | internal, alpha, beta, production |

#### Artifacts Produced

| Build Type | Platform | Artifact |
|------------|----------|----------|
| debug | mobile | `android-mobile-debug-apk` |
| debug | tv | `android-tv-debug-apk` |
| release | mobile | `android-mobile-release-apk`, `android-mobile-release-aab` |
| release | tv | `android-tv-release-apk` |

### build-ios.yml

Builds iOS artifacts.

#### Inputs

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `build_type` | choice | debug | debug or release |
| `upload_to_testflight` | boolean | false | Deploy to TestFlight |

#### Artifacts Produced

| Build Type | Artifact |
|------------|----------|
| debug | `ios-debug` (app bundle) |
| release | `ios-release` (IPA) |

---

## Release Process

### Version Tagging Strategy

Use semantic versioning: `vMAJOR.MINOR.PATCH[-PRERELEASE]`

Examples:
- `v1.0.0` - Major release
- `v1.0.1` - Patch release
- `v1.1.0-beta.1` - Beta release
- `v2.0.0-rc.1` - Release candidate

### Creating a Release

#### Option 1: Tag-based (Recommended)

```bash
# Ensure you're on main with latest changes
git checkout main
git pull origin main

# Create and push tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

This automatically:
1. Runs quality checks
2. Builds all platforms (Android mobile, TV, iOS)
3. Deploys to stores (if secrets are configured)
4. Creates GitHub Release with all artifacts

#### Option 2: Manual Dispatch

1. Go to Actions > Release workflow
2. Click "Run workflow"
3. Enter version (e.g., `1.0.0`)
4. Choose deployment options
5. Click "Run workflow"

### Release Checklist

Before creating a release tag:

- [ ] Update version in `pubspec.yaml`
- [ ] Update changelog/release notes
- [ ] Ensure all tests pass on develop
- [ ] Merge develop into main via PR
- [ ] Verify signing secrets are configured
- [ ] Review store listing metadata

---

## Local Development Commands

Run these commands locally before pushing to catch issues early.

### Setup

```bash
# Install dependencies
flutter pub get

# Run code generators (if using build_runner)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Quality Checks

```bash
# Check formatting (fix issues)
dart format .

# Check formatting (verify only, like CI)
dart format --output=none --set-exit-if-changed .

# Run analyzer
flutter analyze

# Run analyzer with strict mode (like CI)
flutter analyze --fatal-infos --fatal-warnings
```

### Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/live_tv/live_tv_screen_test.dart

# Run tests with random ordering (like CI)
flutter test --test-randomize-ordering-seed=random
```

### Building

```bash
# Debug APK (mobile)
flutter build apk --debug

# Debug APK (TV)
flutter build apk --debug -t lib/main_tv.dart

# Release APK (requires signing setup)
flutter build apk --release

# Release AAB (for Play Store)
flutter build appbundle --release

# iOS (debug, no codesign)
flutter build ios --debug --no-codesign

# iOS (release)
flutter build ios --release
```

### Pre-commit Script

Create a pre-commit hook (`.git/hooks/pre-commit`):

```bash
#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Format check
echo "Checking formatting..."
dart format --output=none --set-exit-if-changed .

# Analyze
echo "Running analyzer..."
flutter analyze --fatal-infos --fatal-warnings

# Tests
echo "Running tests..."
flutter test

echo "All checks passed!"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## GitHub Secrets Configuration

Configure these secrets in your repository settings (Settings > Secrets and variables > Actions).

### Required Secrets

#### Android Signing

| Secret | Description | How to Get |
|--------|-------------|------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore | See [Android Signing Setup](#android-signing-setup) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Your keystore password |
| `ANDROID_KEY_ALIAS` | Key alias in keystore | Alias you created |
| `ANDROID_KEY_PASSWORD` | Key password | Your key password |

#### Google Play Deployment

| Secret | Description | How to Get |
|--------|-------------|------------|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Service account JSON | See [Google Play Setup](#google-play-setup) |

#### iOS Signing

| Secret | Description | How to Get |
|--------|-------------|------------|
| `IOS_CERTIFICATE_BASE64` | Base64-encoded .p12 | See [iOS Signing Setup](#ios-signing-setup) |
| `IOS_CERTIFICATE_PASSWORD` | Certificate password | Export password |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded profile | See [iOS Signing Setup](#ios-signing-setup) |

#### App Store Connect

| Secret | Description | How to Get |
|--------|-------------|------------|
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | See [App Store Connect Setup](#app-store-connect-setup) |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID | See [App Store Connect Setup](#app-store-connect-setup) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded .p8 key | See [App Store Connect Setup](#app-store-connect-setup) |

#### Optional

| Secret | Description |
|--------|-------------|
| `CODECOV_TOKEN` | Codecov upload token |

### Repository Variables

| Variable | Description |
|----------|-------------|
| `APPLE_TEAM_ID` | Apple Developer Team ID |

---

## Signing Artifacts Setup

### Android Signing Setup

#### 1. Create Upload Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Answer the prompts (remember passwords!).

#### 2. Encode Keystore for GitHub

```bash
base64 -i upload-keystore.jks | pbcopy  # macOS
base64 -w 0 upload-keystore.jks         # Linux
```

#### 3. Configure Android Project

Create `android/key.properties` (do NOT commit):

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...

    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

### iOS Signing Setup

#### 1. Create Distribution Certificate

1. Open Keychain Access
2. Certificate Assistant > Request a Certificate from a Certificate Authority
3. Go to [Apple Developer Portal](https://developer.apple.com)
4. Certificates > Create "Apple Distribution" certificate
5. Download and install in Keychain

#### 2. Export Certificate

1. Open Keychain Access
2. Find "Apple Distribution" certificate
3. Right-click > Export
4. Save as `.p12` with password

#### 3. Create Provisioning Profile

1. Go to Apple Developer Portal
2. Profiles > Create "App Store" profile
3. Select your app and certificate
4. Download profile

#### 4. Encode for GitHub

```bash
# Certificate
base64 -i certificate.p12 | pbcopy

# Provisioning profile
base64 -i profile.mobileprovision | pbcopy
```

### Google Play Setup

#### 1. Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project or select existing
3. APIs & Services > Enable "Google Play Android Developer API"
4. IAM & Admin > Service Accounts > Create
5. Download JSON key

#### 2. Link to Play Console

1. Go to [Play Console](https://play.google.com/console)
2. Setup > API access
3. Link Google Cloud project
4. Grant "Release manager" permission to service account

### App Store Connect Setup

#### 1. Create API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Users and Access > Keys
3. Generate API Key with "App Manager" role
4. Note Key ID and Issuer ID
5. Download `.p8` key (only available once!)

#### 2. Encode Key

```bash
base64 -i AuthKey_XXXX.p8 | pbcopy
```

---

## Store Deployment

### Google Play

The workflow deploys to these tracks:

| Track | Purpose | Rollout |
|-------|---------|---------|
| internal | Team testing | Immediate |
| alpha | Internal testers | Immediate |
| beta | External testers | Immediate |
| production | Public release | Staged rollout recommended |

#### Manual Promotion

After deploying to internal/alpha/beta, promote via Play Console:
1. Go to Release > Testing > [Track]
2. Select release > Promote
3. Choose target track

### App Store / TestFlight

The workflow uploads to TestFlight automatically.

#### TestFlight Distribution

1. Build processes automatically (~15-30 min)
2. Add testers in App Store Connect
3. Testers receive notification

#### Production Release

1. Go to App Store Connect
2. Select build from TestFlight
3. Complete App Store listing
4. Submit for review

### Amazon Appstore (Fire TV)

Currently requires manual upload:

1. Download TV APK from GitHub Release
2. Go to [Amazon Developer Console](https://developer.amazon.com)
3. Apps & Games > Your App > APK Files
4. Upload new APK
5. Submit for review

See comments in `build-android.yml` for potential automation.

---

## Troubleshooting

### Common CI Failures

#### Formatting Errors

```
Error: dart format found issues
```

**Fix**: Run `dart format .` locally and commit changes.

#### Analyzer Warnings

```
Error: flutter analyze reported warnings
```

**Fix**: Address all warnings/errors shown in the output.

#### Test Failures

```
Error: Some tests failed
```

**Fix**: Run `flutter test` locally and fix failing tests.

#### Build Failures

```
Error: Gradle build failed
```

**Possible causes**:
- Missing signing configuration
- Incompatible dependencies
- Android SDK issues

### iOS Code Signing Issues

```
Error: No signing certificate found
```

**Check**:
1. Certificate is valid and not expired
2. Certificate matches provisioning profile
3. Secrets are correctly base64 encoded
4. Team ID is correct

### Play Store Upload Failures

```
Error: APK/AAB upload failed
```

**Check**:
1. Service account has correct permissions
2. Package name matches Play Console
3. Version code is higher than previous release

### Workflow Timeout

Default timeouts:
- Quality check: 15 min
- Tests: 20 min
- Android build: 30 min
- iOS build: 45 min
- Release: 60 min

If builds consistently timeout, consider:
- Improving caching
- Splitting into smaller jobs
- Upgrading runner tier

---

## Summary

### Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | PR/push quality checks |
| `.github/workflows/build-android.yml` | Android builds |
| `.github/workflows/build-ios.yml` | iOS builds |
| `.github/workflows/release.yml` | Release orchestration |
| `.github/dependabot.yml` | Dependency updates |

### Quick Reference

```bash
# Local checks before push
dart format .
flutter analyze
flutter test

# Create release
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Manual workflow run
# Go to Actions > Select workflow > Run workflow
```

### Support

For CI/CD issues:
1. Check workflow logs in GitHub Actions
2. Review this documentation
3. Check GitHub Actions documentation
4. Open an issue in the repository
