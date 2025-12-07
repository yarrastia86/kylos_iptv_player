# Cross-Device Playback & Handoff Implementation Plan

## Overview
Implement seamless cross-device playback handoff for premium users, allowing them to transfer playback between Kylos instances on mobile, TV, web, and tablets.

## Architecture

### High-Level Flow
```
Device A (Playing)              Cloud (Firebase)           Device B (Target)
     │                               │                           │
     ├── Advertise presence ────────►│◄─────── Advertise presence─┤
     │                               │                           │
     ├── Request device list ───────►│                           │
     │◄── Return online devices ─────┤                           │
     │                               │                           │
     ├── Send handoff request ──────►│────► Push notification ──►│
     │                               │                           │
     │                               │◄───── Accept handoff ──────┤
     │◄── Handoff confirmed ─────────┤                           │
     │                               │                           │
     └── Stop playback               │         Start playback ───┘
```

### Discovery Strategy

**Hybrid Approach:**
1. **Firebase Realtime Database** - Primary for cross-network discovery
   - Devices register presence with heartbeat
   - Works across all networks (home, mobile, different locations)
   - Reliable push via FCM

2. **Local Network Discovery (mDNS)** - Optional enhancement
   - Faster discovery on same network
   - Reduces latency for same-LAN devices
   - Falls back to Firebase if mDNS fails

## Module Structure

```
lib/
├── core/
│   └── handoff/
│       ├── handoff.dart                    # Barrel export
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── device_presence.dart    # Online device state
│       │   │   ├── handoff_request.dart    # Handoff command
│       │   │   └── handoff_session.dart    # Active handoff state
│       │   └── repositories/
│       │       ├── presence_repository.dart    # Device presence interface
│       │       └── handoff_repository.dart     # Handoff messaging interface
│       └── presentation/
│           ├── handoff_providers.dart      # Riverpod providers
│           └── handoff_controller.dart     # StateNotifier
│
├── infrastructure/
│   └── firebase/
│       ├── realtime/
│       │   ├── firebase_presence_service.dart   # RTDB presence
│       │   └── firebase_handoff_service.dart    # RTDB messaging
│       └── messaging/
│           └── fcm_handoff_service.dart         # Push notifications
│
└── features/
    └── handoff/
        └── presentation/
            ├── screens/
            │   └── device_picker_screen.dart    # Full device picker
            ├── widgets/
            │   ├── device_picker_sheet.dart     # Bottom sheet picker
            │   ├── available_device_tile.dart   # Device list item
            │   ├── handoff_button.dart          # "Send to" button
            │   ├── incoming_handoff_dialog.dart # Accept/reject dialog
            │   └── resume_prompt.dart           # Cross-device resume
            └── providers/
                └── handoff_ui_providers.dart    # UI state
```

## Phase 1: Device Presence System

### 1.1 Firebase Realtime Database Structure

```
/presence/
  /{userId}/
    /{deviceId}/
      online: true
      lastSeen: 1703123456789
      deviceName: "Living Room TV"
      platform: "androidTv"
      formFactor: "tv"
      capabilities: ["playback", "receive_handoff"]
      appVersion: "1.0.0"
      currentContent: {           # Optional - what's playing
        contentId: "movie_123"
        title: "Inception"
        position: 3600
        type: "vod"
      }
```

### 1.2 DevicePresence Entity

```dart
class DevicePresence {
  final String deviceId;
  final String userId;
  final String deviceName;
  final DevicePlatform platform;
  final DeviceFormFactor formFactor;
  final bool isOnline;
  final DateTime lastSeen;
  final List<DeviceCapability> capabilities;
  final String? appVersion;
  final CurrentPlayback? currentContent;

  bool get canReceiveHandoff =>
    capabilities.contains(DeviceCapability.receiveHandoff);

  bool get isCurrentDevice;
  bool get isRecentlyActive =>
    DateTime.now().difference(lastSeen).inMinutes < 2;
}

enum DeviceCapability {
  playback,
  receiveHandoff,
  sendHandoff,
  casting,
}
```

