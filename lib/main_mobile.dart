// Kylos IPTV Player - Mobile Entry Point
// Explicit mobile entry point for Android/iOS phone and tablet builds.

import 'package:kylos_iptv_player/bootstrap.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';
import 'package:kylos_iptv_player/firebase_options.dart';

void main() {
  bootstrap(
    formFactor: FormFactor.mobile,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );
}
