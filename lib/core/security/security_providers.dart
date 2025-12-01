// Kylos IPTV Player - Security Providers
// Riverpod providers for security services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/security/secure_storage_service.dart';
import 'package:kylos_iptv_player/core/security/credential_manager.dart';
import 'package:kylos_iptv_player/core/security/integrity_checker.dart';

/// Provider for the secure storage service.
///
/// Uses the platform-appropriate secure storage implementation.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return FlutterSecureStorageService();
});

/// Provider for the credential manager.
///
/// Handles secure storage of IPTV provider credentials.
final credentialManagerProvider = Provider<CredentialManager>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return CredentialManager(secureStorage: secureStorage);
});

/// Provider for the integrity checker.
///
/// Detects tampering, root/jailbreak, and emulator environments.
final integrityCheckerProvider = Provider<IntegrityChecker>((ref) {
  // Use permissive config by default - detect but don't block
  // Change to IntegrityConfig.strict for more paranoid mode
  return IntegrityChecker(config: IntegrityConfig.permissive);
});

/// Provider for the integrity check result.
///
/// Runs the integrity check once and caches the result.
/// Use this to check device integrity at app startup.
final integrityCheckResultProvider =
    FutureProvider<IntegrityCheckResult>((ref) async {
  final checker = ref.watch(integrityCheckerProvider);
  return checker.checkIntegrity();
});