### 1.3 Presence Repository

```dart
abstract class PresenceRepository {
  /// Start advertising this device's presence
  Future<void> goOnline(DevicePresence presence);

  /// Stop advertising (going offline)
  Future<void> goOffline(String userId, String deviceId);

  /// Update current playback info
  Future<void> updateCurrentContent(
    String userId,
    String deviceId,
    CurrentPlayback? content,
  );

  /// Watch all online devices for this user
  Stream<List<DevicePresence>> watchOnlineDevices(String userId);

  /// Get snapshot of online devices
  Future<List<DevicePresence>> getOnlineDevices(String userId);

  /// Heartbeat to maintain presence
  Future<void> heartbeat(String userId, String deviceId);
}
```

### 1.4 Firebase Presence Implementation

```dart
class FirebasePresenceService implements PresenceRepository {
  final FirebaseDatabase _rtdb;
  Timer? _heartbeatTimer;

  DatabaseReference _presenceRef(String userId, String deviceId) =>
    _rtdb.ref('presence/$userId/$deviceId');

  @override
  Future<void> goOnline(DevicePresence presence) async {
    final ref = _presenceRef(presence.userId, presence.deviceId);

    // Set presence data
    await ref.set(presence.toJson());

    // Set up onDisconnect to automatically go offline
    await ref.onDisconnect().remove();

    // Start heartbeat
    _startHeartbeat(presence.userId, presence.deviceId);
  }

  @override
  Stream<List<DevicePresence>> watchOnlineDevices(String userId) {
    return _rtdb.ref('presence/$userId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <DevicePresence>[];

      return data.entries
        .map((e) => DevicePresence.fromJson(e.key, e.value))
        .where((d) => d.isOnline && d.isRecentlyActive)
        .toList();
    });
  }
}
```

## Phase 2: Handoff Messaging

### 2.1 Handoff Request Entity

```dart
class HandoffRequest {
  final String id;
  final String fromDeviceId;
  final String fromDeviceName;
  final String toDeviceId;
  final String userId;
  final PlayableContent content;
  final Duration position;
  final DateTime timestamp;
  final HandoffStatus status;
}

enum HandoffStatus {
  pending,
  accepted,
  rejected,
  completed,
  expired,
  cancelled,
}
```

### 2.2 Firebase RTDB Handoff Structure

```
/handoff_requests/
  /{userId}/
    /{toDeviceId}/
      requestId: "uuid"
      fromDeviceId: "device_123"
      fromDeviceName: "Phone"
      content: {
        id: "movie_123"
        title: "Inception"
        streamUrl: "https://..."
        type: "vod"
      }
      position: 3600000  # milliseconds
      timestamp: 1703123456789
      status: "pending"
```

### 2.3 Handoff Repository

```dart
abstract class HandoffRepository {
  /// Send handoff request to target device
  Future<HandoffRequest> sendHandoffRequest({
    required String userId,
    required String fromDeviceId,
    required String fromDeviceName,
    required String toDeviceId,
    required PlayableContent content,
    required Duration position,
  });

  /// Watch for incoming handoff requests
  Stream<HandoffRequest?> watchIncomingRequests(
    String userId,
    String deviceId,
  );

  /// Accept handoff request
  Future<void> acceptHandoff(HandoffRequest request);

  /// Reject handoff request
  Future<void> rejectHandoff(HandoffRequest request);

  /// Cancel sent request
  Future<void> cancelHandoff(HandoffRequest request);

  /// Mark handoff as completed (playback started on target)
  Future<void> completeHandoff(HandoffRequest request);
}
```

### 2.4 FCM Push Notifications

For devices in background or screen off:

