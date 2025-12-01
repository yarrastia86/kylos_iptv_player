// Kylos IPTV Player - TV Entry Point
// Explicit TV entry point for Android TV and Fire TV builds.

import 'package:kylos_iptv_player/bootstrap.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';
import 'package:kylos_iptv_player/firebase_options.dart';

void main() {
  bootstrap(
    formFactor: FormFactor.tv,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );
}
