// Kylos IPTV Player - App Widget
// Root application widget with MaterialApp and router configuration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/core/design_system/theme/app_theme.dart';
import 'package:kylos_iptv_player/core/design_system/theme/tv_theme.dart';
import 'package:kylos_iptv_player/core/platform/form_factor.dart';
import 'package:kylos_iptv_player/l10n/app_localizations.dart';
import 'package:kylos_iptv_player/navigation/app_router.dart';
import 'package:kylos_iptv_player/shared/providers/platform_providers.dart';

/// Root application widget for Kylos IPTV Player.
///
/// This widget sets up:
/// - Material 3 theming (adaptive for mobile/TV)
/// - go_router navigation
/// - Platform-specific shell (bottom nav vs side rail)
class KylosApp extends ConsumerWidget {
  const KylosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = ref.watch(formFactorProvider);
    final router = ref.watch(appRouterProvider);

    // Select theme based on form factor
    final darkTheme = formFactor == FormFactor.tv
        ? TvTheme.dark()
        : AppTheme.dark();

    final lightTheme = formFactor == FormFactor.tv
        ? TvTheme.light()
        : AppTheme.light();

    return MaterialApp.router(
      title: 'Kylos IPTV Player',
      debugShowCheckedModeBanner: false,

      // Theming
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark, // Default to dark for media apps

      // Routing
      routerConfig: router,

      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Builder for global overlays and TV focus management
      builder: (context, child) {
        return _AppShell(
          formFactor: formFactor,
          child: child!,
        );
      },
    );
  }
}

/// App shell that wraps the entire app with platform-specific handling.
class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.formFactor,
    required this.child,
  });

  final FormFactor formFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Wrap with TV-specific shortcuts handling if needed
    if (formFactor == FormFactor.tv) {
      return Shortcuts(
        shortcuts: _tvShortcuts,
        child: child,
      );
    }

    return child;
  }

  // TV remote button mappings
  static final _tvShortcuts = <LogicalKeySet, Intent>{
    // TODO: Add TV-specific shortcuts when implementing TV navigation
    // LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
  };
}
