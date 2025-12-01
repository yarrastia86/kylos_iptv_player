// Kylos IPTV Player - Shell Screen
// Main navigation shell with adaptive bottom nav / side rail.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kylos_iptv_player/core/tv/focus_system.dart';
import 'package:kylos_iptv_player/navigation/routes.dart';
import 'package:kylos_iptv_player/shared/providers/platform_providers.dart';

/// Shell screen that provides navigation scaffold.
///
/// Renders different navigation patterns based on form factor:
/// - Mobile: Bottom navigation bar
/// - TV: Side navigation rail with focus support
class ShellScreen extends ConsumerWidget {
  const ShellScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTV = ref.watch(isTvProvider);

    if (isTV) {
      return _TvShellScreen(child: child);
    }

    return _MobileShellScreen(child: child);
  }
}

/// Mobile shell with bottom navigation bar.
class _MobileShellScreen extends StatelessWidget {
  const _MobileShellScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Live TV',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label: 'Series',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.liveTV)) return 0;
    if (location.startsWith(Routes.vod)) return 1;
    if (location.startsWith(Routes.series)) return 2;
    if (location.startsWith(Routes.settings)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.liveTV);
      case 1:
        context.go(Routes.vod);
      case 2:
        context.go(Routes.series);
      case 3:
        context.go(Routes.settings);
    }
  }
}

/// TV shell with side navigation rail and focus support.
class _TvShellScreen extends StatefulWidget {
  const _TvShellScreen({required this.child});

  final Widget child;

  @override
  State<_TvShellScreen> createState() => _TvShellScreenState();
}

class _TvShellScreenState extends State<_TvShellScreen> {
  final List<FocusNode> _navFocusNodes = [];
  final FocusNode _contentFocusNode = FocusNode(debugLabel: 'TV Content Area');
  bool _railHasFocus = false;

  static const _destinations = [
    _NavDestination(
      icon: Icons.live_tv_outlined,
      selectedIcon: Icons.live_tv,
      label: 'Live TV',
      route: Routes.liveTV,
    ),
    _NavDestination(
      icon: Icons.movie_outlined,
      selectedIcon: Icons.movie,
      label: 'Movies',
      route: Routes.vod,
    ),
    _NavDestination(
      icon: Icons.tv_outlined,
      selectedIcon: Icons.tv,
      label: 'Series',
      route: Routes.series,
    ),
    _NavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: Routes.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Create focus nodes for each navigation destination
    for (var i = 0; i < _destinations.length; i++) {
      _navFocusNodes.add(
        FocusNode(debugLabel: 'TV Nav ${_destinations[i].label}'),
      );
    }
  }

  @override
  void dispose() {
    for (final node in _navFocusNodes) {
      node.dispose();
    }
    _contentFocusNode.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.liveTV)) return 0;
    if (location.startsWith(Routes.vod)) return 1;
    if (location.startsWith(Routes.series)) return 2;
    if (location.startsWith(Routes.settings)) return 3;
    return 0;
  }

  void _onItemSelected(BuildContext context, int index) {
    final destination = _destinations[index];
    context.go(destination.route);
    // Move focus to content area after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocusNode.requestFocus();
    });
  }

  KeyEventResult _handleRailKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final selectedIndex = _calculateSelectedIndex(context);

    // Handle up/down navigation within rail
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (selectedIndex > 0) {
        _navFocusNodes[selectedIndex - 1].requestFocus();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (selectedIndex < _destinations.length - 1) {
        _navFocusNodes[selectedIndex + 1].requestFocus();
        return KeyEventResult.handled;
      }
    }
    // Handle right arrow to move to content
    else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _contentFocusNode.requestFocus();
      setState(() => _railHasFocus = false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return TVNavigationScope(
      onBackPressed: () {
        // Move focus to rail when back is pressed from content
        if (!_railHasFocus) {
          _navFocusNodes[selectedIndex].requestFocus();
          setState(() => _railHasFocus = true);
        } else {
          // Exit app or go to previous screen
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            // Custom focusable navigation rail for TV
            Focus(
              onKeyEvent: _handleRailKeyEvent,
              onFocusChange: (hasFocus) {
                setState(() => _railHasFocus = hasFocus);
              },
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'KYLOS',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Navigation items
                    Expanded(
                      child: ListView.builder(
                        itemCount: _destinations.length,
                        itemBuilder: (context, index) {
                          final destination = _destinations[index];
                          final isSelected = index == selectedIndex;

                          return _TVNavItem(
                            focusNode: _navFocusNodes[index],
                            icon: isSelected
                                ? destination.selectedIcon
                                : destination.icon,
                            label: destination.label,
                            isSelected: isSelected,
                            onSelect: () => _onItemSelected(context, index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content area with focus scope
            Expanded(
              child: FocusScope(
                node: FocusScopeNode(debugLabel: 'TV Content Scope'),
                child: Focus(
                  focusNode: _contentFocusNode,
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;

                    // Handle left arrow to move to rail
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      // Only handle if at the left edge of content
                      final primaryFocus = FocusManager.instance.primaryFocus;
                      if (primaryFocus == _contentFocusNode ||
                          !primaryFocus!.focusInDirection(
                            TraversalDirection.left,
                          )) {
                        _navFocusNodes[selectedIndex].requestFocus();
                        setState(() => _railHasFocus = true);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for navigation destinations.
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}

/// Focusable navigation item for TV rail.
class _TVNavItem extends StatefulWidget {
  const _TVNavItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  State<_TVNavItem> createState() => _TVNavItemState();
}

class _TVNavItemState extends State<_TVNavItem> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onSelect();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = _isFocused
        ? colorScheme.primaryContainer
        : widget.isSelected
            ? colorScheme.secondaryContainer
            : Colors.transparent;

    final iconColor = _isFocused
        ? colorScheme.onPrimaryContainer
        : widget.isSelected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant;

    final textColor = iconColor;

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: _isFocused
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
