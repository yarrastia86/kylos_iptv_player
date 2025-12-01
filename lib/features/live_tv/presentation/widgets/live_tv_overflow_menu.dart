// Kylos IPTV Player - Live TV Overflow Menu
// Floating overflow menu panel with navigation and actions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/live_tv/presentation/widgets/live_tv_overflow_menu_item.dart';

/// Menu item data model for the overflow menu.
class OverflowMenuItem {
  const OverflowMenuItem({
    required this.id,
    required this.icon,
    required this.label,
  });

  /// Unique identifier for the menu item.
  final String id;

  /// Icon displayed for the menu item.
  final IconData icon;

  /// Text label for the menu item.
  final String label;
}

/// Callback type for menu item selection.
typedef OnMenuItemSelected = void Function(String itemId);

/// A floating overflow menu panel for Live TV screens.
///
/// Displays a list of menu options in a floating panel with
/// smooth animations and TV/remote navigation support.
class LiveTvOverflowMenu extends StatefulWidget {
  const LiveTvOverflowMenu({
    super.key,
    required this.onItemSelected,
    required this.onDismiss,
    this.anchorPosition,
  });

  /// Callback when a menu item is selected.
  final OnMenuItemSelected onItemSelected;

  /// Callback when the menu should be dismissed.
  final VoidCallback onDismiss;

  /// Optional anchor position for the menu (top-right by default).
  final Offset? anchorPosition;

  /// Standard menu items for the Live TV overflow menu.
  static const List<OverflowMenuItem> standardItems = [
    OverflowMenuItem(
      id: 'home',
      icon: Icons.home_outlined,
      label: 'Home',
    ),
    OverflowMenuItem(
      id: 'refresh_content',
      icon: Icons.refresh,
      label: 'Refresh Channels, Movies and Series',
    ),
    OverflowMenuItem(
      id: 'refresh_epg',
      icon: Icons.calendar_today_outlined,
      label: 'Refresh TV Guide',
    ),
    OverflowMenuItem(
      id: 'sort',
      icon: Icons.sort,
      label: 'Sort',
    ),
    OverflowMenuItem(
      id: 'settings',
      icon: Icons.settings_outlined,
      label: 'Settings',
    ),
    OverflowMenuItem(
      id: 'logout',
      icon: Icons.logout,
      label: 'Logout',
    ),
  ];

  @override
  State<LiveTvOverflowMenu> createState() => _LiveTvOverflowMenuState();
}

class _LiveTvOverflowMenuState extends State<LiveTvOverflowMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final FocusNode _menuFocusNode;

  @override
  void initState() {
    super.initState();

    _menuFocusNode = FocusNode(debugLabel: 'OverflowMenu');

    _animationController = AnimationController(
      duration: KylosDurations.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Request focus after animation starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _menuFocusNode.dispose();
    super.dispose();
  }

  Future<void> _dismissWithAnimation() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  void _handleItemTap(String itemId) {
    widget.onItemSelected(itemId);
    _dismissWithAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dismissWithAnimation(),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black54,
        child: KeyboardListener(
          focusNode: _menuFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              // Handle Back/Escape to dismiss
              if (event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.browserBack) {
                _dismissWithAnimation();
              }
            }
          },
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 60,
                right: KylosSpacing.m,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.topRight,
                  child: _buildMenuPanel(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: KylosColors.surfaceDark,
        borderRadius: BorderRadius.circular(KylosRadius.l),
        border: Border.all(
          color: KylosColors.buttonBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: KylosColors.liveTvGlow.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KylosRadius.l),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),

              // Divider
              Container(
                height: 1,
                color: KylosColors.buttonBorder,
              ),

              // Menu items - scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: KylosSpacing.s,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: LiveTvOverflowMenu.standardItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      // Add divider before logout
                      if (item.id == 'logout') {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KylosSpacing.m,
                                vertical: KylosSpacing.xs,
                              ),
                              child: Container(
                                height: 1,
                                color: KylosColors.buttonBorder,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KylosSpacing.xs,
                              ),
                              child: LiveTvOverflowMenuItem(
                                icon: item.icon,
                                label: item.label,
                                onTap: () => _handleItemTap(item.id),
                              ),
                            ),
                          ],
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KylosSpacing.xs,
                        ),
                        child: LiveTvOverflowMenuItem(
                          icon: item.icon,
                          label: item.label,
                          onTap: () => _handleItemTap(item.id),
                          autofocus: index == 0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(KylosSpacing.m),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KylosColors.liveTvGlow.withOpacity(0.15),
            KylosColors.surfaceDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KylosColors.liveTvGlow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(KylosRadius.s),
            ),
            child: const Icon(
              Icons.menu,
              color: KylosColors.liveTvGlow,
              size: 20,
            ),
          ),
          const SizedBox(width: KylosSpacing.s),
          const Text(
            'Menu',
            style: TextStyle(
              color: KylosColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _dismissWithAnimation(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: KylosColors.surfaceOverlay,
                borderRadius: BorderRadius.circular(KylosRadius.s),
              ),
              child: const Icon(
                Icons.close,
                color: KylosColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the Live TV overflow menu as an overlay.
///
/// Returns the selected menu item ID, or null if dismissed.
Future<String?> showLiveTvOverflowMenu(BuildContext context) async {
  String? selectedItemId;

  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return LiveTvOverflowMenu(
          onItemSelected: (itemId) {
            selectedItemId = itemId;
          },
          onDismiss: () {
            Navigator.of(context).pop();
          },
        );
      },
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );

  return selectedItemId;
}
