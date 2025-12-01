# Kylos IPTV Player - Multi-Platform and TV UX Strategy

## Document Version

| Version | Date       | Author          | Description                     |
|---------|------------|-----------------|--------------------------------|
| 1.0     | 2024-01-XX | UX/Platform     | Initial multi-platform design   |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Platform Analysis](#2-platform-analysis)
3. [UX Adaptation Strategy](#3-ux-adaptation-strategy)
4. [Flutter Implementation](#4-flutter-implementation)
5. [Platform Limitations and Mitigations](#5-platform-limitations-and-mitigations)
6. [Phased Rollout Roadmap](#6-phased-rollout-roadmap)
7. [Testing and QA Strategy](#7-testing-and-qa-strategy)
8. [Appendices](#8-appendices)

---

## 1. Executive Summary

### Target Platforms

| Platform | Priority | Timeline | Approach |
|----------|----------|----------|----------|
| Android Phone/Tablet | P0 | Phase 1 | Flutter (shared codebase) |
| iOS iPhone/iPad | P0 | Phase 1 | Flutter (shared codebase) |
| Android TV | P1 | Phase 2 | Flutter (TV adaptations) |
| Amazon Fire TV | P1 | Phase 2 | Flutter (TV adaptations) |
| Samsung Tizen | P2 | Phase 3 | Evaluate: Flutter-Tizen or native |

### Core UX Principles

1. **Platform-native feel**: Each platform should feel familiar to its users
2. **Shared mental model**: Core concepts and navigation patterns remain consistent
3. **Optimized interactions**: Touch for mobile, D-pad for TV, no awkward compromises
4. **Performance parity**: Smooth 60fps experience across all platforms

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation paradigm | Adaptive (bottom nav mobile, rail TV) | Platform conventions |
| Focus system | Custom FocusableWidget wrapper | Better control than default |
| Layout system | Breakpoint-based responsive | Single codebase efficiency |
| Player UI | Platform-specific overlays | Different interaction patterns |

---

## 2. Platform Analysis

### 2.1 Mobile Platforms (Android/iOS)

#### User Context

```
Environment: Personal device, often mobile usage
Screen size: 4.7" - 6.9" (phones), 7.9" - 12.9" (tablets)
Interaction: Touch (tap, swipe, pinch, long-press)
Session length: Short to medium (5-60 minutes)
Audio: Often headphones or speaker, privacy consideration
```

#### UX Expectations

| Element | Expectation |
|---------|-------------|
| Navigation | Bottom tab bar (iOS/Android convention) |
| Lists | Vertical scrolling, pull-to-refresh |
| Actions | Tap for primary, long-press for secondary |
| Search | Keyboard input with autocomplete |
| Player | Tap to show/hide controls, swipe gestures |
| Orientation | Portrait default, landscape for playback |

#### Platform-Specific Considerations

**Android:**
- Back button handling (system navigation)
- Picture-in-Picture support
- Notification media controls
- Wide device fragmentation

**iOS:**
- Swipe-back gesture navigation
- Control Center integration
- AirPlay support
- Notch/Dynamic Island handling

### 2.2 TV Platforms (Android TV / Fire TV)

#### User Context

```
Environment: Living room, shared viewing, "10-foot UI"
Screen size: 32" - 85" (typical TV sizes)
Viewing distance: 6-12 feet from screen
Interaction: D-pad remote (directional + select + back)
Session length: Medium to long (30-180 minutes)
Audio: TV speakers or sound system
```

#### UX Expectations

| Element | Expectation |
|---------|-------------|
| Navigation | Left rail or top tabs, horizontal content rows |
| Lists | Horizontal scrolling rows, grid layouts |
| Actions | Select button for primary, long-press/menu for secondary |
| Search | Voice search primary, on-screen keyboard secondary |
| Player | Always-visible controls initially, auto-hide |
| Focus | Clear visual focus indicator, predictable movement |

#### Remote Control Buttons

```
Standard Android TV Remote:
┌─────────────────────────────┐
│         [Voice]             │
│                             │
│    [Up]                     │
│ [Left] [OK] [Right]         │
│   [Down]                    │
│                             │
│  [Back]  [Home]  [Menu]     │
│                             │
│  [Rew]  [Play/Pause] [FF]   │
└─────────────────────────────┘

Fire TV Remote (additional):
- Alexa button (voice)
- Fast forward / rewind buttons
- Volume buttons
- Mute button
```

#### Key Differences from Mobile

| Aspect | Mobile | TV |
|--------|--------|------|
| Primary input | Touch anywhere | D-pad navigation |
| Scrolling | Continuous swipe | Step-by-step focus |
| Text input | On-screen keyboard | Voice or hunt-and-peck |
| Hover states | None | Focus states essential |
| Touch targets | 48dp minimum | 48dp minimum, but focus areas larger |
| Information density | Higher | Lower (legibility at distance) |

### 2.3 Samsung Tizen

#### Platform Characteristics

```
OS: Tizen (Linux-based, Samsung proprietary)
SDK: Tizen Studio, Web apps, or Native C++
Flutter support: Experimental (flutter-tizen project)
Remote: Samsung Smart Remote (similar to Android TV)
Screen: Smart TVs, typically 32" - 85"
```

#### Unique Considerations

- Different app lifecycle management
- Samsung-specific media APIs
- Remote control key codes differ
- Limited Flutter plugin ecosystem
- Separate app store (Samsung Galaxy Store for TVs)

---

## 3. UX Adaptation Strategy

### 3.1 Navigation Architecture

#### Mobile Navigation (Bottom Tabs)

```
┌─────────────────────────────────────────────────────────────┐
│  [Status Bar]                                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│                                                              │
│                    CONTENT AREA                              │
│                                                              │
│              (Scrollable, touch-driven)                      │
│                                                              │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  [Live TV]  [Movies]  [Series]  [Search]  [Settings]        │
│     ●          ○         ○         ○          ○              │
└─────────────────────────────────────────────────────────────┘

Behavior:
- Tap to switch tabs
- Each tab maintains its own navigation stack
- Swipe on content to scroll
- Pull down to refresh
```

#### Tablet Navigation (Bottom Tabs + Master-Detail)

```
PORTRAIT:
Same as phone, but with larger touch targets and more content per row

LANDSCAPE (width >= 840dp):
┌────────────────────────────────────────────────────────────────────┐
│  [Status Bar]                                                       │
├──────────────────────────┬─────────────────────────────────────────┤
│                          │                                          │
│     MASTER LIST          │          DETAIL VIEW                     │
│                          │                                          │
│  [Channel 1]  ←─────────→│    Channel Name                         │
│  [Channel 2]             │    Now Playing: Show Title               │
│  [Channel 3]             │    [Play Button]                         │
│  ...                     │                                          │
│                          │    Up Next:                              │
│                          │    - 8:00 PM: Show A                     │
│                          │    - 9:00 PM: Show B                     │
│                          │                                          │
├──────────────────────────┴─────────────────────────────────────────┤
│  [Live TV]  [Movies]  [Series]  [Search]  [Settings]               │
└────────────────────────────────────────────────────────────────────┘
```

#### TV Navigation (Side Rail + Horizontal Rows)

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  ┌──────┐                                                               │
│  │      │   CONTINUE WATCHING                                           │
│  │ Live │   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                    │
│  │  TV  │   │ Ch1 │ │ Ch2 │ │ Ch3 │ │ Mov1│ │ Ser1│ ...               │
│  │      │   └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                    │
│  ├──────┤                                                               │
│  │      │   LIVE TV - FAVORITES                                         │
│  │Movies│   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                    │
│  │      │   │*Ch1*│ │ Ch2 │ │ Ch3 │ │ Ch4 │ │ Ch5 │ ...               │
│  ├──────┤   └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                    │
│  │      │        ↑                                                      │
│  │Series│   FOCUSED ITEM                                                │
│  │      │   (Highlighted with border/scale)                             │
│  ├──────┤                                                               │
│  │      │   RECENTLY ADDED MOVIES                                       │
│  │Search│   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                    │
│  │      │   │ Mov │ │ Mov │ │ Mov │ │ Mov │ │ Mov │ ...               │
│  ├──────┤   └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                    │
│  │      │                                                               │
│  │ ⚙️   │                                                               │
│  │      │                                                               │
│  └──────┘                                                               │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘

Focus Navigation:
- D-pad Left: Move to side rail (or previous item)
- D-pad Right: Move to next item in row
- D-pad Up: Move to row above (or previous rail item)
- D-pad Down: Move to row below (or next rail item)
- Select: Open/play focused item
- Back: Go back in navigation stack
```

### 3.2 Component Adaptations

#### Channel/Content Cards

**Mobile Card:**
```
┌─────────────────────┐
│ ┌─────────────────┐ │
│ │                 │ │
│ │   THUMBNAIL     │ │  56dp x 56dp (channel)
│ │                 │ │  or 16:9 (movie)
│ └─────────────────┘ │
│ Channel Name        │  14sp
│ Now: Program Title  │  12sp, secondary color
└─────────────────────┘
Width: 100-120dp
Interaction: Tap to view, long-press for menu
```

**TV Card:**
```
┌───────────────────────────────┐
│ ┌───────────────────────────┐ │
│ │                           │ │
│ │                           │ │
│ │       THUMBNAIL           │ │  160dp x 90dp (16:9)
│ │                           │ │
│ │                           │ │
│ └───────────────────────────┘ │
│ Channel Name                  │  18sp
│ Now: Program Title            │  14sp, secondary color
│ 8:00 PM - 9:00 PM             │  12sp, tertiary color
└───────────────────────────────┘
Width: 180-220dp
Focus state: Scale 1.05x, bright border, shadow
Interaction: D-pad navigate, Select to view/play
```

#### Player Controls

**Mobile Player:**
```
┌────────────────────────────────────────────────────────────────┐
│ [Back] ←              Channel Name              → [Cast] [⋮]  │
│                                                                │
│                                                                │
│                                                                │
│                         VIDEO                                  │
│                                                                │
│                 Tap anywhere to toggle                         │
│                                                                │
│                                                                │
│                                                                │
│                                                                │
│         [⏪]    [⏸️]    [⏩]                                    │
│                                                                │
│  ▶────────────●────────────────────────────────────────  Live │
│                                                                │
│  [🔊]  [CC]  [Settings]                                        │
└────────────────────────────────────────────────────────────────┘

Gestures:
- Tap: Toggle controls visibility
- Double-tap left/right: Seek -10s/+10s
- Swipe up/down (left side): Brightness
- Swipe up/down (right side): Volume
- Pinch: Aspect ratio toggle
```

**TV Player:**
```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│  Channel Name                                   [HD] [CC] LIVE         │
│  Now: Program Title                                                     │
│                                                                         │
│                                                                         │
│                                                                         │
│                              VIDEO                                      │
│                                                                         │
│                                                                         │
│                                                                         │
│                                                                         │
│                                                                         │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐       │
│   │ ⏪  │  │*⏸️* │  │ ⏩  │  │ 🔊 │  │ CC  │  │ EPG │  │ Info│       │
│   └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘       │
│               ↑                                                         │
│           FOCUSED                                                       │
│                                                                         │
│   Next: Program Title (9:00 PM)                                         │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘

Controls:
- D-pad Up: Show info overlay (now/next, channel info)
- D-pad Down: Show channel list overlay
- D-pad Left/Right: Navigate controls (when visible)
- Select: Activate focused control
- Back: Hide controls, then exit player
- Play/Pause button: Direct toggle (no navigation needed)
- Ch+/Ch-: Change channel (if available on remote)
```

### 3.3 Information Density

| Element | Mobile | Tablet | TV |
|---------|--------|--------|------|
| Font base size | 14sp | 14sp | 18sp |
| Card width | 100-120dp | 140-160dp | 180-220dp |
| Grid columns | 3-4 | 4-6 | 5-7 |
| Row padding | 8dp | 12dp | 24dp |
| Section spacing | 16dp | 24dp | 32dp |
| Icon size | 24dp | 24dp | 32dp |

### 3.4 Screen-by-Screen Breakdown

#### Home Screen

**Mobile:**
- Vertical scroll with horizontal content rows
- "Continue Watching" at top
- Category rows: Live TV, Movies, Series
- Quick access to favorites

**TV:**
- Side rail with main categories
- Horizontal rows for content
- Hero banner for featured content (optional)
- Focus starts on first content item

#### Channel List

**Mobile:**
```
Category Tabs (horizontal scroll)
─────────────────────────────────
┌─────────────────────────────┐
│ 🔴 Channel Logo  Channel 1  │
│    Now: Show Title          │
│    8:00 - 9:00 PM          │
├─────────────────────────────┤
│ 🟢 Channel Logo  Channel 2  │
│    Now: Movie Title         │
│    7:30 - 10:00 PM         │
├─────────────────────────────┤
...
```

**TV:**
```
┌──────────────────────────────────────────────────────────────────┐
│  LIVE TV                                           [A-Z] [🔍]    │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ALL  |  SPORTS  |  NEWS  |  ENTERTAINMENT  |  KIDS  |  ...     │
│  ───                                                              │
│                                                                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│  │  Logo   │ │  Logo   │ │  Logo   │ │  Logo   │ │  Logo   │    │
│  │ *ESPN* │ │  CNN    │ │  HBO    │ │  Fox    │ │  ABC    │    │
│  │ Game   │ │ News    │ │ Movie   │ │ Show    │ │ News    │    │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
│       ↑                                                          │
│   FOCUSED                                                        │
│                                                                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│  │  Logo   │ │  Logo   │ │  Logo   │ │  Logo   │ │  Logo   │    │
│  │  NBC    │ │  CBS    │ │  TNT    │ │  USA    │ │  TBS    │    │
│  │ Show    │ │ Show    │ │ Movie   │ │ Show    │ │ Comedy  │    │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

#### EPG Guide

**Mobile:**
```
┌─────────────────────────────────────┐
│  EPG Guide             [Today ▼]   │
├─────────────────────────────────────┤
│  ← 7:00 PM   8:00 PM   9:00 PM →   │
├────────┬────────────────────────────┤
│  ESPN  │ Game █████████████        │
├────────┼────────────────────────────┤
│  CNN   │ News ████  Anderson ████  │
├────────┼────────────────────────────┤
│  HBO   │ Movie ████████████████    │
├────────┼────────────────────────────┤

Interaction:
- Swipe left/right: Scroll timeline
- Swipe up/down: Scroll channels
- Tap program: Show details modal
- Long-press: Set reminder
```

**TV:**
```
┌──────────────────────────────────────────────────────────────────────────┐
│  EPG GUIDE                                        Wednesday, Jan 15      │
├──────────────────────────────────────────────────────────────────────────┤
│           │ 7:00 PM    │ 7:30 PM    │ 8:00 PM    │ 8:30 PM    │ 9:00    │
│           │            │            │            │            │          │
├───────────┼────────────┴────────────┼────────────┴────────────┼──────────┤
│   ESPN    │     NBA Basketball      │*    SportsCenter      *│  NFL...  │
│           │     Lakers vs Celtics   │ ←── FOCUSED ────────→  │          │
├───────────┼────────────┬────────────┼────────────┬────────────┼──────────┤
│   CNN     │   News     │  Anderson  │   Cooper   │    360     │  News    │
│           │            │  Cooper    │   360      │            │          │
├───────────┼────────────┴────────────┴────────────┴────────────┼──────────┤
│   HBO     │              Movie: The Batman                    │  Real... │
│           │                                                   │          │
├───────────┼────────────┬────────────┬────────────┬────────────┼──────────┤
│   Fox     │   News     │  Show      │   Show     │  Show      │  Late... │
│           │            │            │            │            │          │
└───────────┴────────────┴────────────┴────────────┴────────────┴──────────┘

│                                                                           │
│  [Now]  [+1 Hour]  [-1 Hour]  [Date]                [Watch] [Reminder]   │
│                                                                           │

Navigation:
- D-pad: Move focus between programs
- Select on program: Show options (Watch, Reminder, Info)
- Fast forward/rewind: Jump ±1 hour
- Channel up/down: Jump ±5 channels
```

---

## 4. Flutter Implementation

### 4.1 Form Factor Detection

```dart
// lib/core/platform/form_factor.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FormFactor {
  phone,
  tablet,
  tv,
  desktop,
  web,
}

enum InputMode {
  touch,
  dpad,
  keyboard,
  mouse,
}

class PlatformInfo {
  static FormFactor? _cachedFormFactor;
  static InputMode? _cachedInputMode;

  /// Detect form factor based on platform and screen size
  static Future<FormFactor> detectFormFactor(Size screenSize) async {
    if (_cachedFormFactor != null) return _cachedFormFactor!;

    if (kIsWeb) {
      _cachedFormFactor = FormFactor.web;
      return FormFactor.web;
    }

    if (Platform.isAndroid) {
      // Check if running on Android TV
      final isTV = await _isAndroidTV();
      if (isTV) {
        _cachedFormFactor = FormFactor.tv;
        return FormFactor.tv;
      }

      // Check screen size for phone vs tablet
      final shortestSide = screenSize.shortestSide;
      _cachedFormFactor = shortestSide < 600 ? FormFactor.phone : FormFactor.tablet;
      return _cachedFormFactor!;
    }

    if (Platform.isIOS) {
      final shortestSide = screenSize.shortestSide;
      _cachedFormFactor = shortestSide < 600 ? FormFactor.phone : FormFactor.tablet;
      return _cachedFormFactor!;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      _cachedFormFactor = FormFactor.desktop;
      return FormFactor.desktop;
    }

    _cachedFormFactor = FormFactor.phone;
    return FormFactor.phone;
  }

  /// Check if running on Android TV / Fire TV
  static Future<bool> _isAndroidTV() async {
    if (!Platform.isAndroid) return false;

    try {
      const channel = MethodChannel('com.kylos.iptvplayer/platform');
      final result = await channel.invokeMethod<bool>('isAndroidTV');
      return result ?? false;
    } catch (e) {
      // Fallback: check for TV feature via package info
      return false;
    }
  }

  /// Detect primary input mode
  static InputMode detectInputMode(FormFactor formFactor) {
    if (_cachedInputMode != null) return _cachedInputMode!;

    switch (formFactor) {
      case FormFactor.phone:
      case FormFactor.tablet:
        _cachedInputMode = InputMode.touch;
        break;
      case FormFactor.tv:
        _cachedInputMode = InputMode.dpad;
        break;
      case FormFactor.desktop:
      case FormFactor.web:
        _cachedInputMode = InputMode.keyboard;
        break;
    }

    return _cachedInputMode!;
  }
}
```

**Android Platform Channel (Kotlin):**

```kotlin
// android/app/src/main/kotlin/.../PlatformPlugin.kt

package com.kylos.iptvplayer

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PlatformPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.kylos.iptvplayer/platform")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAndroidTV" -> {
                val uiModeManager = context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                val isTV = uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
                result.success(isTV)
            }
            "isFireTV" -> {
                val isFireTV = context.packageManager.hasSystemFeature("amazon.hardware.fire_tv")
                result.success(isFireTV)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

### 4.2 Responsive Layout System

```dart
// lib/core/layout/responsive.dart

import 'package:flutter/material.dart';

/// Breakpoints following Material Design guidelines
class Breakpoints {
  static const double phone = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
  static const double tv = 1920;
}

/// Layout configuration per breakpoint
class LayoutConfig {
  final int gridColumns;
  final double gutterWidth;
  final double marginWidth;
  final EdgeInsets contentPadding;
  final double cardWidth;
  final double fontSize;

  const LayoutConfig({
    required this.gridColumns,
    required this.gutterWidth,
    required this.marginWidth,
    required this.contentPadding,
    required this.cardWidth,
    required this.fontSize,
  });

  static LayoutConfig phone() => const LayoutConfig(
        gridColumns: 4,
        gutterWidth: 8,
        marginWidth: 16,
        contentPadding: EdgeInsets.all(16),
        cardWidth: 100,
        fontSize: 14,
      );

  static LayoutConfig tablet() => const LayoutConfig(
        gridColumns: 8,
        gutterWidth: 16,
        marginWidth: 24,
        contentPadding: EdgeInsets.all(24),
        cardWidth: 140,
        fontSize: 14,
      );

  static LayoutConfig tv() => const LayoutConfig(
        gridColumns: 12,
        gutterWidth: 24,
        marginWidth: 48,
        contentPadding: EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        cardWidth: 200,
        fontSize: 18,
      );
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.tv,
  });

  final Widget phone;
  final Widget? tablet;
  final Widget? tv;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // TV detection takes priority over size
        final formFactor = context.formFactor;
        if (formFactor == FormFactor.tv && tv != null) {
          return tv!;
        }

        if (width >= Breakpoints.tablet && tablet != null) {
          return tablet!;
        }

        return phone;
      },
    );
  }
}

/// Extension for easy access
extension ResponsiveContext on BuildContext {
  FormFactor get formFactor {
    // Access from provider or inherited widget
    return FormFactor.phone; // Placeholder
  }

  LayoutConfig get layout {
    switch (formFactor) {
      case FormFactor.phone:
        return LayoutConfig.phone();
      case FormFactor.tablet:
        return LayoutConfig.tablet();
      case FormFactor.tv:
        return LayoutConfig.tv();
      default:
        return LayoutConfig.phone();
    }
  }

  bool get isTV => formFactor == FormFactor.tv;
  bool get isMobile => formFactor == FormFactor.phone || formFactor == FormFactor.tablet;
}
```

### 4.3 Focus Management System

```dart
// lib/core/tv/focus_system.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper for focusable TV widgets
class FocusableWidget extends StatefulWidget {
  const FocusableWidget({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocusChange,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusNode,
    this.focusedDecoration,
    this.unfocusedDecoration,
    this.scaleOnFocus = 1.05,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onSelect;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final bool canRequestFocus;
  final FocusNode? focusNode;
  final BoxDecoration? focusedDecoration;
  final BoxDecoration? unfocusedDecoration;
  final double scaleOnFocus;
  final Duration animationDuration;

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnFocus,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() => _isFocused = hasFocus);
      widget.onFocusChange?.call(hasFocus);

      if (hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle select/enter key
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.canRequestFocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: _isFocused
                    ? widget.focusedDecoration ?? _defaultFocusedDecoration(context)
                    : widget.unfocusedDecoration,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _defaultFocusedDecoration(BuildContext context) {
    return BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 3,
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
```

### 4.4 TV Navigation Manager

```dart
// lib/core/tv/tv_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages focus traversal for TV layouts
class TVNavigationManager extends StatefulWidget {
  const TVNavigationManager({
    super.key,
    required this.child,
    this.onBackPressed,
  });

  final Widget child;
  final VoidCallback? onBackPressed;

  @override
  State<TVNavigationManager> createState() => _TVNavigationManagerState();
}

class _TVNavigationManagerState extends State<TVNavigationManager> {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _tvShortcuts,
      child: Actions(
        actions: {
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (_) {
              widget.onBackPressed?.call();
              return null;
            },
          ),
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (intent) {
              _handleDirectionalFocus(intent.direction);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: widget.child,
        ),
      ),
    );
  }

  static final _tvShortcuts = <ShortcutActivator, Intent>{
    // D-pad navigation
    const SingleActivator(LogicalKeyboardKey.arrowUp):
        const DirectionalFocusIntent(TraversalDirection.up),
    const SingleActivator(LogicalKeyboardKey.arrowDown):
        const DirectionalFocusIntent(TraversalDirection.down),
    const SingleActivator(LogicalKeyboardKey.arrowLeft):
        const DirectionalFocusIntent(TraversalDirection.left),
    const SingleActivator(LogicalKeyboardKey.arrowRight):
        const DirectionalFocusIntent(TraversalDirection.right),

    // Back button
    const SingleActivator(LogicalKeyboardKey.goBack): const BackIntent(),
    const SingleActivator(LogicalKeyboardKey.escape): const BackIntent(),
    const SingleActivator(LogicalKeyboardKey.browserBack): const BackIntent(),

    // Media keys
    const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
        const PlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPlay): const PlayIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPause): const PauseIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaFastForward):
        const SeekForwardIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaRewind):
        const SeekBackwardIntent(),
  };

  void _handleDirectionalFocus(TraversalDirection direction) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return;

    primaryFocus.focusInDirection(direction);
  }
}

