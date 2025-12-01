// Kylos IPTV Player - Form Factor
// Platform and form factor detection utilities.

/// Represents the device form factor for adaptive UI.
enum FormFactor {
  /// Phone devices (< 600dp shortest side)
  mobile,

  /// Tablet devices (>= 600dp shortest side)
  tablet,

  /// TV devices (Android TV, Fire TV)
  tv,

  /// Desktop applications (macOS, Windows, Linux)
  desktop,

  /// Web browser
  web,
}

/// Extension methods for FormFactor enum.
extension FormFactorExtension on FormFactor {
  /// Whether this is a mobile device (phone or tablet).
  bool get isMobile => this == FormFactor.mobile || this == FormFactor.tablet;

  /// Whether this is a TV platform.
  bool get isTV => this == FormFactor.tv;

  /// Whether this is a desktop platform.
  bool get isDesktop => this == FormFactor.desktop;

  /// Whether this is a web platform.
  bool get isWeb => this == FormFactor.web;

  /// Whether this platform uses remote/keyboard navigation (no touch).
  bool get usesFocusNavigation => this == FormFactor.tv;

  /// Whether this platform primarily uses touch input.
  bool get usesTouchInput => isMobile;
}

/// Represents the primary input mode for the current platform.
enum InputMode {
  /// Touch-based input (tap, swipe, pinch)
  touch,

  /// D-pad remote control input
  dpad,

  /// Keyboard and mouse input
  keyboard,

  /// Mouse-only input
  mouse,
}

/// Extension methods for InputMode enum.
extension InputModeExtension on InputMode {
  /// Whether this input mode requires visible focus indicators.
  bool get requiresFocusIndicators =>
      this == InputMode.dpad || this == InputMode.keyboard;
}
