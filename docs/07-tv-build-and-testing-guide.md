# TV Build and Testing Guide

This guide covers building, installing, and testing Kylos IPTV Player on Android TV and Fire TV devices.

## Table of Contents

1. [Overview](#overview)
2. [Android Configuration](#android-configuration)
3. [Building for TV](#building-for-tv)
4. [Testing on Emulators](#testing-on-emulators)
5. [Testing on Physical Devices](#testing-on-physical-devices)
6. [D-Pad Navigation Testing](#d-pad-navigation-testing)
7. [Debugging Tips](#debugging-tips)

---

## Overview

Kylos IPTV Player supports three platforms:
- **Mobile** (phones and tablets)
- **Android TV** (Google TV, Shield TV, etc.)
- **Fire TV** (Fire TV Stick, Fire TV Cube, etc.)

The app uses a separate entry point for TV (`lib/main_tv.dart`) that sets the form factor to `FormFactor.tv`, enabling TV-specific layouts and navigation.

### Key Differences for TV

| Feature | Mobile | TV |
|---------|--------|-----|
| Navigation | Bottom nav bar | Side navigation rail |
| Input | Touch | D-pad/Remote |
| Layout | Vertical lists | Horizontal card rows |
| Focus | Optional | Required for all interactive elements |
| Controls overlay | Touch-triggered | Auto-hide with key-triggered show |

---

## Android Configuration

### AndroidManifest.xml Setup

You need two manifest configurations - one for mobile and one for TV.

#### Main AndroidManifest (android/app/src/main/AndroidManifest.xml)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Kylos IPTV"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Main activity for mobile -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <!-- Mobile intent filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
        </activity>

        <!-- Leanback launcher activity for TV -->
        <activity
            android:name=".TVMainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:screenOrientation="landscape">

            <!-- TV Leanback intent filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>
            </intent-filter>

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
        </activity>

        <!-- Declare Leanback support -->
        <meta-data
            android:name="android.software.leanback"
            android:value="true"/>
    </application>

    <!-- TV feature declaration -->
    <uses-feature
        android:name="android.software.leanback"
        android:required="false"/>

    <!-- Declare that touch is not required -->
    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false"/>

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

### TV Activity (TVMainActivity.kt)

Create `android/app/src/main/kotlin/com/kylos/iptvplayer/TVMainActivity.kt`:

```kotlin
package com.kylos.iptvplayer

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TVMainActivity: FlutterActivity() {
    private val CHANNEL = "com.kylos.iptvplayer/platform"

    override fun getDartEntrypointFunctionName(): String {
        // Use the TV entry point
        return "main_tv"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAndroidTV" -> {
                        result.success(isAndroidTV())
                    }
                    "isFireTV" -> {
                        result.success(isFireTV())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun isAndroidTV(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        return uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }

    private fun isFireTV(): Boolean {
        return packageManager.hasSystemFeature("amazon.hardware.fire_tv")
    }
}
```

### Main Activity Platform Channel (MainActivity.kt)

Update `android/app/src/main/kotlin/com/kylos/iptvplayer/MainActivity.kt`:

```kotlin
package com.kylos.iptvplayer

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.kylos.iptvplayer/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAndroidTV" -> {
                        result.success(isAndroidTV())
                    }
                    "isFireTV" -> {
                        result.success(isFireTV())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun isAndroidTV(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        return uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }

    private fun isFireTV(): Boolean {
        return packageManager.hasSystemFeature("amazon.hardware.fire_tv")
    }
}
```

### Build Gradle Configuration

Add TV-specific build flavors in `android/app/build.gradle`:

```gradle
android {
    // ...

    flavorDimensions "platform"

    productFlavors {
        mobile {
            dimension "platform"
            applicationIdSuffix ""
        }

        tv {
            dimension "platform"
            applicationIdSuffix ".tv"
            // Target TV entry point
            resValue "string", "flutter_entrypoint", "main_tv"
        }

        firetv {
            dimension "platform"
            applicationIdSuffix ".firetv"
            resValue "string", "flutter_entrypoint", "main_tv"
        }
    }
}
```

---

## Building for TV

### Debug Build

```bash
# Build for Android TV (debug)
flutter build apk --debug --flavor tv -t lib/main_tv.dart

# Build for Fire TV (debug)
flutter build apk --debug --flavor firetv -t lib/main_tv.dart
```

### Release Build

```bash
# Build for Android TV (release)
flutter build apk --release --flavor tv -t lib/main_tv.dart

# Build App Bundle for Play Store (includes TV support)
flutter build appbundle --release --flavor tv -t lib/main_tv.dart
```

### Fire TV Specific Build

For Amazon Appstore submission:

```bash
# Fire TV release APK
flutter build apk --release --flavor firetv -t lib/main_tv.dart

# The APK will be at:
# build/app/outputs/flutter-apk/app-firetv-release.apk
```

---

## Testing on Emulators

### Android TV Emulator

1. **Create Android TV AVD**:
   ```bash
   # List available system images
   sdkmanager --list | grep tv

   # Download TV system image
   sdkmanager "system-images;android-33;google_tv;x86_64"

   # Create AVD
   avdmanager create avd -n "AndroidTV_API33" \
     -k "system-images;android-33;google_tv;x86_64" \
     -d "tv_1080p"
   ```

2. **Start Emulator**:
   ```bash
   emulator -avd AndroidTV_API33
   ```

3. **Run App**:
   ```bash
   flutter run -t lib/main_tv.dart
   ```

### Fire TV Emulator

Amazon does not provide official Fire TV emulators. Use:
- Android TV emulator as a proxy (most behavior is similar)
- Physical Fire TV device for accurate testing

### Emulator D-Pad Controls

In Android TV emulator, use keyboard for D-pad:
- **Arrow keys**: Navigate
- **Enter**: Select/OK
- **Backspace**: Back
- **F1**: Home
- **Escape**: Back (alternative)

---

## Testing on Physical Devices

### Android TV Device Setup

1. **Enable Developer Options**:
   - Go to Settings > Device Preferences > About
   - Click "Build" 7 times to enable Developer Options

2. **Enable USB Debugging**:
   - Settings > Device Preferences > Developer Options
   - Enable "USB debugging"

3. **Connect via USB or Network**:
   ```bash
   # USB connection
   adb devices

   # Network connection (after initial USB setup)
   adb tcpip 5555
   adb connect <TV_IP_ADDRESS>:5555
   ```

4. **Install and Run**:
   ```bash
   flutter run -t lib/main_tv.dart
   ```

### Fire TV Device Setup

1. **Enable Developer Options**:
   - Settings > My Fire TV > About
   - Click "Build" 7 times

2. **Enable ADB Debugging**:
   - Settings > My Fire TV > Developer Options
   - Enable "ADB debugging"
   - Enable "Apps from Unknown Sources"

3. **Connect via Network**:
   ```bash
   adb connect <FIRE_TV_IP>:5555
   ```

4. **Install APK**:
   ```bash
   flutter build apk --debug -t lib/main_tv.dart
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

---

## D-Pad Navigation Testing

### Remote Control Key Mapping

| Remote Button | Keyboard Key | LogicalKeyboardKey |
|---------------|--------------|-------------------|
| D-pad Up | Arrow Up | `arrowUp` |
| D-pad Down | Arrow Down | `arrowDown` |
| D-pad Left | Arrow Left | `arrowLeft` |
| D-pad Right | Arrow Right | `arrowRight` |
| Select/OK | Enter | `select`, `enter` |
| Back | Backspace | `goBack`, `escape` |
| Play/Pause | Space | `mediaPlayPause` |
| Fast Forward | F | `mediaFastForward` |
| Rewind | R | `mediaRewind` |
| Home | H | `goHome` |

### Testing Checklist

1. **Navigation Flow**:
   - [ ] Can navigate between nav rail and content with left/right
   - [ ] Can navigate between items in content with arrow keys
   - [ ] Focus indicator is clearly visible
   - [ ] Focus wraps appropriately (or doesn't where intended)

2. **Selection**:
   - [ ] Enter/Select key triggers selection
   - [ ] Selected item provides feedback
   - [ ] Channel selection starts playback

3. **Back Button**:
   - [ ] Back from content goes to nav rail
   - [ ] Back from nav rail exits or shows exit dialog
   - [ ] Back during playback shows/hides controls

4. **Media Keys**:
   - [ ] Play/Pause works during playback
   - [ ] Channel Up/Down changes channel
   - [ ] Info button shows channel info

5. **Auto-hide Controls**:
   - [ ] Player controls auto-hide after timeout
   - [ ] Any key press shows controls again
   - [ ] Timer resets on interaction

### Widget Test Verification

Run the TV-specific tests:

```bash
# Run all TV tests
flutter test test/features/live_tv/presentation/tv_live_tv_screen_test.dart

# Run with verbose output
flutter test --verbose test/features/live_tv/presentation/tv_live_tv_screen_test.dart
```

---

## Debugging Tips

### Common Issues

1. **App shows mobile layout on TV**:
   - Ensure using `-t lib/main_tv.dart` entry point
   - Check platform channel is returning correct values
   - Verify `formFactorProvider` is properly overridden

2. **Focus not visible**:
   - Check focus nodes are properly attached
   - Verify `FocusableWidget` or similar is wrapping interactive elements
   - Check theme colors for focus indicators

3. **Back button not working**:
   - Ensure `TVNavigationScope` is wrapping the screen
   - Check `onBackPressed` callback is connected
   - Verify no other widget is consuming the key event

4. **Slow performance on Fire TV Stick**:
   - Use release builds for performance testing
   - Reduce animation complexity
   - Consider lower resolution assets

### Debug Logging

Enable verbose focus logging:

```dart
// In your debug build
import 'package:flutter/widgets.dart';

void enableFocusDebugging() {
  debugFocusChanges = true;
}
```

### Remote Debugging

Connect to running app with DevTools:

```bash
# Get DevTools URL
flutter run -t lib/main_tv.dart --verbose

# Look for:
# An Observatory debugger and profiler on Android TV is available at: http://127.0.0.1:XXXXX/
```

---

## Summary

Building for TV requires:
1. Separate manifest configuration with Leanback launcher
2. TV-specific activity using `main_tv.dart` entry point
3. Platform channel for detecting TV vs mobile
4. Testing with emulator or physical device
5. Thorough D-pad navigation verification

Key files created:
- `lib/main_tv.dart` - TV entry point
- `lib/core/platform/platform_info.dart` - Platform detection
- `lib/core/tv/focus_system.dart` - Focus management
- `lib/features/live_tv/presentation/widgets/tv_channel_card.dart` - TV-specific UI
- `lib/features/playback/presentation/widgets/tv_player_controls.dart` - TV player controls

For questions or issues, refer to the Flutter TV documentation or the project issue tracker.
