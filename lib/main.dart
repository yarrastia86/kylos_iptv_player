// Kylos IPTV Player - Main Entry Point
// Default entry point that detects platform and delegates initialization.

import 'package:kylos_iptv_player/bootstrap.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';
import 'package:kylos_iptv_player/firebase_options.dart';

void main() {
  // Default entry point - platform detection happens in bootstrap
  bootstrap(
    formFactor: FormFactor.mobile,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );
}
