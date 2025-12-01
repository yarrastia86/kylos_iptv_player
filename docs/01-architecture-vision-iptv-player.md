# Kylos IPTV Player - Architecture Vision Document

**Version:** 1.0
**Date:** November 2024
**Status:** Draft

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Competitive Analysis](#2-competitive-analysis)
3. [Technology Evaluation](#3-technology-evaluation)
4. [High-Level Architecture](#4-high-level-architecture)
5. [Bounded Contexts and Modules](#5-bounded-contexts-and-modules)
6. [Technology Stack Decisions](#6-technology-stack-decisions)
7. [Monetization Strategy](#7-monetization-strategy)
8. [Risks and Open Questions](#8-risks-and-open-questions)
9. [Appendices](#9-appendices)

---

## 1. Executive Summary

This document outlines the architecture vision for **Kylos IPTV Player**, a cross-platform IPTV media player application. The app will serve as a **media player only**, allowing users to configure their own legally acquired IPTV sources (M3U, M3U8, Xtream Codes API). Kylos IPTV Player will NOT host, distribute, or recommend any content.

### Core Value Proposition

- High-quality, stable media playback experience
- Support for Live TV, VOD (Movies/Series), and EPG
- Cross-platform availability: Android, iOS, Android TV, Fire TV, with future Samsung Tizen support
- User-centric features: favorites, search, continue watching, parental controls, multiple profiles
- Ethical monetization through freemium model and optional ads

### Target Platforms (Priority Order)

1. **Phase 1:** Android (phones/tablets), iOS (iPhone/iPad)
2. **Phase 2:** Android TV, Amazon Fire TV
3. **Phase 3:** Samsung Tizen Smart TVs (conditional on Flutter-Tizen maturity)
4. **Future:** Apple TV, webOS (LG), potentially web

---

## 2. Competitive Analysis

### 2.1 Smarters Pro Overview

IPTV Smarters Pro, developed by WHMCS Smarters, is the de facto reference in this space. Key observations:

| Aspect | Smarters Pro | Our Target |
|--------|--------------|------------|
| **Playlist Support** | M3U, M3U8, Xtream Codes API | M3U, M3U8, Xtream Codes API (parity) |
| **Content Types** | Live TV, Movies, Series, Catch-up | Live TV, Movies, Series, Catch-up |
| **EPG Support** | Built-in via Xtream, manual XMLTV | Built-in via Xtream, manual XMLTV |
| **Parental Control** | PIN-based locking | PIN-based locking |
| **Multi-User** | Multiple IPTV subscriptions | Multiple profiles + subscriptions |
| **Platforms** | Android, iOS, Fire TV, Windows, macOS, Smart TVs | Flutter-based cross-platform |
| **Monetization** | Freemium + Pro unlock | Freemium + subscription/IAP |

### 2.2 Other Notable Competitors

| App | Strengths | Weaknesses |
|-----|-----------|------------|
| **TiviMate** | Excellent EPG, recording, Android TV focus | Android-only, complex for beginners |
| **GSE Smart IPTV** | Multi-platform, good codec support | Dated UI, stability issues reported |
| **IPTV Smart Player** | Clean UI, good App Store presence | Limited advanced features |
| **OTT Navigator** | Feature-rich, provider panels | Steep learning curve |

### 2.3 UX Expectations from Competitors

Based on competitor analysis, users expect:

- **Onboarding:** Simple playlist/provider setup (URL paste, file upload, or Xtream login)
- **Navigation:** Category-based browsing with search
- **Playback:** Fast channel switching (<2s), buffer management, quality selection
- **EPG:** Grid-style guide with current/next program info
- **Personalization:** Favorites, recently watched, continue watching for VOD
- **TV Experience:** D-pad/remote navigation, 10-foot UI design
- **Reliability:** Crash-free experience, graceful error handling

### 2.4 Legal Positioning (Critical)

All successful IPTV players in app stores share a common legal stance:

> **Required Disclaimer Pattern:**
> - The app is a media player only
> - Does not provide, host, or distribute any content
> - Users are responsible for ensuring they have legal rights to accessed content
> - The developer has no affiliation with any IPTV service providers
> - Streaming copyrighted content without permission is prohibited

**Our app MUST include:**
1. Terms of Service with clear legal disclaimer
2. In-app disclaimer during onboarding
3. App Store description explicitly stating "player only" status
4. No links to or recommendations of IPTV providers

---

## 3. Technology Evaluation

### 3.1 Flutter Evaluation

#### 3.1.1 Mobile (Android/iOS) - RECOMMENDED

| Criterion | Assessment | Notes |
|-----------|------------|-------|
| **Maturity** | Excellent | Production-ready, used by major apps |
| **Video Playback** | Good | Via `video_player`, `media_kit`, or `better_player` |
| **Performance** | Excellent | Native compilation, 60fps UI |
| **Codec Support** | Good | Platform codecs + optional FFmpeg via media_kit |
| **Developer Experience** | Excellent | Hot reload, strong tooling |

**Verdict:** Flutter is highly appropriate for mobile IPTV development.

#### 3.1.2 Android TV / Fire TV - RECOMMENDED WITH CAVEATS

| Criterion | Assessment | Notes |
|-----------|------------|-------|
| **Official Support** | Good | Flutter supports Android TV as target |
| **D-pad Navigation** | Moderate | Requires custom focus management |
| **10-foot UI** | Manual | Need dedicated TV layouts, no built-in Leanback |
| **Video Playback** | Good | ExoPlayer integration works well |
| **Remote Control** | Moderate | Custom key event handling required |

**Caveats:**
- No built-in equivalent to Android's Leanback library
- Custom focus traversal system needed
- Separate UI layouts recommended for TV vs mobile
- Testing requires physical devices or emulators

**Verdict:** Flutter is viable for Android TV with additional development effort for TV-specific UX.

#### 3.1.3 Samsung Tizen - CONDITIONAL

| Criterion | Assessment | Notes |
|-----------|------------|-------|
| **Official Support** | Partial | Samsung-maintained flutter-tizen project |
| **Device Support** | Limited | Tizen 6.0+ only (2021+ TVs) |
| **Plugin Ecosystem** | Limited | Not all Flutter plugins available |
| **Video Playback** | Available | Via `video_player_avplay` package |
| **DRM Support** | Limited | Platform-specific implementation required |
| **In-App Purchase** | Not Available | No IAP API for Tizen currently |
| **Firebase** | Partial | Not all FlutterFire plugins supported |

**Known Limitations:**
- Cannot target TVs from 2020 or earlier
- No Impeller rendering backend
- Webview plugin unstable
- D-pad navigation requires significant custom work
- No SkSL shader caching (affects startup time)

**Verdict:** Flutter-Tizen is viable for basic functionality but carries significant risk for a production IPTV app. Recommend treating as Phase 3 with dedicated R&D spike.

#### 3.1.4 Flutter Recommendation Summary

```
Platform         | Recommendation | Confidence | Notes
-----------------|----------------|------------|---------------------------
Android Mobile   | YES            | High       | Primary target
iOS Mobile       | YES            | High       | Primary target
Android TV       | YES            | Medium     | Custom TV UX required
Fire TV          | YES            | Medium     | Same as Android TV
Samsung Tizen    | CONDITIONAL    | Low        | Spike required, Phase 3
Apple TV         | POSSIBLE       | Medium     | Via Flutter, less tested
LG webOS         | NO (native)    | N/A        | No Flutter support
```

### 3.2 Backend Evaluation: Firebase vs Alternatives

#### 3.2.1 Firebase (Recommended Primary)

**Pros:**
- Excellent Flutter integration (FlutterFire)
- Comprehensive BaaS: Auth, Firestore, Storage, Functions, FCM, Remote Config, Analytics
- Real-time sync built-in (useful for watchlist, preferences)
- Generous free tier for MVP/launch
- Google-scale reliability and uptime
- RevenueCat integration for cross-platform subscriptions

**Cons:**
- Vendor lock-in to Google ecosystem
- NoSQL (Firestore) less suited for complex relational queries
- Costs can escalate with scale (read/write operations, bandwidth)
- Limited backend logic customization without Cloud Functions

**Cost Projection (Estimates):**
| Users | Monthly Cost (Est.) |
|-------|---------------------|
| 1,000 | Free tier |
| 10,000 | $50-150 |
| 100,000 | $300-800 |
| 1,000,000 | $2,000-5,000+ |

#### 3.2.2 Supabase (Plan B)

**Pros:**
- Open source, self-hostable (avoids lock-in)
- PostgreSQL (relational, powerful queries)
- Real-time subscriptions
- Row-level security
- More predictable pricing with spend caps
- Growing Flutter SDK support

**Cons:**
- Less mature than Firebase
- Flutter SDK less battle-tested
- Smaller community and ecosystem
- Edge functions less integrated than Cloud Functions
- No direct equivalent to Firebase Remote Config

#### 3.2.3 Custom Backend (NestJS + PostgreSQL)

**Pros:**
- Full control over architecture
- No vendor lock-in
- Can optimize for specific IPTV use cases
- Predictable infrastructure costs (VPS/cloud)

**Cons:**
- Significant development overhead
- Must build auth, real-time, push notifications from scratch
- Ongoing maintenance burden
- Slower time-to-market

#### 3.2.4 Backend Recommendation

| Choice | Recommendation | Use Case |
|--------|----------------|----------|
| **Firebase** | PRIMARY | MVP through scale, fastest time-to-market |
| **Supabase** | PLAN B | If cost at scale becomes prohibitive, or if self-hosting required |
| **Custom** | NOT RECOMMENDED | Only if unique requirements emerge |

**Hybrid Approach (Long-term consideration):**
- Use Firebase for Auth, FCM, Remote Config, Analytics
- Use Supabase or custom PostgreSQL for user data if complex queries needed
- RevenueCat for subscription management (abstracts both platforms)

### 3.3 Scalability and Performance Considerations

#### 3.3.1 IPTV-Specific Concerns

| Concern | Mitigation |
|---------|------------|
| **Stream URLs not stored** | Provider URLs fetched on-demand, never persisted in our backend |
| **EPG data volume** | Cache locally, refresh on schedule, not stored in Firebase |
| **Playlist parsing** | Client-side, no backend load |
| **Concurrent users** | Firebase handles this; no streaming through our servers |
| **Channel switching latency** | ExoPlayer/AVPlayer optimization, buffer tuning |

#### 3.3.2 Firebase-Specific Optimizations

- Use Firestore offline persistence for user preferences
- Minimize document reads via caching and batching
- Use Cloud Functions sparingly (cold start latency)
- Leverage Firebase Remote Config for feature flags (minimal reads)

---

## 4. High-Level Architecture

### 4.1 System Context Diagram

```
+------------------------------------------------------------------+
|                        EXTERNAL SYSTEMS                           |
+------------------------------------------------------------------+
|                                                                   |
|   +-------------------+    +-------------------+                  |
|   | IPTV Provider     |    | EPG Provider      |                  |
|   | (User's source)   |    | (XMLTV endpoint)  |                  |
|   +-------------------+    +-------------------+                  |
|          |                        |                               |
|          | M3U/M3U8/              | XMLTV                         |
|          | Xtream API             |                               |
|          v                        v                               |
|   +--------------------------------------------------+           |
|   |            KYLOS IPTV PLAYER APP                  |           |
|   |  +--------------------------------------------+  |           |
|   |  |  Flutter Client Application                |  |           |
|   |  |  - Android / iOS / Android TV / Fire TV    |  |           |
|   |  |  - (Future: Tizen, Apple TV)               |  |           |
|   |  +--------------------------------------------+  |           |
|   +--------------------------------------------------+           |
|          |         |         |         |                          |
|          v         v         v         v                          |
|   +----------+ +--------+ +-------+ +----------+                  |
|   | Firebase | | Revenue| | AdMob | | Analytics|                  |
|   | Backend  | | Cat    | |       | | (Firebase|                  |
|   |          | |        | |       | | +Crashly)|                  |
|   +----------+ +--------+ +-------+ +----------+                  |
|       |                                                           |
|       +-- Auth (Firebase Auth)                                    |
|       +-- User Data (Firestore)                                   |
|       +-- Push Notifications (FCM)                                |
|       +-- Feature Flags (Remote Config)                           |
|       +-- Cloud Functions (server logic)                          |
|                                                                   |
+------------------------------------------------------------------+
```

### 4.2 Data Flow Overview

```
1. USER AUTHENTICATION
   User -> Firebase Auth -> JWT Token -> App authenticated

2. IPTV SOURCE CONFIGURATION
   User enters M3U URL or Xtream credentials
   -> App fetches playlist directly from Provider
   -> Parsed locally, categories/channels extracted
   -> Metadata cached locally (SQLite/Hive)

3. LIVE TV PLAYBACK
   User selects channel -> App retrieves stream URL from playlist
   -> Video player (ExoPlayer/AVPlayer) connects to Provider stream
   -> Stream plays (no data through our backend)

4. EPG LOADING
   App fetches XMLTV from EPG URL (from playlist or user config)
   -> Parsed and stored locally
   -> Displayed in grid/list UI

5. USER PREFERENCES SYNC
   Favorites, watch history, settings
   -> Stored in Firestore (synced across devices)
   -> Offline-first with local cache

6. SUBSCRIPTION MANAGEMENT
   Purchase initiated -> RevenueCat handles transaction
   -> Entitlements synced -> Features unlocked
```

### 4.3 Client Architecture (Clean Architecture)

```
+---------------------------------------------------------------+
|                    PRESENTATION LAYER                          |
|  +----------------------------------------------------------+ |
|  | UI (Widgets)          | State Management (BLoC/Riverpod) | |
|  | - Screens             | - AuthBloc                       | |
|  | - Components          | - PlayerBloc                     | |
|  | - Navigation          | - PlaylistBloc                   | |
|  | - TV/Mobile layouts   | - EpgBloc                        | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
                              |
                              v
+---------------------------------------------------------------+
|                      DOMAIN LAYER                              |
|  +----------------------------------------------------------+ |
|  | Use Cases              | Entities           | Interfaces | |
|  | - AddPlaylist          | - Channel          | - Repos    | |
|  | - PlayChannel          | - Program          | - Services | |
|  | - LoadEpg              | - Playlist         |            | |
|  | - ManageFavorites      | - User             |            | |
|  | - SetParentalPin       | - Profile          |            | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
                              |
                              v
+---------------------------------------------------------------+
|                       DATA LAYER                               |
|  +----------------------------------------------------------+ |
|  | Repositories           | Data Sources                    | |
|  | - PlaylistRepository   | - Remote: HTTP client           | |
|  | - EpgRepository        | - Local: SQLite/Hive            | |
|  | - UserRepository       | - Firebase: Firestore           | |
|  | - SettingsRepository   | - Secure Storage                | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
                              |
                              v
+---------------------------------------------------------------+
|                   INFRASTRUCTURE LAYER                         |
|  +----------------------------------------------------------+ |
|  | Platform Services      | External SDKs                   | |
|  | - Video Player         | - Firebase Auth                 | |
|  | - Background Service   | - Firebase Firestore            | |
|  | - Notifications        | - RevenueCat                    | |
|  | - Secure Storage       | - AdMob                         | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
```

---

## 5. Bounded Contexts and Modules

### 5.1 Module Overview

```
lib/
  +-- core/                    # Shared utilities, constants, extensions
  +-- features/
  |     +-- auth/              # Authentication & user session
  |     +-- onboarding/        # First-run setup, disclaimers
  |     +-- playlist/          # Playlist/provider management
  |     +-- player/            # Video playback engine
  |     +-- live_tv/           # Live channel browsing & playback
  |     +-- vod/               # Movies & series browsing
  |     +-- epg/               # Electronic Program Guide
  |     +-- favorites/         # Favorites management
  |     +-- history/           # Watch history, continue watching
  |     +-- search/            # Global search
  |     +-- settings/          # App settings, preferences
  |     +-- parental/          # Parental controls
  |     +-- profiles/          # Multi-profile support
  |     +-- subscription/      # Monetization, IAP, premium
  +-- shared/                  # Shared widgets, services
  +-- main.dart
```

### 5.2 Bounded Context Details

#### 5.2.1 Playback Engine & Streaming

**Responsibility:** Video playback for live streams and VOD content.

**Key Components:**
- Video player abstraction (platform-agnostic interface)
- Stream protocol handlers (HLS, DASH, RTMP)
- Buffer management and quality adaptation
- Subtitle and audio track selection
- Picture-in-Picture support
- Background audio (for radio channels)

**Technology Choices:**
| Platform | Player | Notes |
|----------|--------|-------|
| Android | ExoPlayer (via media_kit or better_player) | Best HLS/DASH support |
| iOS | AVPlayer (via media_kit or native) | Native performance |
| Android TV | ExoPlayer | Same as Android |
| Tizen | AVPlay (via video_player_avplay) | Platform-specific |

**Recommended Package:** `media_kit` - provides unified API with ExoPlayer (Android) and AVPlayer (iOS/macOS), plus FFmpeg fallback for edge cases.

#### 5.2.2 Playlist & Provider Configuration

**Responsibility:** Managing user's IPTV sources and parsing playlist data.

**Key Components:**
- Playlist model (M3U, M3U8, Xtream Codes)
- M3U parser
- Xtream Codes API client
- Provider credential secure storage
- Playlist refresh and caching

**Data Models:**
```
Playlist
  - id: String
  - name: String
  - type: PlaylistType (M3U, XTREAM)
  - url: String? (for M3U)
  - xtreamCredentials: XtreamCredentials? (for Xtream)
  - lastSync: DateTime
  - categories: List<Category>

XtreamCredentials
  - serverUrl: String
  - username: String
  - password: String (encrypted)

Category
  - id: String
  - name: String
  - type: CategoryType (LIVE, MOVIE, SERIES)

Channel
  - id: String
  - name: String
  - logoUrl: String?
  - streamUrl: String
  - categoryId: String
  - epgId: String?
```

#### 5.2.3 EPG & Metadata

**Responsibility:** Loading, parsing, and displaying program guide information.

**Key Components:**
- XMLTV parser
- Xtream EPG API client
- EPG data caching (local database)
- Program schedule matching with channels
- EPG grid UI component

**Storage Strategy:**
- EPG data stored in local SQLite (via drift or sqflite)
- Refresh on configurable schedule (default: every 12 hours)
- NOT stored in Firebase (too large, unnecessary sync)

#### 5.2.4 User Accounts, Profiles & Preferences

**Responsibility:** User authentication, profile management, and synced preferences.

**Key Components:**
- Firebase Auth integration (email/password, Google, Apple Sign-In)
- Anonymous auth for guest mode
- Profile CRUD operations
- Preferences sync (theme, language, playback settings)
- Avatar selection

**Firestore Structure:**
```
users/{userId}
  - email: String
  - createdAt: Timestamp
  - subscriptionTier: String
  - profiles: subcollection
      /{profileId}
        - name: String
        - avatar: String
        - isChild: Boolean
        - favorites: List<String>
        - watchHistory: List<WatchHistoryItem>
        - settings: Map
```

#### 5.2.5 Monetization & Subscriptions

**Responsibility:** Managing freemium model, in-app purchases, and ad display.

**Key Components:**
- RevenueCat SDK integration
- Entitlement checking
- Subscription tier logic
- AdMob integration (banner, interstitial)
- Purchase restoration
- Receipt validation (via RevenueCat)

**Feature Matrix:**
| Feature | Free | Premium |
|---------|------|---------|
| Playlists | 1 | Unlimited |
| Profiles | 1 | 5 |
| Favorites | 50 | Unlimited |
| EPG | Basic (current/next) | Full grid |
| Ads | Yes (banner + occasional interstitial) | No |
| Cloud Sync | No | Yes |
| Parental Controls | Basic | Advanced |

#### 5.2.6 Analytics & Logging

**Responsibility:** Understanding user behavior, app performance, and crash reporting.

**Key Components:**
- Firebase Analytics (screen views, events)
- Firebase Crashlytics (crash reporting)
- Custom event tracking (channel plays, errors, feature usage)
- Privacy-compliant data collection

**Key Events to Track:**
- `playlist_added`, `playlist_removed`
- `channel_played`, `vod_played`
- `subscription_started`, `subscription_cancelled`
- `epg_loaded`, `epg_error`
- `search_performed`
- `parental_pin_set`

---

## 6. Technology Stack Decisions

### 6.1 Client Stack

| Category | Choice | Package/Tool | Rationale |
|----------|--------|--------------|-----------|
| **Framework** | Flutter | flutter 3.x | Cross-platform, single codebase |
| **State Management** | BLoC or Riverpod | flutter_bloc / riverpod | Scalable, testable |
| **Navigation** | GoRouter | go_router | Declarative, deep linking |
| **Video Player** | media_kit | media_kit | Unified API, ExoPlayer + AVPlayer |
| **Local DB** | Drift (SQLite) | drift | Type-safe, efficient for EPG |
| **Key-Value** | Hive | hive | Fast, lightweight preferences |
| **Secure Storage** | flutter_secure_storage | flutter_secure_storage | Credentials encryption |
| **HTTP Client** | Dio | dio | Interceptors, error handling |
| **DI** | GetIt + Injectable | get_it, injectable | Clean dependency injection |
| **TV Navigation** | flutter_tv / custom | Custom focus system | D-pad support |

### 6.2 Backend Stack

| Category | Choice | Service | Rationale |
|----------|--------|---------|-----------|
| **Auth** | Firebase Auth | Firebase | Social logins, anonymous auth |
| **Database** | Firestore | Firebase | Real-time sync, offline support |
| **Functions** | Cloud Functions | Firebase | Server-side validation |
| **Push** | FCM | Firebase | Cross-platform notifications |
| **Config** | Remote Config | Firebase | Feature flags, A/B testing |
| **Analytics** | Firebase Analytics | Firebase | User behavior insights |
| **Crash Reporting** | Crashlytics | Firebase | Stability monitoring |
| **Storage** | Firebase Storage | Firebase | User avatars (minimal use) |

### 6.3 Monetization Stack

| Category | Choice | Service | Rationale |
|----------|--------|---------|-----------|
| **Subscriptions** | RevenueCat | RevenueCat | Cross-platform IAP abstraction |
| **Ads** | AdMob | Google AdMob | Largest ad network, Flutter support |

### 6.4 DevOps & CI/CD

| Category | Choice | Tool | Rationale |
|----------|--------|------|-----------|
| **CI/CD** | GitHub Actions | GitHub | Integrated, Flutter support |
| **Code Quality** | very_good_analysis | Dart | Strict linting rules |
| **Testing** | flutter_test + mockito | Flutter | Unit + widget + integration |
| **Distribution** | Fastlane | Fastlane | Automated store uploads |
| **Versioning** | Semantic Versioning | - | Clear version communication |

---

## 7. Monetization Strategy

### 7.1 Freemium Model Design

**Free Tier:**
- Single playlist support
- Single profile
- Basic EPG (now/next only)
- Limited favorites (50)
- Ads (non-intrusive banner ads, occasional interstitial on app open)
- Local-only data (no cloud sync)

**Premium Tier (One-time or Subscription):**
- Unlimited playlists
- Up to 5 profiles
- Full EPG grid view
- Unlimited favorites
- Ad-free experience
- Cloud sync across devices
- Priority support

### 7.2 Pricing Strategy Options

| Model | Price Point | Pros | Cons |
|-------|-------------|------|------|
| **One-time IAP** | $9.99-$14.99 | User preference, simple | One-time revenue |
| **Monthly Sub** | $2.99-$4.99/mo | Recurring revenue | Higher churn risk |
| **Yearly Sub** | $19.99-$29.99/yr | Better LTV | Larger upfront ask |
| **Hybrid** | Both options | User choice | Complexity |

**Recommendation:** Start with **yearly subscription ($24.99/yr)** with option to **unlock lifetime ($39.99)** for users who prefer one-time. This balances recurring revenue with user preference.

### 7.3 Ad Strategy

- **Banner ads:** Bottom of screen during channel browsing (not during playback)
- **Interstitial ads:** On app open (max 1 per session), never interrupting playback
- **Rewarded ads:** Optional, e.g., "Watch ad to unlock premium EPG for 24 hours"
- **No ads during video playback** (critical for user experience and retention)

### 7.4 Store Compliance Notes

- In-app purchases MUST use platform payment systems (Apple/Google)
- Subscription terms must be clearly displayed
- Auto-renewal terms must be explicit
- Restore purchases functionality required
- Price transparency in app and store listing

---

## 8. Risks and Open Questions

### 8.1 App Store / Play Store Policy Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **App rejected for IPTV association** | Medium | High | Clear disclaimers, no content references, "media player" positioning |
| **App removed after approval** | Low-Medium | Critical | Monitor policy changes, maintain compliance, have appeal process ready |
| **IAP policy violations** | Low | Medium | Use RevenueCat for compliance |
| **Ad policy violations** | Low | Medium | Follow AdMob guidelines strictly |

**Apple-Specific Concerns:**
- Apple scrutinizes IPTV apps more heavily
- Avoid any screenshots or marketing showing TV content
- Emphasize "local media" and "personal playlists" in description

**Google-Specific Concerns:**
- Google may flag apps associated with piracy keywords
- Avoid terms like "free TV", "free channels" in metadata
- Clear copyright policy required

### 8.2 Legal / Compliance Concerns

| Concern | Mitigation |
|---------|------------|
| **DMCA/Copyright claims** | Include clear ToS stating no content responsibility; respond to valid DMCA requests |
| **Illegal content association** | Explicit disclaimer; do not recommend or link to providers |
| **User data privacy** | GDPR/CCPA compliance; minimal data collection; privacy policy |
| **Regional availability** | Consider geo-restrictions for problematic regions if needed |

**Required Legal Documents:**
1. Terms of Service
2. Privacy Policy
3. DMCA/Copyright Policy
4. Disclaimer (in-app and store listing)

### 8.3 Technical Risks and Limitations

| Risk | Area | Mitigation |
|------|------|------------|
| **Flutter TV UX limitations** | Android TV | Custom focus system; dedicated TV layouts; extensive testing |
| **Tizen support gaps** | Samsung TV | Treat as Phase 3; conduct spike; fallback to native if needed |
| **Video player edge cases** | Playback | Use media_kit with FFmpeg fallback; test diverse streams |
| **EPG parsing performance** | Large EPG files | Incremental parsing; background processing; pagination |
| **Firebase cost at scale** | Backend | Monitor usage; implement caching; have Supabase as Plan B |
| **Stream DRM** | Playback | Many IPTV streams unencrypted; for DRM, platform-specific work needed |

### 8.4 Open Questions (Requiring Decisions)

1. **State Management:** BLoC vs Riverpod?
   - Recommendation: BLoC for larger team scalability; Riverpod for solo/small team simplicity

2. **Subscription Model:** Monthly vs Yearly vs Lifetime?
   - Recommendation: Start with Yearly + Lifetime option

3. **Multi-device Sync:** Required for free tier?
   - Recommendation: Premium-only to drive conversions

4. **Tizen Priority:** How important is Samsung TV support?
   - Recommendation: Defer to Phase 3, evaluate after mobile launch

5. **Catch-up TV:** Support from day one?
   - Recommendation: Phase 2 feature (depends on provider support)

6. **Recording/DVR:** In scope?
   - Recommendation: Out of scope (legal complexity, storage requirements)

7. **Chromecast Support:** Required?
   - Recommendation: Phase 2 feature

8. **AirPlay Support:** Required?
   - Recommendation: Phase 2 feature (iOS priority)

---

## 9. Appendices

### 9.1 Glossary

| Term | Definition |
|------|------------|
| **M3U/M3U8** | Playlist file format for multimedia streams |
| **Xtream Codes** | API standard for IPTV providers (panel API) |
| **EPG** | Electronic Program Guide (TV schedule data) |
| **XMLTV** | XML-based EPG data format |
| **VOD** | Video On Demand (movies/series) |
| **HLS** | HTTP Live Streaming protocol |
| **DASH** | Dynamic Adaptive Streaming over HTTP |
| **Catch-up** | Ability to watch past programs (time-shifted TV) |
| **10-foot UI** | TV interface designed for viewing from ~10 feet distance |
| **D-pad** | Directional pad (TV remote navigation) |

### 9.2 Reference Links

**Flutter Packages:**
- media_kit: https://pub.dev/packages/media_kit
- better_player: https://pub.dev/packages/better_player
- drift: https://pub.dev/packages/drift
- flutter_bloc: https://pub.dev/packages/flutter_bloc
- riverpod: https://pub.dev/packages/riverpod
- go_router: https://pub.dev/packages/go_router

**Backend Services:**
- Firebase: https://firebase.google.com/
- Supabase: https://supabase.com/
- RevenueCat: https://www.revenuecat.com/

**Flutter-Tizen:**
- Repository: https://github.com/flutter-tizen/flutter-tizen
- Limitations: https://github.com/flutter-tizen/flutter-tizen/wiki/Limitations

**Store Guidelines:**
- Google Play Policy: https://support.google.com/googleplay/android-developer/
- Apple App Store Guidelines: https://developer.apple.com/app-store/review/guidelines/

### 9.3 Sample Disclaimer Text

```
DISCLAIMER

Kylos IPTV Player is a media player application only. This app does not
provide, host, stream, or distribute any television channels, movies,
series, or other media content.

Users are solely responsible for the content they access through this
application. Users must ensure they have the legal right to access any
content they stream using their own IPTV service subscriptions or
personal media playlists.

Kylos IPTV Player has no affiliation with any IPTV service provider. We
do not endorse, promote, or encourage the streaming of copyrighted
content without proper authorization from the copyright holder.

By using this application, you agree to use it only for accessing legally
acquired content and accept full responsibility for your usage.
```

### 9.4 Phased Delivery Roadmap (Features Only)

**Phase 1 - MVP (Mobile):**
- User auth (email, Google, Apple)
- Single playlist support (M3U + Xtream)
- Live TV browsing and playback
- Basic VOD (movies, series)
- Basic EPG (now/next)
- Favorites
- Basic search
- Free tier with ads
- Premium tier (subscription)

**Phase 2 - Enhanced Mobile + TV:**
- Android TV / Fire TV support
- Multiple playlists
- Full EPG grid
- Multi-profile support
- Parental controls
- Watch history / continue watching
- Chromecast / AirPlay
- Catch-up TV

**Phase 3 - Platform Expansion:**
- Samsung Tizen (if viable)
- Apple TV
- Advanced search/filters
- Cloud recording (if legally feasible)
- Provider recommendations (curated, legal)

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Nov 2024 | Architecture Team | Initial architecture vision |

---

*This document serves as the foundational architecture vision. Detailed technical specifications, API designs, and implementation guides will follow in subsequent documents.*