```dart
class FCMHandoffService {
  /// Subscribe device to handoff topic
  Future<void> subscribeToHandoffs(String userId, String deviceId) async {
    await FirebaseMessaging.instance
      .subscribeToTopic('handoff_$userId_$deviceId');
  }

  /// Send push notification for handoff
  Future<void> sendHandoffPush(HandoffRequest request) async {
    // Cloud Function triggers FCM to target device
    await FirebaseFunctions.instance
      .httpsCallable('sendHandoffNotification')
      .call({
        'userId': request.userId,
        'toDeviceId': request.toDeviceId,
        'requestId': request.id,
        'title': 'Play on this device?',
        'body': '${request.fromDeviceName} wants to play ${request.content.title}',
      });
  }
}
```

## Phase 3: Handoff Controller

### 3.1 Handoff State

```dart
class HandoffState {
  final List<DevicePresence> availableDevices;
  final bool isLoading;
  final HandoffRequest? pendingOutgoingRequest;
  final HandoffRequest? incomingRequest;
  final String? error;

  bool get hasAvailableDevices =>
    availableDevices.where((d) => !d.isCurrentDevice).isNotEmpty;

  bool get hasPendingRequest => pendingOutgoingRequest != null;
  bool get hasIncomingRequest => incomingRequest != null;
}
```

### 3.2 Handoff Controller

```dart
class HandoffController extends StateNotifier<HandoffState> {
  HandoffController({
    required this.presenceRepository,
    required this.handoffRepository,
    required this.playbackNotifier,
    required this.currentDeviceId,
    required this.userId,
  });

  /// Initialize and start listening
  Future<void> initialize() async {
    // Go online
    await _goOnline();

    // Watch available devices
    _devicesSubscription = presenceRepository
      .watchOnlineDevices(userId)
      .listen(_onDevicesChanged);

    // Watch incoming requests
    _requestsSubscription = handoffRepository
      .watchIncomingRequests(userId, currentDeviceId)
      .listen(_onIncomingRequest);
  }

  /// Send playback to another device
  Future<void> sendToDevice(DevicePresence targetDevice) async {
    final playbackState = playbackNotifier.state;
    if (!playbackState.hasContent) return;

    state = state.copyWith(isLoading: true);

    try {
      final request = await handoffRepository.sendHandoffRequest(
        userId: userId,
        fromDeviceId: currentDeviceId,
        fromDeviceName: await _getDeviceName(),
        toDeviceId: targetDevice.deviceId,
        content: playbackState.content!,
        position: playbackState.position ?? Duration.zero,
      );

      state = state.copyWith(
        pendingOutgoingRequest: request,
        isLoading: false,
      );

      // Wait for response with timeout
      _startRequestTimeout(request);

    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send handoff request',
        isLoading: false,
      );
    }
  }

  /// Accept incoming handoff
  Future<void> acceptIncomingHandoff() async {
    final request = state.incomingRequest;
    if (request == null) return;

    // Accept in Firebase
    await handoffRepository.acceptHandoff(request);

    // Start playback
    await playbackNotifier.play(request.content);
    await playbackNotifier.seek(request.position);

    // Mark completed
    await handoffRepository.completeHandoff(request);

    state = state.copyWith(incomingRequest: null);
  }

  /// Reject incoming handoff
  Future<void> rejectIncomingHandoff() async {
    final request = state.incomingRequest;
    if (request == null) return;

    await handoffRepository.rejectHandoff(request);
    state = state.copyWith(incomingRequest: null);
  }

  void _onHandoffAccepted(HandoffRequest request) {
    // Stop local playback
    playbackNotifier.stop();

    state = state.copyWith(pendingOutgoingRequest: null);

    // Show success message
  }
}
```

## Phase 4: UI Components

### 4.1 Device Picker Sheet