// Custom intents for TV actions
class BackIntent extends Intent {
  const BackIntent();
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class PlayIntent extends Intent {
  const PlayIntent();
}

class PauseIntent extends Intent {
  const PauseIntent();
}

class SeekForwardIntent extends Intent {
  const SeekForwardIntent();
}

class SeekBackwardIntent extends Intent {
  const SeekBackwardIntent();
}
```

### 4.5 Horizontal Scrolling Row for TV

```dart
// lib/shared/widgets/tv/horizontal_content_row.dart

import 'package:flutter/material.dart';
import 'package:kylos_player/core/tv/focus_system.dart';

/// TV-optimized horizontal scrolling row with focus management
class HorizontalContentRow<T> extends StatefulWidget {
  const HorizontalContentRow({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.onItemSelected,
    this.itemWidth = 200,
    this.itemSpacing = 16,
    this.autofocus = false,
  });

  final String title;
  final List<T> items;
  final Widget Function(BuildContext context, T item, bool isFocused) itemBuilder;
  final void Function(T item)? onItemSelected;
  final double itemWidth;
  final double itemSpacing;
  final bool autofocus;

  @override
  State<HorizontalContentRow<T>> createState() => _HorizontalContentRowState<T>();
}

class _HorizontalContentRowState<T> extends State<HorizontalContentRow<T>> {
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final offset = index * (widget.itemWidth + widget.itemSpacing);
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = offset - (screenWidth / 2) + (widget.itemWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: 16),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: widget.itemWidth * 0.75, // Aspect ratio
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];

              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.items.length - 1 ? widget.itemSpacing : 0,
                ),
                child: SizedBox(
                  width: widget.itemWidth,
                  child: FocusableWidget(
                    autofocus: widget.autofocus && index == 0,
                    onFocusChange: (hasFocus) {
                      if (hasFocus) {
                        setState(() => _focusedIndex = index);
                        _scrollToIndex(index);
                      }
                    },
                    onSelect: () => widget.onItemSelected?.call(item),
                    child: Builder(
                      builder: (context) {
                        final isFocused = _focusedIndex == index &&
                            Focus.of(context).hasFocus;
                        return widget.itemBuilder(context, item, isFocused);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

### 4.6 Platform-Adaptive Card

```dart
// lib/shared/widgets/content_card.dart

import 'package:flutter/material.dart';
import 'package:kylos_player/core/layout/responsive.dart';
import 'package:kylos_player/core/tv/focus_system.dart';

/// Content card that adapts to mobile and TV
class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
    this.isFocused = false,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final isTV = context.isTV;
    final layout = context.layout;

    if (isTV) {
      return _TVCard(
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        isFocused: isFocused,
        cardWidth: layout.cardWidth,
        fontSize: layout.fontSize,
      );
    }

    return _MobileCard(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      onTap: onTap,
      cardWidth: layout.cardWidth,
      fontSize: layout.fontSize,
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onTap,
    required this.cardWidth,
    required this.fontSize,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double cardWidth;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Icon(Icons.tv, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: fontSize - 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TVCard extends StatelessWidget {
  const _TVCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.isFocused,
    required this.cardWidth,
    required this.fontSize,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isFocused;
  final double cardWidth;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isFocused
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              )
            : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      transform: isFocused
          ? (Matrix4.identity()..scale(1.05))
          : Matrix4.identity(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.tv, size: 48)
                  : null,
            ),
          ),
          // Info section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFocused
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: isFocused
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: isFocused
                        ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Platform Limitations and Mitigations

### 5.1 Flutter on Android TV / Fire TV

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| Focus system requires manual setup | Medium | Custom FocusableWidget wrapper |
| No built-in Leanback support | High | Implement Leanback-like patterns manually |
| Default scroll physics not TV-friendly | Medium | Custom PageScrollPhysics for rows |
| On-screen keyboard poor for TV | Medium | Prioritize voice search, minimal text input |
| Remote key mapping varies | Low | Map common keys, test on multiple devices |
| Picture-in-Picture requires native code | Low | Platform channel implementation |

#### Mitigation: Leanback-Style Navigation

```dart
// lib/core/tv/leanback_row.dart

import 'package:flutter/material.dart';

/// Leanback-style row that snaps to items
class LeanbackRow extends StatefulWidget {
  const LeanbackRow({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 200,
    this.focusedItemIndex = 0,
    this.onFocusedItemChanged,
  });

  final int itemCount;
  final Widget Function(BuildContext, int, bool) itemBuilder;
  final double itemExtent;
  final int focusedItemIndex;
  final ValueChanged<int>? onFocusedItemChanged;

  @override
  State<LeanbackRow> createState() => _LeanbackRowState();
}

class _LeanbackRowState extends State<LeanbackRow> {
  late ScrollController _scrollController;
  late int _focusedIndex;

  @override
  void initState() {
    super.initState();
    _focusedIndex = widget.focusedItemIndex;
    _scrollController = ScrollController(
      initialScrollOffset: _calculateOffset(_focusedIndex),
    );
  }

  double _calculateOffset(int index) {
    // Center the focused item
    final screenWidth = MediaQuery.of(context).size.width;
    final itemStart = index * widget.itemExtent;
    return itemStart - (screenWidth / 2) + (widget.itemExtent / 2);
  }

  void _animateToIndex(int index) {
    final offset = _calculateOffset(index);
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemExtent * 0.8, // Height based on item extent
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Control via focus
        itemCount: widget.itemCount,
        itemExtent: widget.itemExtent,
        itemBuilder: (context, index) {
          return widget.itemBuilder(context, index, index == _focusedIndex);
        },
      ),
    );
  }
}
```

### 5.2 Flutter on Samsung Tizen

| Limitation | Impact | Mitigation |
|------------|--------|------------|
| Experimental flutter-tizen project | High | Plan for alternative approaches |
| Limited plugin ecosystem | High | Custom platform channels for Tizen APIs |
| Different app lifecycle | Medium | Tizen-specific lifecycle handling |
| Performance concerns | Medium | Profile and optimize for Tizen hardware |
| Samsung certification requirements | High | Dedicated testing and compliance pass |

#### Mitigation Options

**Option A: Flutter-Tizen (Experimental)**
- Use flutter-tizen fork for shared codebase
- Accept limitations and potential instability
- Maintain Tizen-specific workarounds

**Option B: Native Tizen Web App**
- Develop separate Tizen web app using Tizen Web SDK
- Share backend API and business logic concepts
- Independent UI implementation

**Option C: React Native / NativeScript**
- Use alternative cross-platform framework with better Tizen support
- Share some business logic via shared packages

**Recommendation**: Start with Option A in Phase 3, with Option B as fallback if flutter-tizen proves too unstable.

### 5.3 Video Playback Across Platforms

| Platform | Player Recommendation | Notes |
|----------|----------------------|-------|
| Android Mobile | media_kit (libmpv) | Best codec support, hardware acceleration |
| Android TV | media_kit (libmpv) | Same as mobile, works well |
| Fire TV | media_kit (libmpv) | Test Amazon-specific codecs |
| iOS | media_kit (libmpv) or AVPlayer | AVPlayer for better HLS support |
| Samsung Tizen | AVPlay (native) | Must use Samsung's player API |

#### Player Abstraction Layer

```dart
// lib/infrastructure/player/player_interface.dart

abstract class PlayerInterface {
  /// Initialize the player
  Future<void> initialize();

  /// Dispose resources
  Future<void> dispose();

  /// Play a stream
  Future<void> play(String url, {Map<String, String>? headers});

  /// Pause playback
  Future<void> pause();

  /// Resume playback
  Future<void> resume();

  /// Stop playback
  Future<void> stop();

  /// Seek to position
  Future<void> seek(Duration position);

  /// Get current position
  Duration get position;

  /// Get total duration
  Duration get duration;

  /// Get buffered position
  Duration get bufferedPosition;

  /// Check if playing
  bool get isPlaying;

  /// Get available audio tracks
  List<AudioTrack> get audioTracks;

  /// Set audio track
  Future<void> setAudioTrack(AudioTrack track);

  /// Get available subtitles
  List<Subtitle> get subtitles;

  /// Set subtitle
  Future<void> setSubtitle(Subtitle? subtitle);

  /// Stream of playback state changes
  Stream<PlaybackState> get stateStream;

  /// Stream of position updates
  Stream<Duration> get positionStream;

  /// Stream of errors
  Stream<PlayerError> get errorStream;

  /// Get the video widget
  Widget get videoWidget;
}

// Factory to get platform-specific implementation
class PlayerFactory {
  static PlayerInterface create() {
    if (Platform.isAndroid || Platform.isIOS) {
      return MediaKitPlayer();
    }
    // Add Tizen implementation when available
    return MediaKitPlayer();
  }
}
```

---

## 6. Phased Rollout Roadmap

### 6.1 Phase 1: Mobile Foundation (Months 1-4)

#### Goals
- Launch on Android and iOS
- Establish core architecture
- Validate product-market fit

#### Deliverables

| Week | Milestone |
|------|-----------|
| 1-2 | Project setup, architecture scaffolding |
| 3-4 | M3U/Xtream parsing, playlist management |
| 5-6 | Channel list, categories, search |
| 7-8 | Video player integration, basic playback |
| 9-10 | EPG guide, favorites, continue watching |
| 11-12 | Profiles, parental controls |
| 13-14 | Monetization, IAP integration |
| 15-16 | Testing, polish, store submission |

#### Platform-Specific Work

**Android:**
- Material 3 theming
- Picture-in-Picture implementation
- Notification media controls
- Back button handling

**iOS:**
- iOS 15+ minimum target
- AirPlay support
- Control Center integration
- App Clips consideration (future)

#### Exit Criteria
- [ ] App published on Google Play and App Store
- [ ] Core features working: playlist, playback, EPG
- [ ] IAP verified and processing payments
- [ ] Crash rate < 1%
- [ ] 4.0+ star rating maintained

### 6.2 Phase 2: TV Platforms (Months 5-8)

#### Goals
- Expand to Android TV and Fire TV
- Implement 10-foot UI
- Maintain single codebase

#### Deliverables

| Week | Milestone |
|------|-----------|
| 17-18 | Form factor detection, responsive scaffolding |
| 19-20 | Focus system implementation, TV navigation |
| 21-22 | TV-specific layouts: home, channel list |
| 23-24 | TV player UI, remote controls |
| 25-26 | EPG grid for TV |
| 27-28 | Fire TV specific: Amazon IAP, voice search |
| 29-30 | TV testing, optimization |
| 31-32 | Store submissions, certification |

#### Technical Work

**Focus System:**
```
Week 17-18:
- Implement FocusableWidget base class
- Create TVNavigationManager
- Handle back button and media keys
- Test focus traversal patterns
```

**Layouts:**
```
Week 19-22:
- Side rail navigation
- Horizontal scrolling rows
- TV-sized cards (180-220dp)
- Focus indicators and animations
```

**Player:**
```
Week 23-24:
- TV control overlay
- D-pad seek controls
- Channel up/down support
- Quick channel switch overlay
```

#### Feature Flags for Rollout

```dart
// Remote Config flags for TV rollout
enum TVFeatureFlag {
  tvPlatformEnabled,        // Master switch for TV builds
  tvBetaAccess,            // Beta tester access
  tvEpgGridEnabled,        // EPG grid view
  tvVoiceSearchEnabled,    // Voice search integration
  tvPipEnabled,            // Picture-in-Picture on TV
}

// Gradual rollout percentages
// Week 1: 5% of TV users
// Week 2: 25% of TV users
// Week 3: 50% of TV users
// Week 4: 100% of TV users
```

#### Exit Criteria
- [ ] App published on Google Play (Android TV) and Amazon Appstore
- [ ] D-pad navigation fully functional
- [ ] All screens adapted for 10-foot UI
- [ ] Remote control playback working
- [ ] Fire TV Alexa integration (voice search)
- [ ] < 5% TV-specific bug reports

### 6.3 Phase 3: Samsung Tizen Evaluation (Months 9-12)

#### Goals
- Evaluate Tizen viability
- Build prototype or decide on alternative
- Ship if feasible

#### Decision Tree

```
                    Start Phase 3
                         │
                         ▼
            ┌────────────────────────┐
            │ Evaluate flutter-tizen │
            │ stability and plugins  │
            └────────────────────────┘
                         │
            ┌────────────┴────────────┐
            │                         │
            ▼                         ▼
     Stable enough?            Not stable?
            │                         │
            ▼                         ▼
   Build Flutter-Tizen      Evaluate alternatives
        prototype            (Web, Native, Skip)
            │                         │
            ▼                         ▼
     Works well?              Worth effort?
      │       │                │       │
      ▼       ▼                ▼       ▼
    Yes      No              Yes      No
      │       │                │       │
      ▼       ▼                ▼       ▼
   Ship it  Try Web        Build Web  Defer
            version          version   Tizen
```

#### Tizen-Specific Considerations

**If Flutter-Tizen:**
- Test on real Samsung TVs (2020+ models)
- Implement Tizen-specific plugins via platform channels
- Use Samsung AVPlay for video playback
- Handle Tizen app lifecycle (suspend/resume)

**If Web App:**
- Use Tizen Web SDK
- Implement UI with web technologies (HTML/CSS/JS)
- Reuse backend APIs and data models
- Accept different maintenance burden

#### Deliverables

| Week | Milestone |
|------|-----------|
| 33-34 | Flutter-tizen setup, prototype skeleton |
| 35-36 | Basic navigation and layout test |
| 37-38 | Video playback with AVPlay |
| 39-40 | Feature parity assessment |
| 41-42 | Decision point: continue or pivot |
| 43-46 | Full implementation (if continuing) |
| 47-48 | Samsung certification and launch |

#### Exit Criteria (if launching)
- [ ] App approved on Samsung Galaxy Store for TVs
- [ ] Playback working on target Samsung TV models
- [ ] Remote navigation functional
- [ ] Core features: playlists, playback, favorites
- [ ] IAP integration (if Samsung supports in-app purchases)

---

## 7. Testing and QA Strategy

### 7.1 Target Devices

#### Mobile (Phase 1)

**Android (minimum 12 devices):**

| Category | Devices | Notes |
|----------|---------|-------|
| Budget | Samsung Galaxy A14, Xiaomi Redmi Note 12 | Low-end performance |
| Mid-range | Samsung Galaxy A54, Google Pixel 6a | Common user segment |
| Flagship | Samsung Galaxy S23, Google Pixel 8 | High-end, latest OS |
| Tablet | Samsung Galaxy Tab A8, Tab S8 | Tablet layouts |

**iOS (minimum 8 devices):**

| Category | Devices | Notes |
|----------|---------|-------|
| Older | iPhone 11, iPhone SE 3rd gen | Minimum supported |
| Current | iPhone 14, iPhone 15 | Primary targets |
| Dynamic Island | iPhone 14 Pro, iPhone 15 Pro | New UI paradigm |
| iPad | iPad 9th gen, iPad Pro 12.9" | Tablet layouts |

#### TV (Phase 2)

**Android TV (minimum 6 devices):**

| Category | Devices | Notes |
|----------|---------|-------|
| Reference | Google TV Chromecast | Pure Android TV |
| Shield | NVIDIA Shield TV Pro | High-end, enthusiast |
| Smart TV | Sony Bravia (Android TV) | Built-in TV experience |
| Budget | Xiaomi Mi TV Stick | Low-end streamer |

**Fire TV (minimum 4 devices):**

| Category | Devices | Notes |
|----------|---------|-------|
| Stick | Fire TV Stick 4K Max | Most common |
| Cube | Fire TV Cube | With Alexa |
| Built-in | Toshiba/Insignia Fire TV | Integrated experience |
| Stick Lite | Fire TV Stick Lite | Budget model |

#### Samsung Tizen (Phase 3)

| Category | Devices | Notes |
|----------|---------|-------|
| 2020 | Samsung TU8000 | Older Tizen |
| 2021 | Samsung AU8000 | Mid-range |
| 2022 | Samsung S95B | High-end OLED |
| 2023 | Samsung CU8000 | Current gen |

### 7.2 Emulators and Simulators

| Platform | Tool | Usage |
|----------|------|-------|
| Android Phone | Android Studio Emulator | Development, CI |
| Android TV | Android TV Emulator (x86) | Development |
| Fire TV | Fire TV Emulator | Development |
| iOS | Xcode Simulator | Development, CI |
| Samsung Tizen | Tizen Studio Emulator | Development |

**CI Device Farm Services:**

- Firebase Test Lab (Android, iOS)
- AWS Device Farm (Android, iOS, Fire TV)
- BrowserStack App Live (Android, iOS)
- Samsung Remote Test Lab (Tizen)

### 7.3 Test Categories

#### Functional Testing

| Category | Tests |
|----------|-------|
| Playlist Management | Add/edit/delete M3U URL, Xtream, file |
| Playback | Start, pause, resume, seek, stop |
| Channel Navigation | Browse, filter, search, favorites |
| EPG | Load, display, navigate, reminders |
| Profiles | Create, switch, delete, parental controls |
| Settings | Theme, language, player, notifications |
| Monetization | Purchase, restore, entitlement check |

#### Platform-Specific Testing

**Mobile:**
| Test | Android | iOS |
|------|---------|-----|
| Back navigation | System back button | Swipe gesture |
| Background playback | Service + notification | Background modes |
| PiP | Activity flag | AVPictureInPictureController |
| Cast | Chromecast SDK | AirPlay |
| Deep links | Intent filters | Universal links |

**TV:**
| Test | Android TV | Fire TV |
|------|------------|---------|
| Focus traversal | D-pad all directions | D-pad all directions |
| Remote keys | Play, pause, FF, RW | + Alexa button |
| Voice search | Google Assistant | Alexa |
| Quick switch | Channel up/down | Channel up/down |
| Sleep/resume | Activity lifecycle | Activity lifecycle |

#### Performance Testing

| Metric | Target | Tool |
|--------|--------|------|
| Cold start time | < 3 seconds | Firebase Performance |
| Channel switch time | < 2 seconds | Custom timing |
| EPG load time | < 5 seconds | Custom timing |
| Frame rate | 60 fps (smooth) | Flutter DevTools |
| Memory usage | < 200MB idle | Android Profiler |
| Battery drain | < 5% per hour (playback) | System tools |

#### Playback Testing

| Test Case | Streams to Test |
|-----------|-----------------|
| HLS VOD | Standard HLS manifest |
| HLS Live | Live HLS with DVR |
| MPEG-TS | Raw TS streams |
| HTTP Direct | MP4, MKV direct links |
| Xtream API | Multiple provider formats |
| DRM (future) | Widevine, FairPlay |

| Scenario | Test |
|----------|------|
| Network switch | WiFi to mobile during playback |
| Network loss | Graceful handling, retry |
| Seek | Jump forward/backward, edge cases |
| Audio tracks | Switch language mid-playback |
| Subtitles | Enable/disable, switch language |
| Quality switch | Auto and manual quality changes |

### 7.4 QA Process

#### Automated Testing

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  unit_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test --coverage

  integration_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test integration_test/

  widget_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test test/widget/

  golden_tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test --update-goldens test/golden/

  device_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run on Firebase Test Lab
        uses: asadmansr/Firebase-Test-Lab-Action@v1
        with:
          arg-spec: tests.yml:device-tests
```

#### Manual QA Checklist

```markdown
## Pre-Release Checklist

### Core Functionality
- [ ] Add M3U URL playlist
- [ ] Add Xtream playlist
- [ ] Refresh playlist content
- [ ] Browse channel list
- [ ] Search channels
- [ ] Play live channel
- [ ] Play VOD content
- [ ] Add to favorites
- [ ] View EPG guide
- [ ] Set program reminder

### Playback
- [ ] Play/Pause
- [ ] Seek forward/backward
- [ ] Change audio track
- [ ] Enable/disable subtitles
- [ ] Quality selection (if available)
- [ ] PiP mode (mobile)

### TV-Specific (Phase 2+)
- [ ] D-pad navigation in all screens
- [ ] Focus indicators visible
- [ ] Remote play/pause buttons
- [ ] Voice search (Android TV/Fire TV)
- [ ] Channel up/down in player

### Monetization
- [ ] View paywall
- [ ] Complete purchase flow
- [ ] Restore purchases
- [ ] Pro features unlocked

### Edge Cases
- [ ] No network connection
- [ ] Expired/invalid playlist
- [ ] Empty search results
- [ ] Player error handling
- [ ] Background/foreground transitions
```

### 7.5 Feature Flag Strategy for TV Rollout

```dart
// Remote Config setup for TV rollout

class TVRolloutConfig {
  // Master switch
  static const String tvEnabled = 'tv_platform_enabled';

  // Percentage rollout
  static const String tvRolloutPercent = 'tv_rollout_percent';

  // Feature-specific flags
  static const String tvEpgGrid = 'tv_epg_grid_enabled';
  static const String tvVoiceSearch = 'tv_voice_search_enabled';
  static const String tvQuickChannelSwitch = 'tv_quick_channel_switch';

  // Debug/beta flags
  static const String tvDebugMode = 'tv_debug_mode';
  static const String tvBetaTester = 'tv_beta_tester';
}

// Rollout schedule example
// Week 1: tv_rollout_percent = 5
// Week 2: tv_rollout_percent = 25
// Week 3: tv_rollout_percent = 50
// Week 4: tv_rollout_percent = 100
```

---

## 8. Appendices

### 8.1 Key Metrics to Track

| Metric | Description | Target |
|--------|-------------|--------|
| DAU/MAU ratio | Daily engagement | > 30% |
| Session duration | Time in app | > 15 min |
| Playback success rate | Streams started successfully | > 95% |
| Crash-free rate | Sessions without crash | > 99% |
| TV adoption rate | TV users / Total users | > 20% (Phase 2) |
| Focus navigation errors | Failed focus movements | < 1% on TV |

### 8.2 Accessibility Considerations

| Platform | Requirements |
|----------|--------------|
| Android | TalkBack support, content descriptions |
| iOS | VoiceOver support, accessibility labels |
| Android TV | TalkBack support, focus announcements |
| Fire TV | VoiceView support |

### 8.3 Localization Strategy

| Priority | Languages |
|----------|-----------|
| P0 (Launch) | English, Spanish |
| P1 (Month 3) | Portuguese, French, German |
| P2 (Month 6) | Italian, Russian, Arabic |
| P3 (Month 9) | Japanese, Korean, Chinese (Simplified) |

### 8.4 Resource Links

| Resource | URL |
|----------|-----|
| Android TV Design Guidelines | https://developer.android.com/design/ui/tv |
| Fire TV UX Guidelines | https://developer.amazon.com/docs/fire-tv/design-and-user-experience-guidelines.html |
| Flutter Focus System | https://docs.flutter.dev/development/ui/advanced/focus |
| flutter-tizen | https://github.com/pnmr/flutter-tizen |
| Samsung Tizen Developer | https://developer.tizen.org |

---

## Summary

This multi-platform strategy provides:

1. **Adaptive UX**: Platform-native experiences for mobile and TV
2. **Unified codebase**: Single Flutter project with responsive breakpoints
3. **Custom focus system**: Robust D-pad navigation for TV platforms
4. **Phased rollout**: Mobile first, TV second, Tizen evaluated third
5. **Comprehensive testing**: Device coverage across all target platforms
6. **Feature flags**: Gradual TV rollout with quick rollback capability

The architecture is designed to maximize code sharing while delivering optimal experiences on each platform.
