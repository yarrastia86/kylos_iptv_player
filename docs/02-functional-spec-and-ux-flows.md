# Kylos IPTV Player - Functional Specification & UX Flows

**Version:** 1.0
**Date:** November 2024
**Status:** Draft
**Related Documents:** `01-architecture-vision-iptv-player.md`

---

## Table of Contents

1. [Document Overview](#1-document-overview)
2. [User Personas](#2-user-personas)
3. [Onboarding & Setup](#3-onboarding--setup)
4. [Home & Navigation](#4-home--navigation)
5. [Live TV Experience](#5-live-tv-experience)
6. [VOD & Series Experience](#6-vod--series-experience)
7. [Playlist & Provider Management](#7-playlist--provider-management)
8. [Profiles, Favorites & Parental Control](#8-profiles-favorites--parental-control)
9. [Settings](#9-settings)
10. [Monetization UX](#10-monetization-ux)
11. [Error Handling & Edge Cases](#11-error-handling--edge-cases)
12. [Feature Phasing](#12-feature-phasing)
13. [Appendices](#13-appendices)

---

## 1. Document Overview

### 1.1 Purpose

This document defines the functional requirements and user experience flows for Kylos IPTV Player. It serves as the primary reference for:
- UI/UX design decisions
- Development implementation
- QA test case creation
- Stakeholder alignment

### 1.2 Scope

| In Scope | Out of Scope |
|----------|--------------|
| Mobile apps (Android/iOS) | Web application |
| TV apps (Android TV/Fire TV) | Desktop native apps |
| User-facing features | Backend admin panels |
| Freemium monetization | B2B/white-label features |

### 1.3 Terminology

| Term | Definition |
|------|------------|
| **Source/Playlist** | An IPTV source configured by the user (M3U URL or Xtream credentials) |
| **Channel** | A live TV stream from the user's IPTV provider |
| **VOD** | Video On Demand - movies and series content |
| **EPG** | Electronic Program Guide - TV schedule data |
| **Profile** | A user profile within an account (e.g., "Dad", "Kids") |

---

## 2. User Personas

### 2.1 Primary Personas

#### Persona A: "Tech-Savvy Cord Cutter" (Primary)
- **Demographics:** 25-45, comfortable with technology
- **Behavior:** Has existing IPTV subscription, wants quality player app
- **Goals:** Reliable playback, good EPG, cross-device sync
- **Pain Points:** Buggy apps, poor channel switching, complicated setup

#### Persona B: "Family User"
- **Demographics:** 30-50, manages household entertainment
- **Behavior:** Needs to set up for family members with different needs
- **Goals:** Easy profiles, parental controls, kid-friendly interface
- **Pain Points:** Kids accessing inappropriate content, complex UIs

#### Persona C: "Casual Viewer"
- **Demographics:** Any age, less tech-savvy
- **Behavior:** Just wants to watch TV, minimal configuration
- **Goals:** Simple experience, quick access to favorites
- **Pain Points:** Too many options, confusing navigation

#### Persona D: "TV-First User"
- **Demographics:** Any age, primarily uses TV device
- **Behavior:** Uses remote control, prefers lean-back experience
- **Goals:** Easy navigation with remote, large readable text
- **Pain Points:** Small touch-oriented UIs, focus navigation issues

---

## 3. Onboarding & Setup

### 3.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| ONB-01 | As a new user, I want to quickly understand what the app does so I can decide to continue | MVP |
| ONB-02 | As a new user, I want to read and accept the legal disclaimer so I understand my responsibilities | MVP |
| ONB-03 | As a new user, I want to add my first IPTV source so I can start watching | MVP |
| ONB-04 | As a new user, I want to optionally create an account so I can sync across devices | MVP |
| ONB-05 | As a new user, I want clear feedback if my playlist URL is invalid so I can fix it | MVP |
| ONB-06 | As an anonymous user, I want to upgrade to a registered account without losing my data | Phase 2 |

### 3.2 First Launch Flow

```
+------------------+     +------------------+     +------------------+
|   Splash Screen  | --> |  Welcome Screen  | --> |  Legal Consent   |
|   (2 seconds)    |     |  (App intro)     |     |  (ToS + Privacy) |
+------------------+     +------------------+     +------------------+
                                                          |
                                                          v
+------------------+     +------------------+     +------------------+
|   Home Screen    | <-- |  Loading Source  | <-- | Add First Source |
|   (Ready to use) |     |  (Parsing...)    |     |  (M3U/Xtream)    |
+------------------+     +------------------+     +------------------+
```

#### Step 1: Splash Screen
- **Duration:** 2 seconds (or until app initialization complete)
- **Content:** Kylos IPTV Player logo, brief tagline
- **Actions:** None (auto-advance)

#### Step 2: Welcome Screen
- **Content:**
  - App logo
  - Headline: "Welcome to Kylos IPTV Player"
  - Subheadline: "Your personal media player for live TV, movies, and series"
  - Key features list (3 bullet points max)
- **Actions:**
  - Primary button: "Get Started"
  - Secondary link: "Already have an account? Sign In"

#### Step 3: Legal Consent Screen
- **Content:**
  - Headline: "Before We Begin"
  - Disclaimer box (scrollable):
    ```
    Kylos IPTV Player is a media player application only.

    - We do NOT provide, host, or distribute any TV channels, movies, or media content
    - You must use your own legally acquired IPTV service or playlists
    - You are solely responsible for the content you access
    - Streaming copyrighted content without permission is prohibited
    ```
  - Checkbox 1: "I understand and accept the Terms of Service" (required)
  - Checkbox 2: "I have read the Privacy Policy" (required)
  - Links to full ToS and Privacy Policy documents
- **Actions:**
  - Primary button: "I Agree & Continue" (disabled until both checkboxes checked)
  - Back button (returns to Welcome)
- **Validation:**
  - Both checkboxes must be checked to proceed
  - Consent timestamp stored locally and in backend (if authenticated)

#### Step 4: Add First Source Screen
- **Content:**
  - Headline: "Add Your IPTV Source"
  - Subheadline: "Enter your playlist URL or provider credentials"
  - Tab selector or segmented control:
    - Tab 1: "M3U / M3U8 URL"
    - Tab 2: "Xtream Codes"
    - Tab 3: "File Upload" (Phase 2)

##### Tab 1: M3U URL Input
- **Fields:**
  - Playlist Name (optional, default: "My Playlist")
  - M3U URL (required, validated)
  - EPG URL (optional)
- **Validation:**
  - URL format validation (must start with http:// or https://)
  - Reachability test on submit
- **Error States:**
  - Invalid URL format: "Please enter a valid URL starting with http:// or https://"
  - Unreachable URL: "Could not connect to this URL. Please check the address and try again."
  - Invalid content: "The URL does not contain a valid M3U playlist."

##### Tab 2: Xtream Codes Input
- **Fields:**
  - Playlist Name (optional, default: "My Playlist")
  - Server URL (required) - with helper text: "e.g., http://provider.com:8080"
  - Username (required)
  - Password (required, obscured with show/hide toggle)
- **Validation:**
  - Server URL format validation
  - Authentication test on submit
- **Error States:**
  - Invalid credentials: "Authentication failed. Please check your username and password."
  - Server unreachable: "Could not connect to the server. Please check the URL."
  - Account expired: "Your provider account appears to be expired. Please contact your provider."

##### Tab 3: File Upload (Phase 2)
- **Fields:**
  - Playlist Name (optional)
  - File picker button
- **Supported formats:** .m3u, .m3u8

#### Step 5: Loading Source Screen
- **Content:**
  - Progress indicator (spinner or progress bar)
  - Status messages (sequential):
    1. "Connecting to server..."
    2. "Downloading playlist..."
    3. "Parsing channels..." (with count: "Found 1,234 channels")
    4. "Loading categories..."
    5. "Fetching EPG data..." (if EPG URL provided)
  - Cancel button
- **Duration:** Variable (typically 5-30 seconds depending on playlist size)
- **Success:** Auto-navigate to Home Screen
- **Failure:** Show error dialog with retry option

#### Step 6: Optional Account Creation (Post-Setup)
- **Trigger:** After first source added successfully, show non-blocking prompt
- **Content:**
  - Headline: "Create an Account?"
  - Benefits list:
    - Sync playlists across devices
    - Backup your favorites and settings
    - Access premium features
  - Sign-in options:
    - Continue with Google
    - Continue with Apple (iOS only)
    - Sign up with Email
    - "Skip for now" link
- **Behavior:**
  - If skipped, user remains anonymous (Firebase Anonymous Auth)
  - Anonymous data can be migrated when user later creates account

### 3.3 Returning User Flow

```
+------------------+     +------------------+
|   Splash Screen  | --> |   Home Screen    |
|   (Quick load)   |     |   (Last state)   |
+------------------+     +------------------+
         |
         | (if no valid source)
         v
+------------------+
| Add Source Modal |
+------------------+
```

- **Behavior:** If user has valid sources, go directly to Home
- **Edge Case:** If all sources are invalid/expired, prompt to add new source

### 3.4 Mobile vs TV Onboarding Differences

| Aspect | Mobile | TV |
|--------|--------|-----|
| Text input | On-screen keyboard | Remote-based keyboard or QR code linking |
| URL entry | Direct typing | Option to "Send from phone" via QR code |
| Navigation | Touch gestures | D-pad focus navigation |
| Legal consent | Scroll + checkboxes | Highlight + select with OK button |

#### TV-Specific: QR Code Linking (Phase 2)
- **Flow:**
  1. TV shows QR code with unique session ID
  2. User scans with phone
  3. Phone opens web page to enter credentials
  4. Credentials sent to TV via backend
  5. TV auto-proceeds with setup

---

## 4. Home & Navigation

### 4.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| NAV-01 | As a user, I want to quickly access Live TV, Movies, and Series from the home screen | MVP |
| NAV-02 | As a user, I want to see what I was watching recently so I can continue | MVP |
| NAV-03 | As a user, I want to access my favorites quickly | MVP |
| NAV-04 | As a user, I want to switch between profiles easily | Phase 2 |
| NAV-05 | As a TV user, I want to navigate entirely with my remote control | MVP |
| NAV-06 | As a user, I want to search across all content types | MVP |

### 4.2 Navigation Structure

#### 4.2.1 Mobile Navigation (Phone/Tablet)

**Primary Navigation:** Bottom navigation bar (5 items max)

```
+--------------------------------------------------+
|  [Logo]  Kylos IPTV Player        [Search] [Profile]
+--------------------------------------------------+
|                                                   |
|              CONTENT AREA                         |
|                                                   |
+--------------------------------------------------+
|  [Live TV]  [Movies]  [Series]  [Favorites]  [Settings]
+--------------------------------------------------+
```

**Navigation Items:**
1. **Live TV** (icon: TV) - Default landing tab
2. **Movies** (icon: Film)
3. **Series** (icon: Play list)
4. **Favorites** (icon: Heart)
5. **Settings** (icon: Gear)

**Top Bar Elements:**
- App logo (tappable, returns to home)
- Search icon (opens search overlay)
- Profile avatar (opens profile switcher)

#### 4.2.2 TV Navigation (Android TV / Fire TV)

**Primary Navigation:** Left-side rail (collapsible)

```
+--------+--------------------------------------------------+
|        |                                                   |
| [Logo] |              CONTENT AREA                         |
|        |                                                   |
| Live TV|   +-------+  +-------+  +-------+  +-------+     |
|        |   | Chan1 |  | Chan2 |  | Chan3 |  | Chan4 |     |
| Movies |   +-------+  +-------+  +-------+  +-------+     |
|        |                                                   |
| Series |   Continue Watching                              |
|        |   +-------+  +-------+  +-------+                |
| Favor. |   | Movie1|  | Ep 3  |  | Movie2|                |
|        |   +-------+  +-------+  +-------+                |
| Search |                                                   |
|        |                                                   |
| Settngs|                                                   |
|        |                                                   |
+--------+--------------------------------------------------+
```

**Focus Behavior:**
- D-pad LEFT from content area focuses the navigation rail
- D-pad RIGHT from rail enters content area
- Rail expands to show labels when focused, collapses to icons when not
- BACK button: If in content, focus rail; If on rail, show exit dialog

### 4.3 Home Screen Content

#### 4.3.1 Home Screen Layout (Mobile)

```
+--------------------------------------------------+
|  Hero Banner (optional, featured content)         |
+--------------------------------------------------+
|  Continue Watching                    [See All >]|
|  +------+ +------+ +------+ +------+             |
|  |      | |      | |      | |      |  -->        |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  Recently Watched Channels            [See All >]|
|  +------+ +------+ +------+ +------+             |
|  |      | |      | |      | |      |  -->        |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  Favorite Channels                    [See All >]|
|  +------+ +------+ +------+ +------+             |
|  |      | |      | |      | |      |  -->        |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  Popular Movies                       [See All >]|
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
```

#### 4.3.2 Content Rows

| Row | Content | Visibility |
|-----|---------|------------|
| Continue Watching | VOD items with progress > 5% and < 95% | If any exist |
| Recently Watched Channels | Last 10 channels viewed | If any exist |
| Favorite Channels | User's favorited channels | If any exist |
| Favorite Movies/Series | User's favorited VOD | If any exist |
| Popular in [Category] | Top channels by category | Always |

#### 4.3.3 Empty States

**No Sources Configured:**
```
+--------------------------------------------------+
|                     [Icon]                        |
|           No IPTV Source Added                    |
|                                                   |
|   Add your playlist URL or Xtream credentials    |
|   to start watching live TV and movies.          |
|                                                   |
|            [+ Add IPTV Source]                    |
+--------------------------------------------------+
```

**No Favorites:**
```
+--------------------------------------------------+
|                     [Heart Icon]                  |
|              No Favorites Yet                     |
|                                                   |
|   Tap the heart icon on any channel or movie    |
|   to add it to your favorites.                   |
|                                                   |
|            [Browse Live TV]                       |
+--------------------------------------------------+
```

### 4.4 Search Experience

#### 4.4.1 Search Flow

```
User taps Search --> Search Screen Opens --> User types query
       |                                            |
       v                                            v
[Recent Searches]                          [Live Results]
[Suggested]                                (debounced 300ms)
       |                                            |
       v                                            v
   User selects                            Results grouped by:
   recent search                           - Channels
                                           - Movies
                                           - Series
```

#### 4.4.2 Search Screen Layout

```
+--------------------------------------------------+
|  [<]  [____Search_channels,_movies,_series____]  |
+--------------------------------------------------+
|  Recent Searches                         [Clear] |
|  - Sports channels                               |
|  - Breaking Bad                                  |
|  - News                                          |
+--------------------------------------------------+
         |
         | (after typing)
         v
+--------------------------------------------------+
|  [<]  [____"news"_________________________] [X]  |
+--------------------------------------------------+
|  Channels (12)                        [See All >]|
|  +------+ +------+ +------+ +------+             |
|  | CNN  | | BBC  | | Fox  | | Sky  |             |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  Movies (3)                           [See All >]|
|  +------+ +------+ +------+                      |
|  | News | | News | | News |                      |
|  | Room | | of W | | Anch |                      |
|  +------+ +------+ +------+                      |
+--------------------------------------------------+
```

#### 4.4.3 Search Behavior

- **Debounce:** 300ms after last keystroke
- **Minimum query:** 2 characters
- **Scope:** Searches across:
  - Channel names
  - Movie titles
  - Series titles
  - Category names
- **Results limit:** 6 per category in preview, full list on "See All"

### 4.5 Profile Switcher

#### 4.5.1 Profile Switcher UI (Phase 2)

**Trigger:** Tap profile avatar in top bar

```
+--------------------------------------------------+
|  Who's Watching?                          [Edit] |
+--------------------------------------------------+
|                                                   |
|   +------+    +------+    +------+    +------+   |
|   |      |    |      |    |      |    |  +   |   |
|   | Dad  |    | Mom  |    | Kids |    | Add  |   |
|   +------+    +------+    +------+    +------+   |
|                                                   |
+--------------------------------------------------+
```

- **Behavior:** Selecting profile reloads app with that profile's preferences
- **Kids Profile:** Has visual indicator (e.g., colorful border, "Kids" badge)
- **Add Profile:** Opens profile creation flow (Premium feature)

---

## 5. Live TV Experience

### 5.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| LTV-01 | As a user, I want to browse channels by category so I can find what I want | MVP |
| LTV-02 | As a user, I want to search for channels by name | MVP |
| LTV-03 | As a user, I want to see what's currently playing on each channel | MVP |
| LTV-04 | As a user, I want to see a full TV guide with times and programs | MVP |
| LTV-05 | As a user, I want to quickly switch between channels while watching | MVP |
| LTV-06 | As a user, I want to add channels to my favorites | MVP |
| LTV-07 | As a user, I want to see channel logos for easy identification | MVP |
| LTV-08 | As a user, I want to change audio tracks if available | MVP |
| LTV-09 | As a user, I want to enable subtitles if available | MVP |
| LTV-10 | As a TV user, I want to use number keys to jump to channels | Phase 2 |

### 5.2 Channel List Screen

#### 5.2.1 Layout (Mobile)

```
+--------------------------------------------------+
|  [<] Live TV                    [Search] [Guide] |
+--------------------------------------------------+
|  Categories                                       |
|  [All] [Sports] [News] [Entertainment] [Movies] >|
+--------------------------------------------------+
|  +------------------------------------------+    |
|  | [Logo] CNN                               |    |
|  | News    |  Now: Breaking News Live       |    |
|  |         |  Next: Anderson Cooper 360     |    |
|  +------------------------------------------+    |
|  +------------------------------------------+    |
|  | [Logo] ESPN                         [*] |    |
|  | Sports  |  Now: NFL Live                 |    |
|  |         |  Next: SportsCenter            |    |
|  +------------------------------------------+    |
|  +------------------------------------------+    |
|  | [Logo] HBO                               |    |
|  | Movies  |  Now: The Batman (2022)        |    |
|  |         |  Next: House of the Dragon     |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
```

**Elements:**
- Category pills: Horizontally scrollable, "All" selected by default
- Channel cards: Show logo, name, category, current/next program (if EPG available)
- Favorite indicator: Filled star for favorited channels
- Tap action: Opens player with selected channel

#### 5.2.2 Layout (TV)

```
+--------+--------------------------------------------------+
|        |  Categories: [All] [Sports] [News] [Ent.] [Mov.]|
| Live TV|--------------------------------------------------|
|        |  +------+  +------+  +------+  +------+  +------+|
| Movies |  | CNN  |  | ESPN |  | HBO  |  | BBC  |  | FOX  ||
|        |  | News |  |Sports|  |Movies|  | News |  | News ||
| Series |  +------+  +------+  +------+  +------+  +------+|
|        |                                                   |
| Favor. |  +------+  +------+  +------+  +------+  +------+|
|        |  | NBC  |  | ABC  |  | CBS  |  | TNT  |  | TBS  ||
| Search |  | Ent. |  | Ent. |  | Ent. |  |Drama |  |Comedy||
|        |  +------+  +------+  +------+  +------+  +------+|
|Settings|                                                   |
+--------+--------------------------------------------------+
```

**Focus Behavior:**
- D-pad navigates between channel cards
- Category row is separately focusable above content
- Pressing OK/Select on focused channel starts playback

### 5.3 EPG / TV Guide

#### 5.3.1 EPG Availability

| Scenario | Behavior |
|----------|----------|
| EPG URL provided and valid | Full EPG functionality |
| Xtream Codes with EPG | Auto-fetched EPG |
| No EPG available | Show "Now/Next" from playlist if available, else hide EPG features |

#### 5.3.2 EPG Grid View

```
+--------------------------------------------------+
|  [<] TV Guide              [Today v] [Now] [>>]  |
+--------------------------------------------------+
|          | 8:00  | 8:30  | 9:00  | 9:30  | 10:00 |
+--------------------------------------------------+
| CNN      |  Morning News       | Breaking News   |
| [Logo]   |  [##############]   |                 |
+----------+---------------------+-----------------+
| ESPN     | SportsCenter  | NFL Live             |
| [Logo]   | [###]         | [##################] |
+----------+---------------+----------------------+
| HBO      |     The Batman (2022)                |
| [Logo]   |     [#########################]      |
+----------+--------------------------------------+
| BBC      | World News    | Documentary Hour    |
| [Logo]   | [########]    | [#####]             |
+----------+---------------+---------------------+
```

**Elements:**
- Time ruler: Horizontally scrollable, 30-minute increments
- Channel column: Fixed on left, vertically scrollable
- Program cells: Variable width based on duration
- Current time indicator: Vertical line showing "now"
- Program selection: Tap/focus to see details

**Actions:**
- Tap program: Show program details modal
- Tap channel logo: Start watching that channel
- "Now" button: Scroll to current time
- Date picker: Navigate to different days

#### 5.3.3 Now/Next View (Simplified EPG)

For quick viewing without full grid:

```
+--------------------------------------------------+
|  Now & Next                                       |
+--------------------------------------------------+
|  CNN                                              |
|  NOW:  Breaking News Live          8:00 - 10:00 |
|  NEXT: Anderson Cooper 360        10:00 - 11:00 |
+--------------------------------------------------+
|  ESPN                                             |
|  NOW:  NFL Live                    9:00 - 12:00 |
|  NEXT: SportsCenter               12:00 - 13:00 |
+--------------------------------------------------+
```

### 5.4 Channel Details Screen

**Trigger:** Long-press channel (mobile) or press Info button (TV)

```
+--------------------------------------------------+
|  [Logo]  CNN                           [*] [Play]|
+--------------------------------------------------+
|  Category: News                                   |
+--------------------------------------------------+
|  Now Playing                                      |
|  Breaking News Live                              |
|  8:00 AM - 10:00 AM                              |
|                                                   |
|  Coverage of today's top stories from around     |
|  the world with live reports from correspondents.|
+--------------------------------------------------+
|  Coming Up                                        |
|  +--------------------------------------------+  |
|  | 10:00 | Anderson Cooper 360               |  |
|  +--------------------------------------------+  |
|  | 11:00 | CNN Tonight                       |  |
|  +--------------------------------------------+  |
|  | 12:00 | The Lead with Jake Tapper         |  |
|  +--------------------------------------------+  |
+--------------------------------------------------+
```

### 5.5 Playback Experience

#### 5.5.1 Player UI (Mobile)

```
+--------------------------------------------------+
|  [<]  CNN - Breaking News Live      [Cast] [*]   |
|                                                   |
|                                                   |
|                                                   |
|              VIDEO CONTENT                        |
|                                                   |
|                                                   |
|                                                   |
+--------------------------------------------------+
|  [<<]  [Play/Pause]  [>>]           [CC] [Settings]
|  < Previous         Next >                        |
+--------------------------------------------------+
|  Channel List (collapsed)                    [^] |
+--------------------------------------------------+
```

**Controls:**
- Back button: Exit player
- Favorite button: Toggle favorite
- Cast button: Chromecast/AirPlay (Phase 2)
- Previous/Next: Channel zapping
- CC: Subtitle selection
- Settings: Quality, audio track

**Gestures (Mobile):**
- Tap: Show/hide controls
- Swipe left/right: Previous/next channel
- Swipe up: Show channel list overlay
- Double-tap sides: Seek (for VOD only)

#### 5.5.2 Player UI (TV)

```
+--------------------------------------------------+
|                                                   |
|                 VIDEO CONTENT                     |
|                                                   |
+--------------------------------------------------+
|  CNN - Breaking News Live                         |
|  Now: Breaking News | Next: Anderson Cooper 360  |
|--------------------------------------------------|
|  [<<] [||] [>>]           [Audio] [Subs] [Quality]
+--------------------------------------------------+
```

**Remote Controls:**
| Button | Action |
|--------|--------|
| OK/Select | Play/Pause |
| Up | Show info overlay |
| Down | Show channel list |
| Left | Previous channel |
| Right | Next channel |
| Back | Exit player |
| Number keys | Jump to channel number (Phase 2) |

#### 5.5.3 Channel List Overlay

```
+--------------------------------------------------+
|                                                   |
|              VIDEO (dimmed)                       |
|                                                   |
+--------+-----------------------------------------+
|        |  Channels                               |
|   All  |  +----------------------------------+  |
|        |  | CNN           Now: Breaking News |  |
| Sports |  +----------------------------------+  |
|        |  | ESPN       Now: NFL Live        *|  |
|  News  |  +----------------------------------+  |
|        |  | HBO          Now: The Batman     |  |
| Movies |  +----------------------------------+  |
+--------+-----------------------------------------+
```

#### 5.5.4 Quality Selection

**Trigger:** Settings icon or dedicated Quality button

```
+---------------------------+
|  Video Quality            |
+---------------------------+
|  ( ) Auto (Recommended)   |
|  ( ) 1080p HD             |
|  (o) 720p HD              |
|  ( ) 480p SD              |
|  ( ) 360p                 |
+---------------------------+
```

**Note:** Options depend on what the stream/provider supports.

#### 5.5.5 Audio & Subtitle Selection

```
+---------------------------+
|  Audio Track              |
+---------------------------+
|  (o) English              |
|  ( ) Spanish              |
|  ( ) French               |
+---------------------------+

+---------------------------+
|  Subtitles                |
+---------------------------+
|  (o) Off                  |
|  ( ) English              |
|  ( ) Spanish [CC]         |
+---------------------------+
```

### 5.6 Channel Zapping Behavior

**Zap Animation (Mobile):**
1. User swipes left/right or taps next/previous
2. Current video freezes briefly
3. Channel name overlay appears
4. New channel starts loading
5. Overlay fades after 2 seconds

**Zap Animation (TV):**
1. User presses left/right on remote
2. Info bar shows at bottom: "CNN -> ESPN"
3. Brief loading indicator
4. New channel plays
5. Info bar auto-hides after 3 seconds

**Performance Target:** Channel switch < 2 seconds

---

## 6. VOD & Series Experience

### 6.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| VOD-01 | As a user, I want to browse movies by category | MVP |
| VOD-02 | As a user, I want to search for movies by title | MVP |
| VOD-03 | As a user, I want to see movie details before watching | MVP |
| VOD-04 | As a user, I want to continue watching a movie where I left off | MVP |
| VOD-05 | As a user, I want to browse TV series and their episodes | MVP |
| VOD-06 | As a user, I want to auto-play the next episode | Phase 2 |
| VOD-07 | As a user, I want to see related/similar content | Phase 2 |
| VOD-08 | As a user, I want to filter movies by year, rating, etc. | Phase 2 |

### 6.2 Movies Screen

#### 6.2.1 Layout

```
+--------------------------------------------------+
|  [<] Movies                          [Search] [Filter]
+--------------------------------------------------+
|  Categories                                       |
|  [All] [Action] [Comedy] [Drama] [Horror] [Sci-Fi]>
+--------------------------------------------------+
|  +------+ +------+ +------+ +------+ +------+    |
|  |      | |      | |      | |      | |      |    |
|  |      | |      | |      | |      | |      |    |
|  |      | |      | |      | |      | |      |    |
|  +------+ +------+ +------+ +------+ +------+    |
|  Title 1  Title 2  Title 3  Title 4  Title 5     |
|  2023     2022     2023     2021     2023        |
+--------------------------------------------------+
|  +------+ +------+ +------+ +------+ +------+    |
   ...
```

**Movie Card Elements:**
- Poster image (2:3 ratio)
- Title (truncated if long)
- Year
- Progress bar (if partially watched)
- HD/4K badge (if applicable)

### 6.3 Movie Details Screen

```
+--------------------------------------------------+
|  [<]                              [*] [Share]    |
+--------------------------------------------------+
|  +----------+  The Batman                        |
|  |          |  2022 | Action, Drama | 2h 56m    |
|  | POSTER   |  HD                                |
|  |          |  Rating: 8.1/10                    |
|  +----------+                                    |
|                                                   |
|  [   Play   ]  [   Trailer   ]                   |
|                                                   |
+--------------------------------------------------+
|  Overview                                         |
|  When a sadistic serial killer begins murdering  |
|  key political figures in Gotham, Batman is      |
|  forced to investigate the city's hidden...      |
|  [Read more]                                      |
+--------------------------------------------------+
|  Cast                                             |
|  Robert Pattinson, Zoe Kravitz, Paul Dano        |
+--------------------------------------------------+
|  Director                                         |
|  Matt Reeves                                      |
+--------------------------------------------------+
|  You May Also Like                    [See All >]|
|  +------+ +------+ +------+ +------+             |
```

**Actions:**
- Play: Start movie (or resume if progress exists)
- Trailer: Play trailer if available
- Favorite: Add to favorites
- Share: Share movie info (Phase 2)

### 6.4 Series Screen

#### 6.4.1 Series List Layout

Similar to Movies, but with:
- Episode count badge
- "New Episodes" badge if applicable

#### 6.4.2 Series Details Screen

```
+--------------------------------------------------+
|  [<]                              [*] [Share]    |
+--------------------------------------------------+
|  +----------+  Breaking Bad                      |
|  |          |  2008-2013 | Drama, Crime          |
|  | POSTER   |  5 Seasons | 62 Episodes           |
|  |          |  Rating: 9.5/10                    |
|  +----------+                                    |
|                                                   |
|  [   Play S1:E1   ]  [   Resume S3:E5   ]        |
|                                                   |
+--------------------------------------------------+
|  Overview                                         |
|  A high school chemistry teacher diagnosed with  |
|  terminal lung cancer turns to manufacturing...  |
+--------------------------------------------------+
|  Seasons                                          |
|  [Season 1] [Season 2] [Season 3*] [S4] [S5]    |
+--------------------------------------------------+
|  Season 3 Episodes                               |
|  +------------------------------------------+    |
|  | E1: No Mas                      | 47m   |    |
|  | Season premiere. Walt and Jesse...      |    |
|  +------------------------------------------+    |
|  | E2: Caballo Sin Nombre  [====--]| 47m   |    |
|  | Skyler demands that Walt move out...    |    |
|  +------------------------------------------+    |
|  | E3: I.F.T.                      | 47m   |    |
|  | Walt returns home...                    |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
```

**Elements:**
- Season selector: Tabs or dropdown
- Episode list: Title, duration, description
- Progress indicator: Show watching progress per episode
- Current episode highlight: Visual indicator for "Resume" episode

### 6.5 VOD Playback

#### 6.5.1 Player UI Differences from Live TV

| Feature | Live TV | VOD |
|---------|---------|-----|
| Seek bar | No | Yes |
| Rewind/Forward | No | Yes (10s increments) |
| Playback speed | No | Yes (0.5x - 2x) |
| Chapter markers | No | If available |
| Resume prompt | No | Yes |

#### 6.5.2 VOD Player Controls

```
+--------------------------------------------------+
|  [<]  The Batman                    [Cast] [*]   |
|                                                   |
|                                                   |
|                VIDEO CONTENT                      |
|                                                   |
|                                                   |
+--------------------------------------------------+
|  1:23:45 [========|-------------------] 2:56:00  |
|  [-10s] [Play/Pause] [+10s]     [CC] [Settings] |
+--------------------------------------------------+
```

**Gestures (Mobile):**
- Double-tap left: Rewind 10 seconds
- Double-tap right: Forward 10 seconds
- Pinch: Zoom/aspect ratio
- Swipe down: Exit player

#### 6.5.3 Resume Playback Prompt

**Trigger:** Opening a movie/episode with existing progress

```
+--------------------------------------------------+
|                                                   |
|   Resume "The Batman"?                           |
|                                                   |
|   You stopped at 1:23:45                         |
|                                                   |
|   [Resume]          [Start Over]                 |
|                                                   |
+--------------------------------------------------+
```

#### 6.5.4 Next Episode UI (Phase 2)

**Trigger:** 30 seconds before end of episode

```
+--------------------------------------------------+
|                                                   |
|              VIDEO CONTENT                        |
|                                                   |
+--------------------------------------------------+
|  Up Next: S3:E6 - Sunset                         |
|  Starting in 15 seconds...                       |
|  [Play Now]                      [Cancel]        |
+--------------------------------------------------+
```

### 6.6 Continue Watching

#### 6.6.1 Continue Watching Row

```
+--------------------------------------------------+
|  Continue Watching                    [See All >]|
+--------------------------------------------------+
|  +------+    +------+    +------+                |
|  |      |    |      |    |      |                |
|  |      |    |      |    |      |                |
|  |  75% |    |  30% |    |  50% |                |
|  +------+    +------+    +------+                |
|  The Batman  Breaking    Inception              |
|  1:23 left   Bad S3:E5   45m left               |
+--------------------------------------------------+
```

**Logic:**
- Include items with 5% < progress < 95%
- Sort by last watched (most recent first)
- Show remaining time or progress percentage

---

## 7. Playlist & Provider Management

### 7.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| PL-01 | As a user, I want to add multiple IPTV sources | Premium |
| PL-02 | As a user, I want to edit my existing sources | MVP |
| PL-03 | As a user, I want to delete sources I no longer use | MVP |
| PL-04 | As a user, I want to refresh my playlist to get new channels | MVP |
| PL-05 | As a user, I want to see when my playlist was last updated | MVP |
| PL-06 | As a user, I want to switch between sources if I have multiple | Premium |
| PL-07 | As a user, I want my credentials stored securely | MVP |
| PL-08 | As a Premium user, I want to merge channels from multiple sources | Nice-to-have |

### 7.2 Playlist Management Screen

**Access:** Settings > Manage Playlists

```
+--------------------------------------------------+
|  [<] Manage Playlists                            |
+--------------------------------------------------+
|  +------------------------------------------+    |
|  | My IPTV Provider                    [o]  |    |
|  | Xtream Codes                             |    |
|  | 1,234 channels | Last sync: 2h ago       |    |
|  | [Edit] [Refresh] [Delete]                |    |
|  +------------------------------------------+    |
|                                                   |
|  +------------------------------------------+    |
|  | Backup Playlist               [INACTIVE] |    |
|  | M3U URL                             [ ]  |    |
|  | 567 channels | Last sync: 1d ago         |    |
|  | [Edit] [Refresh] [Delete] [Activate]     |    |
|  +------------------------------------------+    |
|                                                   |
|  [+ Add New Playlist]                            |
|                                                   |
|  Free plan: 1 playlist limit                     |
|  [Upgrade to Premium for unlimited playlists]   |
+--------------------------------------------------+
```

**Elements:**
- Active playlist indicator: Radio button or checkmark
- Playlist type badge: "Xtream Codes" or "M3U"
- Channel count
- Last sync timestamp
- Action buttons: Edit, Refresh, Delete, Activate

### 7.3 Add/Edit Playlist Flow

#### 7.3.1 Add New Playlist (Premium Check)

```
Free user taps "Add New Playlist"
         |
         v
+--------------------------------------------------+
|  Upgrade to Premium                              |
|                                                   |
|  Free accounts are limited to 1 playlist.        |
|                                                   |
|  Upgrade to Premium to add unlimited playlists   |
|  and unlock these features:                      |
|  - Multiple IPTV sources                         |
|  - Cloud sync across devices                     |
|  - Multiple profiles                             |
|  - Ad-free experience                            |
|                                                   |
|  [Upgrade Now - $24.99/year]                     |
|  [Maybe Later]                                    |
+--------------------------------------------------+
```

#### 7.3.2 Edit Playlist Screen

```
+--------------------------------------------------+
|  [<] Edit Playlist                       [Save]  |
+--------------------------------------------------+
|  Playlist Name                                    |
|  [My IPTV Provider_________________________]     |
+--------------------------------------------------+
|  Type: Xtream Codes                              |
+--------------------------------------------------+
|  Server URL                                       |
|  [http://myiptv.com:8080__________________]     |
+--------------------------------------------------+
|  Username                                         |
|  [john_doe________________________________]     |
+--------------------------------------------------+
|  Password                                         |
|  [********____________________________] [Show]   |
+--------------------------------------------------+
|  EPG URL (Optional)                              |
|  [http://epg.example.com/guide.xml_______]     |
+--------------------------------------------------+
|                                                   |
|  [Test Connection]                               |
|                                                   |
|  Last tested: Connection successful              |
+--------------------------------------------------+
```

### 7.4 Playlist Refresh

**Trigger:** Manual refresh button or auto-refresh on app open (if > 24h since last)

```
Refresh initiated
        |
        v
+--------------------------------------------------+
|  Refreshing Playlist...                          |
|  [================>                        ] 45%|
|  Downloading channel list...                     |
|  [Cancel]                                        |
+--------------------------------------------------+
        |
        v (on complete)
+--------------------------------------------------+
|  Playlist Refreshed                              |
|                                                   |
|  - 1,256 channels (+22 new)                     |
|  - 145 movies                                    |
|  - 89 series                                     |
|                                                   |
|  [OK]                                            |
+--------------------------------------------------+
```

### 7.5 Credential Security

**Storage Strategy:**
- Credentials encrypted using platform secure storage
  - Android: EncryptedSharedPreferences
  - iOS: Keychain
- Never stored in plain text
- Never transmitted except to the IPTV provider server
- Option to require biometric/PIN to view credentials

### 7.6 Multiple Source Handling (Premium)

#### 7.6.1 Source Switching

```
+--------------------------------------------------+
|  Select Active Source                            |
+--------------------------------------------------+
|                                                   |
|  (o) My IPTV Provider                           |
|      1,234 channels                              |
|                                                   |
|  ( ) Backup Playlist                             |
|      567 channels                                |
|                                                   |
|  ( ) Sports Package                              |
|      89 channels                                 |
|                                                   |
+--------------------------------------------------+
|  [Switch Source]                                 |
+--------------------------------------------------+
```

#### 7.6.2 Merged View (Nice-to-have)

```
+--------------------------------------------------+
|  Source View Mode                                |
+--------------------------------------------------+
|                                                   |
|  (o) Single Source                               |
|      Show channels from active source only       |
|                                                   |
|  ( ) Merged View                                 |
|      Combine channels from all sources           |
|      (Duplicates will be removed)               |
|                                                   |
+--------------------------------------------------+
```

---

## 8. Profiles, Favorites & Parental Control

### 8.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| PRF-01 | As a user, I want to create profiles for family members | Phase 2 |
| PRF-02 | As a user, I want each profile to have its own favorites | Phase 2 |
| PRF-03 | As a parent, I want to lock certain channels/categories with a PIN | Phase 2 |
| PRF-04 | As a parent, I want a Kids profile with restricted content | Phase 2 |
| FAV-01 | As a user, I want to add channels to favorites | MVP |
| FAV-02 | As a user, I want to add movies/series to favorites | MVP |
| FAV-03 | As a user, I want to quickly access all my favorites | MVP |
| FAV-04 | As a user, I want to remove items from favorites | MVP |

### 8.2 Profile Management (Phase 2)

#### 8.2.1 Profile List Screen

**Access:** Settings > Manage Profiles

```
+--------------------------------------------------+
|  [<] Manage Profiles                             |
+--------------------------------------------------+
|                                                   |
|   +------+    +------+    +------+    +------+   |
|   |      |    |      |    |      |    |  +   |   |
|   | Dad  |    | Mom  |    | Kids |    | Add  |   |
|   | Edit |    | Edit |    | Edit |    |      |   |
|   +------+    +------+    +------+    +------+   |
|                                                   |
|  Free plan: 1 profile limit                      |
|  [Upgrade for up to 5 profiles]                  |
+--------------------------------------------------+
```

#### 8.2.2 Create/Edit Profile Screen

```
+--------------------------------------------------+
|  [<] Create Profile                      [Save]  |
+--------------------------------------------------+
|                 +------+                          |
|                 |      |                          |
|                 |Avatar|                          |
|                 +------+                          |
|                 [Change]                          |
+--------------------------------------------------+
|  Profile Name                                     |
|  [________________________________]              |
+--------------------------------------------------+
|  Profile Type                                     |
|  (o) Standard                                    |
|  ( ) Kids (Restricted content)                   |
+--------------------------------------------------+
|  [ ] Require PIN to switch to this profile       |
+--------------------------------------------------+
```

#### 8.2.3 Kids Profile Restrictions

When "Kids" type is selected:
- Only shows channels/categories marked as "kid-friendly"
- Hides adult/mature content automatically
- Simplified UI with larger elements
- Colorful, playful design variant
- Cannot access Settings or Profile management

### 8.3 Favorites

#### 8.3.1 Adding to Favorites

**Channels:**
- Tap star/heart icon on channel card
- Long-press channel > "Add to Favorites"
- In player: tap favorite icon in controls

**Movies/Series:**
- Tap star/heart on poster card
- On details screen: tap favorite button
- In player: tap favorite icon

#### 8.3.2 Favorites Screen

```
+--------------------------------------------------+
|  [<] Favorites                         [Edit]    |
+--------------------------------------------------+
|  Channels (12)                                   |
|  +------+ +------+ +------+ +------+             |
|  | CNN  | | ESPN | | HBO  | | BBC  |   -->      |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  Movies (5)                                      |
|  +------+ +------+ +------+ +------+             |
|  |      | |      | |      | |      |   -->      |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  Series (3)                                      |
|  +------+ +------+ +------+                      |
|  |      | |      | |      |                      |
|  +------+ +------+ +------+                      |
+--------------------------------------------------+
```

#### 8.3.3 Edit Favorites Mode

**Trigger:** "Edit" button or long-press any item

```
+--------------------------------------------------+
|  [Cancel] Favorites                      [Done]  |
+--------------------------------------------------+
|  Channels (12)                       [Select All]|
|  +------+ +------+ +------+ +------+             |
|  |  X   | |  X   | |      | |      |             |
|  | CNN  | | ESPN | | HBO  | | BBC  |             |
|  +------+ +------+ +------+ +------+             |
+--------------------------------------------------+
|  [Remove Selected (2)]                           |
+--------------------------------------------------+
```

### 8.4 Parental Controls (Phase 2)

#### 8.4.1 Parental Control Settings

**Access:** Settings > Parental Controls

```
+--------------------------------------------------+
|  [<] Parental Controls                           |
+--------------------------------------------------+
|  Parental PIN                                     |
|  [Set PIN] or [Change PIN]                       |
+--------------------------------------------------+
|  Locked Categories                               |
|  Lock entire categories behind PIN               |
|  [ ] Adult                                       |
|  [ ] XXX                                         |
|  [ ] Pay-Per-View                                |
|  [Manage Categories...]                          |
+--------------------------------------------------+
|  Locked Channels                                 |
|  Lock specific channels behind PIN               |
|  3 channels locked                               |
|  [Manage Channels...]                            |
+--------------------------------------------------+
|  Kids Mode                                        |
|  [ ] Enable Kids Mode profile                    |
|  Creates a restricted profile for children       |
+--------------------------------------------------+
```

#### 8.4.2 PIN Entry Flow

**Trigger:** Attempting to access locked content

```
+--------------------------------------------------+
|                                                   |
|   Enter Parental PIN                             |
|                                                   |
|   This content is locked.                        |
|   Enter your 4-digit PIN to continue.            |
|                                                   |
|         [ ] [ ] [ ] [ ]                          |
|                                                   |
|   [Cancel]                                        |
|                                                   |
|   Forgot PIN? Reset in Settings                  |
|                                                   |
+--------------------------------------------------+
```

**PIN Behavior:**
- 4-digit numeric PIN
- 3 failed attempts = 30 second lockout
- PIN can be reset via account email verification

#### 8.4.3 Lock Channel Flow

```
Long-press channel
        |
        v
+--------------------------------------------------+
|  CNN                                              |
+--------------------------------------------------+
|  [*] Add to Favorites                            |
|  [Lock icon] Lock Channel                        |
|  [Hide icon] Hide Channel                        |
+--------------------------------------------------+
        |
        v (select "Lock Channel")
+--------------------------------------------------+
|  Lock "CNN"?                                     |
|                                                   |
|  This channel will require your Parental PIN     |
|  to access.                                       |
|                                                   |
|  [Cancel]                     [Lock]             |
+--------------------------------------------------+
```

---

## 9. Settings

### 9.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| SET-01 | As a user, I want to configure video playback options | MVP |
| SET-02 | As a user, I want to change the app language | MVP |
| SET-03 | As a user, I want to set my preferred audio language | MVP |
| SET-04 | As a user, I want to backup my settings to the cloud | Premium |
| SET-05 | As a user, I want to clear cache to free up space | MVP |
| SET-06 | As a user, I want to manually refresh EPG data | MVP |
| SET-07 | As a user, I want to see app version and support info | MVP |

### 9.2 Settings Screen Structure

```
+--------------------------------------------------+
|  [<] Settings                                    |
+--------------------------------------------------+
|  ACCOUNT                                          |
|  +------------------------------------------+    |
|  | Profile                              [>] |    |
|  | john@email.com                           |    |
|  +------------------------------------------+    |
|  | Subscription                         [>] |    |
|  | Premium (expires Dec 2025)               |    |
|  +------------------------------------------+    |
|  | Manage Profiles                      [>] |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|  PLAYLISTS                                        |
|  +------------------------------------------+    |
|  | Manage Playlists                     [>] |    |
|  | 2 playlists configured                   |    |
|  +------------------------------------------+    |
|  | Refresh All Playlists                [>] |    |
|  +------------------------------------------+    |
|  | EPG Settings                         [>] |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|  PLAYBACK                                         |
|  +------------------------------------------+    |
|  | Video Quality                        [>] |    |
|  | Auto                                     |    |
|  +------------------------------------------+    |
|  | Buffer Size                          [>] |    |
|  | Medium (Recommended)                     |    |
|  +------------------------------------------+    |
|  | Hardware Decoding                   [ON] |    |
|  +------------------------------------------+    |
|  | Default Audio Language               [>] |    |
|  | English                                  |    |
|  +------------------------------------------+    |
|  | Default Subtitle Language            [>] |    |
|  | Off                                      |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|  APPEARANCE                                       |
|  +------------------------------------------+    |
|  | App Language                         [>] |    |
|  | English                                  |    |
|  +------------------------------------------+    |
|  | Theme                                [>] |    |
|  | System Default                           |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|  PARENTAL CONTROLS                               |
|  +------------------------------------------+    |
|  | Parental Controls                    [>] |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|  DATA & STORAGE                                  |
|  +------------------------------------------+    |
|  | Backup & Sync                        [>] |    |
|  | Last backup: Today, 3:45 PM              |    |
|  +------------------------------------------+    |
|  | Clear Cache                          [>] |    |
|  | 245 MB used                              |    |
|  +------------------------------------------+    |
|  | Clear Watch History                  [>] |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|  ABOUT                                            |
|  +------------------------------------------+    |
|  | Version                                  |    |
|  | 1.0.0 (Build 100)                        |    |
|  +------------------------------------------+    |
|  | Help & Support                       [>] |    |
|  +------------------------------------------+    |
|  | Terms of Service                     [>] |    |
|  +------------------------------------------+    |
|  | Privacy Policy                       [>] |    |
|  +------------------------------------------+    |
|  | Licenses                             [>] |    |
|  +------------------------------------------+    |
+--------------------------------------------------+
|                                                   |
|  [Sign Out]                                      |
|                                                   |
+--------------------------------------------------+
```

### 9.3 Video Quality Settings

```
+--------------------------------------------------+
|  [<] Video Quality                               |
+--------------------------------------------------+
|  Default Quality                                  |
|  (o) Auto (Recommended)                          |
|      Adjusts based on network speed              |
|  ( ) Always High (1080p)                         |
|      Uses more data                              |
|  ( ) Balanced (720p)                             |
|      Good quality, moderate data                 |
|  ( ) Data Saver (480p)                           |
|      Lower quality, saves data                   |
+--------------------------------------------------+
|  Mobile Data Warning                             |
|  [ ] Warn before streaming on mobile data        |
+--------------------------------------------------+
```

### 9.4 Buffer Size Settings

```
+--------------------------------------------------+
|  [<] Buffer Size                                 |
+--------------------------------------------------+
|  ( ) Small (1 second)                            |
|      Faster channel switching                    |
|      May cause more buffering                    |
|                                                   |
|  (o) Medium (3 seconds) - Recommended            |
|      Balanced performance                        |
|                                                   |
|  ( ) Large (10 seconds)                          |
|      Fewer interruptions                         |
|      Slower channel switching                    |
+--------------------------------------------------+
```

### 9.5 EPG Settings

```
+--------------------------------------------------+
|  [<] EPG Settings                                |
+--------------------------------------------------+
|  Auto-refresh EPG                                |
|  [ON]                                            |
|  Refresh every: [12 hours v]                     |
+--------------------------------------------------+
|  Last EPG Update                                  |
|  Today, 6:00 AM                                  |
|  12,456 programs loaded                          |
|                                                   |
|  [Refresh Now]                                   |
+--------------------------------------------------+
|  EPG Time Zone                                    |
|  [Auto-detect v]                                 |
+--------------------------------------------------+
|  Show EPG in Channel List                        |
|  [ON]                                            |
|  Display Now/Next program info                   |
+--------------------------------------------------+
```

### 9.6 Backup & Sync (Premium)

```
+--------------------------------------------------+
|  [<] Backup & Sync                               |
+--------------------------------------------------+
|  Cloud Sync                               [ON]   |
|  Sync favorites, history, and settings           |
|  across all your devices                         |
+--------------------------------------------------+
|  Last Sync                                        |
|  Today, 3:45 PM                                  |
|  [Sync Now]                                      |
+--------------------------------------------------+
|  What's synced:                                   |
|  [x] Favorites                                   |
|  [x] Watch history                               |
|  [x] Playlist configurations                     |
|  [x] App settings                                |
|  [ ] Parental control settings                   |
+--------------------------------------------------+
|                                                   |
|  [Export Data]     [Import Data]                 |
|                                                   |
+--------------------------------------------------+
```

### 9.7 Clear Cache Confirmation

```
+--------------------------------------------------+
|  Clear Cache?                                    |
|                                                   |
|  This will delete:                               |
|  - Cached channel logos (120 MB)                 |
|  - Cached EPG data (85 MB)                       |
|  - Cached poster images (40 MB)                  |
|                                                   |
|  Total: 245 MB                                   |
|                                                   |
|  Your favorites, history, and settings           |
|  will NOT be affected.                           |
|                                                   |
|  [Cancel]                     [Clear Cache]      |
+--------------------------------------------------+
```

---

## 10. Monetization UX

### 10.1 User Stories

| ID | Story | Priority |
|----|-------|----------|
| MON-01 | As a free user, I want to understand what features are free vs paid | MVP |
| MON-02 | As a free user, I want to try the app before paying | MVP |
| MON-03 | As a user, I want to easily upgrade to Premium | MVP |
| MON-04 | As a paying user, I want to restore my purchase on a new device | MVP |
| MON-05 | As a user, I want to understand ad behavior in the free tier | MVP |
| MON-06 | As a subscriber, I want to manage my subscription | MVP |

### 10.2 Feature Tiers

| Feature | Free | Premium |
|---------|------|---------|
| Playlists | 1 | Unlimited |
| Profiles | 1 | 5 |
| Favorites | 50 channels, 20 VOD | Unlimited |
| EPG | Now/Next only | Full grid view |
| Cloud Sync | No | Yes |
| Parental Controls | Basic (lock categories) | Advanced (individual channels) |
| Ads | Yes | No |
| Support | Community | Priority email |

### 10.3 Premium Value Proposition Screen

**Access:** Settings > Subscription or any Premium feature trigger

```
+--------------------------------------------------+
|  [X]                                              |
+--------------------------------------------------+
|                                                   |
|        Upgrade to Kylos Premium                  |
|                                                   |
+--------------------------------------------------+
|                                                   |
|   [Icon] Unlimited Playlists                     |
|          Add as many IPTV sources as you need    |
|                                                   |
|   [Icon] Full EPG Grid                           |
|          See the complete TV guide               |
|                                                   |
|   [Icon] Multi-Device Sync                       |
|          Your favorites everywhere               |
|                                                   |
|   [Icon] 5 Profiles                              |
|          One for each family member              |
|                                                   |
|   [Icon] Ad-Free Experience                      |
|          No interruptions, ever                  |
|                                                   |
+--------------------------------------------------+
|                                                   |
|  +------------------------------------------+    |
|  |  BEST VALUE                              |    |
|  |  Annual - $24.99/year                    |    |
|  |  Save 58% vs monthly                     |    |
|  +------------------------------------------+    |
|                                                   |
|  +------------------------------------------+    |
|  |  Monthly - $4.99/month                   |    |
|  +------------------------------------------+    |
|                                                   |
|  +------------------------------------------+    |
|  |  Lifetime - $39.99 one-time              |    |
|  |  Pay once, own forever                   |    |
|  +------------------------------------------+    |
|                                                   |
+--------------------------------------------------+
|  [Continue]                                      |
|                                                   |
|  Already subscribed? [Restore Purchases]         |
+--------------------------------------------------+
|  Cancel anytime. Terms apply.                    |
+--------------------------------------------------+
```

### 10.4 Paywall Triggers

#### 10.4.1 Adding Second Playlist (Free User)

```
User taps "Add New Playlist"
          |
          v
+--------------------------------------------------+
|  Multiple Playlists - Premium Feature            |
|                                                   |
|  Free accounts can have 1 playlist.              |
|  Upgrade to Premium to add more.                 |
|                                                   |
|  [Upgrade to Premium]                            |
|  [Maybe Later]                                    |
+--------------------------------------------------+
```

#### 10.4.2 Accessing Full EPG Grid (Free User)

```
User taps "TV Guide" or EPG button
          |
          v
+--------------------------------------------------+
|  Full TV Guide - Premium Feature                 |
|                                                   |
|  The free version shows Now & Next programs.     |
|  Upgrade to Premium for the full grid view.      |
|                                                   |
|  [Preview]            [Upgrade to Premium]       |
|                                                   |
|  Preview: 3-day trial of full EPG                |
+--------------------------------------------------+
```

#### 10.4.3 Creating Additional Profile (Free User)

```
User taps "Add Profile"
          |
          v
+--------------------------------------------------+
|  Multiple Profiles - Premium Feature             |
|                                                   |
|  Free accounts can have 1 profile.               |
|  Upgrade to Premium for up to 5 profiles.        |
|                                                   |
|  [Upgrade to Premium]                            |
|  [Maybe Later]                                    |
+--------------------------------------------------+
```

#### 10.4.4 Favorites Limit Reached (Free User)

```
User adds 51st channel to favorites
          |
          v
+--------------------------------------------------+
|  Favorites Limit Reached                         |
|                                                   |
|  You've reached the free limit of 50 channels.   |
|  Upgrade to Premium for unlimited favorites.     |
|                                                   |
|  [Upgrade to Premium]                            |
|  [Manage Favorites]                              |
+--------------------------------------------------+
```

### 10.5 In-App Purchase Flow

```
User selects plan (e.g., Annual)
          |
          v
Platform payment sheet appears (Apple/Google)
          |
          v
User confirms with Face ID / fingerprint / password
          |
          v
Processing... (show loading)
          |
          +--- Success ---> Success Screen
          |
          +--- Failure ---> Error Screen with retry
```

#### 10.5.1 Purchase Success Screen

```
+--------------------------------------------------+
|                                                   |
|                    [Checkmark]                   |
|                                                   |
|        Welcome to Kylos Premium!                 |
|                                                   |
|   Thank you for your purchase.                   |
|   All premium features are now unlocked.         |
|                                                   |
|   Your subscription:                             |
|   Annual - $24.99/year                           |
|   Renews: November 30, 2025                      |
|                                                   |
|   [Start Exploring]                              |
|                                                   |
+--------------------------------------------------+
```

#### 10.5.2 Purchase Error Screen

```
+--------------------------------------------------+
|                                                   |
|                    [Error Icon]                  |
|                                                   |
|        Purchase Failed                           |
|                                                   |
|   We couldn't complete your purchase.            |
|   Error: Payment declined                        |
|                                                   |
|   [Try Again]                                    |
|   [Contact Support]                              |
|   [Cancel]                                        |
|                                                   |
+--------------------------------------------------+
```

### 10.6 Restore Purchases Flow

**Trigger:** "Restore Purchases" button in Premium screen or Settings

```
User taps "Restore Purchases"
          |
          v
+--------------------------------------------------+
|  Restoring Purchases...                          |
|  [Progress indicator]                            |
+--------------------------------------------------+
          |
          +--- Found ---> "Premium restored! Enjoy."
          |
          +--- Not Found ---> "No purchases found for this account."
```

### 10.7 Subscription Management

**Access:** Settings > Subscription

```
+--------------------------------------------------+
|  [<] Subscription                                |
+--------------------------------------------------+
|                                                   |
|  Current Plan: Premium Annual                    |
|  Status: Active                                  |
|                                                   |
|  Renews: November 30, 2025                       |
|  Price: $24.99/year                              |
|                                                   |
+--------------------------------------------------+
|                                                   |
|  [Manage in App Store / Play Store]              |
|                                                   |
|  To cancel or change your subscription,          |
|  use your device's subscription settings.        |
|                                                   |
+--------------------------------------------------+
|                                                   |
|  Purchase History                                |
|  - Nov 30, 2024: Annual subscription $24.99     |
|                                                   |
+--------------------------------------------------+
```

### 10.8 Ad Placement Strategy (Free Tier)

#### 10.8.1 Where Ads Appear

| Location | Ad Type | Frequency |
|----------|---------|-----------|
| App launch | Interstitial | 1 per session (max) |
| Home screen | Banner (bottom) | Always visible |
| Channel list | Banner (bottom) | Always visible |
| Movie details | Banner (bottom) | Always visible |
| Between content | Rewarded optional | User-initiated |

#### 10.8.2 Where Ads NEVER Appear

- During video playback (Live TV or VOD)
- In Settings
- During onboarding
- On paywall/upgrade screens
- After successful purchase

#### 10.8.3 Rewarded Ad Option (Phase 2)

```
User on Free tier views EPG
          |
          v
+--------------------------------------------------+
|  Want to try Full EPG?                           |
|                                                   |
|  Watch a short ad to unlock the full TV guide   |
|  for 24 hours.                                   |
|                                                   |
|  [Watch Ad]          [No Thanks]                 |
|                                                   |
|  Or upgrade to Premium for permanent access      |
+--------------------------------------------------+
```

### 10.9 Platform Compliance Notes

**Apple App Store:**
- Use StoreKit 2 for purchases
- Display "Terms of Use" and "Privacy Policy" links
- Show subscription price, duration, and auto-renewal terms clearly
- Provide "Restore Purchases" functionality
- Do not incentivize reviews in exchange for features

**Google Play Store:**
- Use Google Play Billing Library
- Clearly disclose subscription terms before purchase
- Provide subscription management link to Play Store
- Handle Grace Period and Account Hold states
- Support promo codes (optional)

---

## 11. Error Handling & Edge Cases

### 11.1 Network Errors

#### 11.1.1 No Internet Connection

```
+--------------------------------------------------+
|                                                   |
|              [No Connection Icon]                |
|                                                   |
|           No Internet Connection                 |
|                                                   |
|   Please check your network settings             |
|   and try again.                                 |
|                                                   |
|   [Retry]                                        |
|                                                   |
|   Some features like favorites may still         |
|   work offline.                                   |
|                                                   |
+--------------------------------------------------+
```

#### 11.1.2 Stream Playback Error

```
+--------------------------------------------------+
|                                                   |
|              [Error Icon]                        |
|                                                   |
|           Unable to Play                         |
|                                                   |
|   This channel is currently unavailable.         |
|   This could be due to:                          |
|   - Provider server issues                       |
|   - Network connectivity problems               |
|   - Channel is offline                           |
|                                                   |
|   [Try Again]     [Choose Another Channel]       |
|                                                   |
+--------------------------------------------------+
```

#### 11.1.3 Playlist Load Error

```
+--------------------------------------------------+
|  Error Loading Playlist                          |
|                                                   |
|  Could not connect to your IPTV provider.        |
|                                                   |
|  Error: Connection timeout                       |
|                                                   |
|  [Retry]                                         |
|  [Edit Playlist]                                 |
|  [Use Cached Data]                               |
+--------------------------------------------------+
```

### 11.2 Authentication Errors

#### 11.2.1 Xtream Codes Auth Failed

```
+--------------------------------------------------+
|  Authentication Failed                           |
|                                                   |
|  Could not log in to your IPTV provider.         |
|                                                   |
|  Possible reasons:                               |
|  - Incorrect username or password               |
|  - Account expired                               |
|  - Provider server is down                       |
|                                                   |
|  [Check Credentials]                             |
|  [Contact Provider]                              |
+--------------------------------------------------+
```

#### 11.2.2 Account Expired

```
+--------------------------------------------------+
|  Account Expired                                 |
|                                                   |
|  Your IPTV subscription appears to have          |
|  expired.                                        |
|                                                   |
|  Please contact your IPTV provider to           |
|  renew your subscription.                        |
|                                                   |
|  [OK]                                            |
+--------------------------------------------------+
```

### 11.3 Content Not Available

#### 11.3.1 Channel Offline

```
During playback attempt:
+--------------------------------------------------+
|  Channel Unavailable                             |
|                                                   |
|  "CNN" is currently offline.                     |
|                                                   |
|  [Try Again]     [Watch Something Else]          |
+--------------------------------------------------+
```

#### 11.3.2 VOD Not Found

```
+--------------------------------------------------+
|  Content Unavailable                             |
|                                                   |
|  This movie is no longer available from          |
|  your IPTV provider.                             |
|                                                   |
|  [Browse Other Movies]                           |
+--------------------------------------------------+
```

### 11.4 EPG Errors

#### 11.4.1 EPG Load Failed

```
+--------------------------------------------------+
|  EPG Unavailable                                 |
|                                                   |
|  Could not load TV guide data.                   |
|                                                   |
|  [Retry]     [Continue Without EPG]              |
+--------------------------------------------------+
```

#### 11.4.2 EPG Data Outdated

```
+--------------------------------------------------+
|  EPG Data Outdated                               |
|                                                   |
|  Your TV guide data is more than 24 hours old.  |
|                                                   |
|  [Refresh Now]     [Use Anyway]                  |
+--------------------------------------------------+
```

### 11.5 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Empty playlist (0 channels) | Show error, prompt to check URL or contact provider |
| Very large playlist (>5000 channels) | Show loading progress, paginate display |
| No EPG data for channel | Show "No program info available" instead of empty |
| Multiple streams for same channel | Default to first, offer quality selection |
| Unsupported stream format | Show "Format not supported" error |
| App killed during playback | Resume playback on reopen (with prompt) |
| Background playback (audio) | Continue audio for radio channels |
| Picture-in-Picture exit | Remember position, offer resume |

---

## 12. Feature Phasing

### 12.1 MVP (Phase 1) - Core Experience

**Target:** 3-4 months development

| Category | Features |
|----------|----------|
| **Onboarding** | Welcome flow, legal consent, single playlist setup (M3U + Xtream) |
| **Auth** | Firebase Auth (email, Google, Apple, anonymous) |
| **Live TV** | Channel list, categories, search, basic playback |
| **EPG** | Now/Next display, basic EPG fetch |
| **VOD** | Movies list, series list, basic playback, resume |
| **Favorites** | Add/remove favorites (limited to 50 channels, 20 VOD) |
| **Player** | Play/pause, channel zap, quality selection, audio/subtitle |
| **Settings** | Basic playback options, clear cache, about |
| **Monetization** | Freemium gates, Premium subscription (RevenueCat), basic ads |
| **Platforms** | Android, iOS |

### 12.2 Phase 2 - Enhanced Experience

**Target:** 2-3 months after MVP

| Category | Features |
|----------|----------|
| **TV Support** | Android TV, Fire TV with D-pad navigation |
| **Profiles** | Multiple profiles, profile switching |
| **Parental Controls** | PIN lock, category/channel locking, Kids profile |
| **EPG** | Full grid view, multi-day navigation |
| **Multiple Playlists** | Add/manage multiple sources (Premium) |
| **Cloud Sync** | Backup/restore favorites, settings, history |
| **Continue Watching** | Full implementation with sync |
| **Auto-play** | Next episode auto-play |
| **Casting** | Chromecast, AirPlay support |

### 12.3 Phase 3 - Platform Expansion

**Target:** 3-4 months after Phase 2

| Category | Features |
|----------|----------|
| **Samsung Tizen** | Tizen TV app (if Flutter-Tizen viable) |
| **Apple TV** | tvOS app |
| **Advanced Search** | Filters (year, genre, rating) |
| **Merged Playlists** | Combine channels from multiple sources |
| **TV QR Linking** | Easy setup from phone to TV |
| **Recording** | If legally feasible and storage allows |
| **Watch Party** | Sync viewing with friends (Phase 3+) |

### 12.4 Nice-to-Have (Backlog)

| Feature | Notes |
|---------|-------|
| Custom channel ordering | Drag and drop to reorder |
| Channel number assignment | Assign numbers for remote input |
| Picture-in-Picture on mobile | Mini player while browsing |
| Background playback | Audio-only mode for radio |
| Widgets (Android/iOS) | Quick access to favorites |
| Siri/Google Assistant | Voice control integration |
| Multiple audio tracks | Simultaneous playback |
| Stream recording | Record to device storage |
| Custom themes | Color customization |
| M3U file upload | Upload from device storage |

### 12.5 Feature Priority Matrix

```
                    HIGH IMPACT
                         |
    Profiles          Multiple     Full EPG
    Parental         Playlists      Grid
    Controls                         |
                         |           |
LOW EFFORT -----+--------+-----------+-------- HIGH EFFORT
                         |           |
    Clear Cache      Cloud Sync   TV Apps
    Basic Search                  Casting
                         |
                    LOW IMPACT
```

---

## 13. Appendices

### 13.1 Screen Inventory

| Screen | Platform | Priority |
|--------|----------|----------|
| Splash | All | MVP |
| Welcome | All | MVP |
| Legal Consent | All | MVP |
| Add Source | All | MVP |
| Login/Register | All | MVP |
| Home | All | MVP |
| Live TV List | All | MVP |
| EPG Grid | All | Phase 2 (Now/Next in MVP) |
| Channel Details | All | MVP |
| Player (Live) | All | MVP |
| Movies List | All | MVP |
| Movie Details | All | MVP |
| Series List | All | MVP |
| Series Details | All | MVP |
| Player (VOD) | All | MVP |
| Favorites | All | MVP |
| Search | All | MVP |
| Search Results | All | MVP |
| Settings | All | MVP |
| Manage Playlists | All | MVP |
| Add/Edit Playlist | All | MVP |
| Profiles | All | Phase 2 |
| Profile Switcher | All | Phase 2 |
| Create/Edit Profile | All | Phase 2 |
| Parental Controls | All | Phase 2 |
| PIN Entry | All | Phase 2 |
| Subscription/Premium | All | MVP |
| Purchase Success | All | MVP |
| Backup & Sync | All | Phase 2 |
| Help & Support | All | MVP |

### 13.2 Accessibility Considerations

| Requirement | Implementation |
|-------------|----------------|
| Screen reader support | Semantic labels on all interactive elements |
| High contrast | Support system high contrast mode |
| Text scaling | Support dynamic type / font scaling |
| Focus indicators | Clear visible focus states for TV/keyboard |
| Touch targets | Minimum 44x44pt touch targets |
| Color independence | Don't rely on color alone for meaning |
| Captions/Subtitles | Support for closed captions when available |
| Reduced motion | Respect system reduce motion preference |

### 13.3 Localization Notes

**MVP Languages:**
- English (default)
- Spanish
- French
- German
- Portuguese

**Phase 2 Languages:**
- Arabic (RTL support)
- Italian
- Dutch
- Polish
- Turkish

**Localization Requirements:**
- All UI strings externalized
- Date/time format localization
- Number format localization
- RTL layout support
- No hardcoded text in images

### 13.4 Analytics Events

| Event | Parameters | Phase |
|-------|------------|-------|
| `app_open` | `source`, `is_first_launch` | MVP |
| `onboarding_complete` | `time_spent`, `source_type` | MVP |
| `playlist_added` | `type`, `channel_count` | MVP |
| `channel_played` | `channel_id`, `category`, `source` | MVP |
| `vod_played` | `content_id`, `type`, `resume` | MVP |
| `search_performed` | `query`, `results_count` | MVP |
| `favorite_added` | `content_type`, `content_id` | MVP |
| `epg_viewed` | `view_type` | MVP |
| `premium_screen_viewed` | `trigger` | MVP |
| `purchase_initiated` | `product_id` | MVP |
| `purchase_completed` | `product_id`, `price` | MVP |
| `ad_viewed` | `ad_type`, `placement` | MVP |
| `profile_created` | `type` | Phase 2 |
| `profile_switched` | `profile_type` | Phase 2 |
| `parental_pin_set` | - | Phase 2 |
| `playlist_merged` | `source_count` | Phase 3 |

### 13.5 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App launch to interactive | < 3 seconds | Cold start |
| Channel switch time | < 2 seconds | Time to first frame |
| Playlist parse (1000 channels) | < 5 seconds | M3U parsing |
| EPG load (7 days, 500 channels) | < 10 seconds | XMLTV parsing |
| Search results | < 500ms | Local search |
| Memory usage | < 200MB | Typical usage |
| Battery drain | < 5%/hour | During playback |
| Crash-free sessions | > 99.5% | Crashlytics |

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Nov 2024 | Product Team | Initial functional specification |

---

*This document defines the functional requirements for Kylos IPTV Player. Implementation details and technical specifications are covered in the Architecture Vision document and subsequent technical design documents.*