```dart
class DevicePickerSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handoffState = ref.watch(handoffControllerProvider);
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return _PremiumRequiredView();
    }

    return DraggableScrollableSheet(
      child: Column(
        children: [
          _Header(title: 'Send to device'),
          if (handoffState.isLoading)
            const CircularProgressIndicator()
          else if (handoffState.availableDevices.isEmpty)
            _NoDevicesView()
          else
            Expanded(
              child: ListView.builder(
                itemCount: handoffState.availableDevices.length,
                itemBuilder: (context, index) {
                  final device = handoffState.availableDevices[index];
                  if (device.isCurrentDevice) return const SizedBox.shrink();

                  return AvailableDeviceTile(
                    device: device,
                    onTap: () => _sendToDevice(context, ref, device),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

### 4.2 Handoff Button in Player Controls

```dart
class HandoffButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handoffState = ref.watch(handoffControllerProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final hasDevices = handoffState.hasAvailableDevices;
    final isEnabled = isPremium && hasDevices;

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.cast_connected),
          if (!isPremium)
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.lock, size: 12),
            ),
          if (hasDevices)
            Positioned(
              right: 0,
              top: 0,
              child: _DeviceCountBadge(count: handoffState.availableDevices.length - 1),
            ),
        ],
      ),
      onPressed: isEnabled
        ? () => _showDevicePicker(context)
        : isPremium ? null : () => _showUpgradePrompt(context),
      tooltip: isPremium
        ? 'Send to device'
        : 'Upgrade to Pro for cross-device playback',
    );
  }
}
```

### 4.3 Incoming Handoff Dialog

```dart
class IncomingHandoffDialog extends ConsumerWidget {
  final HandoffRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cast),
          SizedBox(width: 8),
          Text('Incoming Playback'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${request.fromDeviceName} wants to play:'),
          SizedBox(height: 12),
          _ContentPreview(content: request.content),
          SizedBox(height: 8),
          Text(
            'Position: ${_formatDuration(request.position)}',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => ref.read(handoffControllerProvider.notifier)
            .rejectIncomingHandoff(),
          child: Text('Decline'),
        ),
        FilledButton.icon(
          onPressed: () => ref.read(handoffControllerProvider.notifier)
            .acceptIncomingHandoff(),
          icon: Icon(Icons.play_arrow),
          label: Text('Play Here'),
        ),
      ],
    );
  }
}
```

### 4.4 Resume Prompt (Cross-Device)

```dart
class CrossDeviceResumePrompt extends ConsumerWidget {
  final PlayableContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloudProgress = ref.watch(cloudWatchProgressProvider(content.id));

