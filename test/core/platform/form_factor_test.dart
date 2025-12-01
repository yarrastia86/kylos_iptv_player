// Kylos IPTV Player - Form Factor Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';

void main() {
  group('FormFactor', () {
    test('should have five form factors', () {
      expect(FormFactor.values.length, 5);
      expect(FormFactor.values, contains(FormFactor.mobile));
      expect(FormFactor.values, contains(FormFactor.tablet));
      expect(FormFactor.values, contains(FormFactor.tv));
      expect(FormFactor.values, contains(FormFactor.desktop));
      expect(FormFactor.values, contains(FormFactor.web));
    });
  });

  group('FormFactorExtensions', () {
    group('isMobile', () {
      test('should return true for mobile and tablet', () {
        expect(FormFactor.mobile.isMobile, true);
        expect(FormFactor.tablet.isMobile, true);
      });

      test('should return false for non-mobile form factors', () {
        expect(FormFactor.tv.isMobile, false);
        expect(FormFactor.desktop.isMobile, false);
        expect(FormFactor.web.isMobile, false);
      });
    });

    group('isTV', () {
      test('should return true only for tv', () {
        expect(FormFactor.tv.isTV, true);
      });

      test('should return false for non-TV form factors', () {
        expect(FormFactor.mobile.isTV, false);
        expect(FormFactor.tablet.isTV, false);
        expect(FormFactor.desktop.isTV, false);
        expect(FormFactor.web.isTV, false);
      });
    });

    group('usesTouchInput', () {
      test('should return true for touch-capable form factors', () {
        expect(FormFactor.mobile.usesTouchInput, true);
        expect(FormFactor.tablet.usesTouchInput, true);
      });

      test('should return false for non-touch form factors', () {
        expect(FormFactor.tv.usesTouchInput, false);
        expect(FormFactor.desktop.usesTouchInput, false);
        expect(FormFactor.web.usesTouchInput, false);
      });
    });

    group('usesFocusNavigation', () {
      test('should return true only for tv', () {
        expect(FormFactor.tv.usesFocusNavigation, true);
      });

      test('should return false for non-TV form factors', () {
        expect(FormFactor.mobile.usesFocusNavigation, false);
        expect(FormFactor.tablet.usesFocusNavigation, false);
        expect(FormFactor.desktop.usesFocusNavigation, false);
        expect(FormFactor.web.usesFocusNavigation, false);
      });
    });
  });
}
