// Kylos IPTV Player - Platform Providers
// Riverpod providers for platform-related state.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';

/// Form factor provider - overridden at app startup.
///
/// This provider is overridden in bootstrap.dart with the detected
/// or specified form factor for the current platform.
final formFactorProvider = Provider<FormFactor>((ref) {
  // Default value, will be overridden in bootstrap
  return FormFactor.mobile;
});

/// Whether the app is running on a TV platform.
final isTvProvider = Provider<bool>((ref) {
  return ref.watch(formFactorProvider) == FormFactor.tv;
});

/// Whether the app is running on mobile (phone/tablet).
final isMobileProvider = Provider<bool>((ref) {
  final formFactor = ref.watch(formFactorProvider);
  return formFactor == FormFactor.mobile || formFactor == FormFactor.tablet;
});

/// Input mode based on form factor.
final inputModeProvider = Provider<InputMode>((ref) {
  final formFactor = ref.watch(formFactorProvider);
  switch (formFactor) {
    case FormFactor.mobile:
    case FormFactor.tablet:
      return InputMode.touch;
    case FormFactor.tv:
      return InputMode.dpad;
    case FormFactor.desktop:
    case FormFactor.web:
      return InputMode.keyboard;
  }
});