    return cloudProgress.when(
      data: (progress) {
        if (progress == null || !progress.canResume) {
          return const SizedBox.shrink();
        }

        final wasOnDifferentDevice = progress.deviceId != currentDeviceId;

        return Card(
          child: ListTile(
            leading: Icon(Icons.play_circle_fill),
            title: Text('Continue watching'),
            subtitle: Text(
              wasOnDifferentDevice
                ? 'Resume from ${progress.deviceName} at ${_formatDuration(progress.position)}'
                : 'Resume at ${_formatDuration(progress.position)}',
            ),
            trailing: FilledButton(
              onPressed: () => _resumePlayback(ref, progress),
              child: Text('Resume'),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

## Phase 5: Cloud Watch History Sync

### 5.1 Firestore Watch Progress Structure

```
/users/{userId}/watch_progress/{contentId}
  contentId: "movie_123"
  contentType: "vod"
  title: "Inception"
  positionSeconds: 3600
  durationSeconds: 8880
  progress: 0.405
  posterUrl: "https://..."
  seriesId: null
  seasonNumber: null
  episodeNumber: null
  deviceId: "device_abc"
  deviceName: "Living Room TV"
  updatedAt: Timestamp
```

### 5.2 Cloud Watch History Repository

```dart
class FirestoreWatchHistoryRepository implements WatchHistoryRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  CollectionReference<Map<String, dynamic>> get _collection =>
    _firestore.collection('users').doc(userId).collection('watch_progress');

  @override
  Future<void> saveProgress(WatchProgress progress) async {
    await _collection.doc(progress.contentId).set(
      progress.toJson()..['updatedAt'] = FieldValue.serverTimestamp(),
      SetOptions(merge: true),
    );
  }

  @override
  Stream<WatchProgress?> watchProgress(String contentId) {
    return _collection.doc(contentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return WatchProgress.fromFirestore(doc);
    });
  }

  @override
  Stream<List<WatchProgress>> watchContinueWatching({int limit = 20}) {
    return _collection
      .where('progress', isGreaterThan: 0.01)
      .where('progress', isLessThan: 0.9)
      .orderBy('progress')
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((d) => WatchProgress.fromFirestore(d)).toList()
      );
  }
}
```

### 5.3 Hybrid Local + Cloud Strategy

```dart
class HybridWatchHistoryRepository implements WatchHistoryRepository {
  final LocalWatchHistoryRepository _local;
  final FirestoreWatchHistoryRepository? _cloud;
  final bool isPremium;

  @override
  Future<void> saveProgress(WatchProgress progress) async {
    // Always save locally (works offline)
    await _local.saveProgress(progress);

    // Sync to cloud if premium
    if (isPremium && _cloud != null) {
      try {
        await _cloud!.saveProgress(progress);
      } catch (e) {
        // Queue for later sync
        await _queueForSync(progress);
      }
    }
  }

  @override
  Future<WatchProgress?> getProgress(String contentId) async {
    // Try cloud first for premium (most up-to-date)
    if (isPremium && _cloud != null) {
      try {
        final cloudProgress = await _cloud!.getProgress(contentId);
        if (cloudProgress != null) {
          // Update local cache
          await _local.saveProgress(cloudProgress);
          return cloudProgress;
        }
      } catch (e) {
        // Fall back to local
      }
    }

    return _local.getProgress(contentId);
  }
}
```

## Phase 6: QR Code TV Authentication

### 6.1 Flow

```
TV Screen                         Mobile App
    │                                  │
    ├── Generate pairing code ────────►│
    │   (Show QR + 6-digit code)       │
    │                                  │
    │                     Scan QR ─────┤
    │                     or enter code│
    │                                  │
    │◄──────────── Confirm pairing ────┤
    │                                  │
    ├── Receive auth token ───────────►│
    │                                  │
    └── Sign in with token             │
```

### 6.2 Pairing Code Structure

```
/pairing_codes/{code}
  code: "ABC123"
  createdAt: Timestamp
  expiresAt: Timestamp (5 minutes)
  deviceId: "tv_device_123"
  deviceName: "Living Room TV"
  status: "pending" | "claimed" | "completed" | "expired"
  claimedBy: null | userId
  authToken: null | "custom_token"
```

### 6.3 TV Pairing Service

```dart
class TVPairingService {
  /// Generate a pairing code for TV sign-in
  Future<PairingCode> generatePairingCode() async {
    final code = _generateCode(); // 6 alphanumeric chars
    final deviceId = await _getDeviceId();
    final deviceName = await _getDeviceName();

    final pairingCode = PairingCode(
      code: code,
      deviceId: deviceId,
      deviceName: deviceName,
      expiresAt: DateTime.now().add(Duration(minutes: 5)),
    );

    await _firestore.collection('pairing_codes')
      .doc(code)
      .set(pairingCode.toJson());

    return pairingCode;
  }

  /// Watch for pairing completion
  Stream<PairingStatus> watchPairingStatus(String code) {
    return _firestore.collection('pairing_codes')
      .doc(code)
      .snapshots()
      .map((doc) => PairingStatus.fromFirestore(doc));
  }

  /// Complete sign-in with received token
  Future<void> completeSignIn(String authToken) async {
    await FirebaseAuth.instance.signInWithCustomToken(authToken);
  }
}

class MobilePairingService {
  /// Claim a pairing code and authenticate TV
  Future<void> claimPairingCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw NotAuthenticatedException();

    // Update pairing code
    await _firestore.collection('pairing_codes').doc(code).update({
      'status': 'claimed',
      'claimedBy': user.uid,
    });

    // Generate custom token for TV (via Cloud Function)
    final result = await FirebaseFunctions.instance
      .httpsCallable('generateTVAuthToken')
      .call({'code': code, 'userId': user.uid});

    // Update with token
    await _firestore.collection('pairing_codes').doc(code).update({
      'status': 'completed',
      'authToken': result.data['token'],
    });
  }
}
```

## Phase 7: Cloud Functions

### Required Cloud Functions

```typescript
// functions/src/index.ts

// 1. Send handoff push notification
export const sendHandoffNotification = functions.https.onCall(async (data, context) => {
  const { userId, toDeviceId, requestId, title, body } = data;

  // Get FCM token for target device
  const deviceDoc = await admin.firestore()
    .collection('users').doc(userId)
    .collection('devices').doc(toDeviceId)
    .get();

  const fcmToken = deviceDoc.data()?.fcmToken;
  if (!fcmToken) throw new Error('Device not found or no FCM token');

  await admin.messaging().send({
    token: fcmToken,
    data: { type: 'handoff', requestId },
    notification: { title, body },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });
});

// 2. Generate custom auth token for TV
export const generateTVAuthToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error('Not authenticated');

  const { code, userId } = data;

  // Verify code exists and is claimed by this user
  const codeDoc = await admin.firestore()
    .collection('pairing_codes').doc(code).get();

  if (!codeDoc.exists) throw new Error('Invalid code');
  if (codeDoc.data()?.claimedBy !== userId) throw new Error('Unauthorized');

  // Generate custom token
  const customToken = await admin.auth().createCustomToken(userId, {
    deviceType: 'tv',
    pairedVia: code,
  });

  return { token: customToken };
});

// 3. Cleanup expired pairing codes
export const cleanupPairingCodes = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async () => {
    const expired = await admin.firestore()
      .collection('pairing_codes')
      .where('expiresAt', '<', admin.firestore.Timestamp.now())
      .get();

    const batch = admin.firestore().batch();
    expired.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });

// 4. Cleanup stale presence
export const cleanupStalePresence = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const staleThreshold = Date.now() - (5 * 60 * 1000); // 5 minutes

    // This would need RTDB admin cleanup
  });
```

## Implementation Priority

### Sprint 1: Foundation (1-2 weeks)
1. ✅ Device presence system with Firebase RTDB
2. ✅ Handoff request/response messaging
3. ✅ Basic handoff controller

### Sprint 2: UI & Integration (1-2 weeks)
4. Device picker bottom sheet
5. Handoff button in player controls
6. Incoming handoff dialog
7. Integration with existing player

### Sprint 3: Cloud Sync (1 week)
8. Firestore watch history repository
9. Hybrid local/cloud repository
10. Cross-device resume prompt

### Sprint 4: TV Features (1-2 weeks)
11. QR code pairing flow
12. TV-optimized handoff UI
13. Remote control navigation for handoff

### Sprint 5: Polish & Testing (1 week)
14. Error handling & edge cases
15. Offline behavior
16. Multi-device testing
17. Documentation

## Dependencies to Add

```yaml
# pubspec.yaml additions
dependencies:
  firebase_database: ^10.4.0      # Realtime Database for presence
  firebase_messaging: ^14.7.0     # FCM for push notifications
  qr_flutter: ^4.1.0              # QR code generation
  mobile_scanner: ^3.5.0          # QR code scanning
```

## Testing Strategy

1. **Unit Tests**
   - Presence repository
   - Handoff repository
   - Controller logic

2. **Widget Tests**
   - Device picker
   - Handoff dialogs
   - Resume prompts

3. **Integration Tests**
   - Full handoff flow between emulators
   - Presence updates
   - Cloud sync

4. **Manual Testing Matrix**
   - Mobile → TV handoff
   - TV → Mobile handoff
   - Tablet ↔ Phone
   - Same network vs different networks
   - Premium vs Free tier enforcement
