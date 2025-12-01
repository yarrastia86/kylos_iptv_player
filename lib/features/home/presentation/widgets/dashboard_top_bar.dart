// Kylos IPTV Player - Dashboard Top Bar
// Top bar widget with logo, time/date, and action buttons.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';

/// Top bar for the dashboard screen.
///
/// Displays the app logo, current time/date, and action icons.
class DashboardTopBar extends StatefulWidget {
  const DashboardTopBar({
    super.key,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onSettingsTap,
    this.onPowerTap,
    this.compact = false,
  });

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onPowerTap;
  final bool compact;

  @override
  State<DashboardTopBar> createState() => _DashboardTopBarState();
}

class _DashboardTopBarState extends State<DashboardTopBar> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? KylosSpacing.m : KylosSpacing.xl,
        vertical: widget.compact ? KylosSpacing.s : KylosSpacing.m,
      ),
      child: Row(
        children: [
          // Logo / App name
          _buildLogo(),

          const Spacer(),

          // Time and Date (hide on very compact screens)
          if (!widget.compact) _buildTimeDate(timeFormat, dateFormat),

          const Spacer(),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon with gradient
        Container(
          width: KylosDimensions.logoSize,
          height: KylosDimensions.logoSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: KylosColors.liveTvGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(KylosRadius.m),
            boxShadow: [
              BoxShadow(
                color: KylosColors.liveTvGlow.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: KylosSpacing.s),
        // Brand text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('KYLOS', style: KylosTextStyles.brandName),
            Text('IPTV PLAYER', style: KylosTextStyles.brandTagline),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeDate(DateFormat timeFormat, DateFormat dateFormat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeFormat.format(_currentTime),
          style: KylosTextStyles.time,
        ),
        const SizedBox(height: 2),
        Text(
          dateFormat.format(_currentTime),
          style: KylosTextStyles.date,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TopBarIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          onTap: widget.onNotificationsTap ?? () {},
        ),
        SizedBox(width: KylosSpacing.xs),
        _TopBarIconButton(
          icon: Icons.person_outline,
          tooltip: 'Profile',
          onTap: widget.onProfileTap ?? () {},
        ),
        SizedBox(width: KylosSpacing.xs),
        _TopBarIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: widget.onSettingsTap ?? () {},
        ),
        SizedBox(width: KylosSpacing.xs),
        _TopBarIconButton(
          icon: Icons.power_settings_new,
          tooltip: 'Exit',
          onTap: widget.onPowerTap ?? () {},
        ),
      ],
    );
  }
}

/// Individual action button in the top bar.
class _TopBarIconButton extends StatefulWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<_TopBarIconButton> {
  bool _isFocused = false;
  bool _isHovered = false;
  bool _isPressed = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onTap();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool get _isActive => _isFocused || _isHovered;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Tooltip(
            message: widget.tooltip,
            child: AnimatedContainer(
              duration: KylosDurations.fast,
              curve: Curves.easeOutCubic,
              width: KylosDimensions.topBarButtonSize,
              height: KylosDimensions.topBarButtonSize,
              decoration: BoxDecoration(
                color: _isActive
                    ? KylosColors.buttonFocused
                    : _isPressed
                        ? KylosColors.surfaceLight
                        : KylosColors.buttonBackground,
                borderRadius: BorderRadius.circular(KylosRadius.m),
                border: _isFocused
                    ? Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: _isActive
                      ? KylosColors.textPrimary
                      : KylosColors.textSecondary,
                  size: KylosDimensions.topBarIconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
