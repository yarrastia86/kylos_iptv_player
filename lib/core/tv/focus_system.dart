// Kylos IPTV Player - TV Focus System
// Focus management utilities for TV/D-pad navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that makes its child focusable for TV navigation.
///
/// Provides visual feedback when focused and handles D-pad select events.
/// Use this for any interactive element on TV platforms.
class FocusableWidget extends StatefulWidget {
  const FocusableWidget({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocusChange,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusNode,
    this.focusedDecoration,
    this.unfocusedDecoration,
    this.scaleOnFocus = 1.05,
    this.animationDuration = const Duration(milliseconds: 150),
    this.borderRadius = 8.0,
    this.focusBorderWidth = 3.0,
  });

  /// The child widget to make focusable.
  final Widget child;

  /// Callback invoked when the select/enter key is pressed.
  final VoidCallback? onSelect;

  /// Callback invoked when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether this widget should request focus on first build.
  final bool autofocus;

  /// Whether this widget can receive focus.
  final bool canRequestFocus;

  /// External focus node (optional).
  final FocusNode? focusNode;

  /// Decoration when focused (optional, uses default if null).
  final BoxDecoration? focusedDecoration;

  /// Decoration when unfocused (optional).
  final BoxDecoration? unfocusedDecoration;

  /// Scale factor when focused (1.0 = no scale).
  final double scaleOnFocus;

  /// Duration of focus animations.
  final Duration animationDuration;

  /// Border radius for default focus decoration.
  final double borderRadius;

  /// Width of the focus border.
  final double focusBorderWidth;

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _ownsNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnFocus,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(FocusableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsNode) {
        _focusNode.dispose();
      }
      _ownsNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isFocused) {
      setState(() => _isFocused = hasFocus);
      widget.onFocusChange?.call(hasFocus);

      if (hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle select/enter key
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  BoxDecoration _defaultFocusedDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      border: Border.all(
        color: colorScheme.primary,
        width: widget.focusBorderWidth,
      ),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.canRequestFocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: widget.animationDuration,
                decoration: _isFocused
                    ? widget.focusedDecoration ??
                        _defaultFocusedDecoration(context)
                    : widget.unfocusedDecoration,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A scope that provides TV navigation context and key handling.
///
/// Wrap your TV screens with this widget to enable proper back button
/// handling and media key support.
class TVNavigationScope extends StatelessWidget {
  const TVNavigationScope({
    super.key,
    required this.child,
    this.onBackPressed,
    this.onPlayPause,
    this.onFastForward,
    this.onRewind,
    this.onChannelUp,
    this.onChannelDown,
    this.onInfo,
  });

  /// The child widget tree.
  final Widget child;

  /// Callback when back button is pressed.
  final VoidCallback? onBackPressed;

  /// Callback when play/pause is pressed.
  final VoidCallback? onPlayPause;

  /// Callback when fast forward is pressed.
  final VoidCallback? onFastForward;

  /// Callback when rewind is pressed.
  final VoidCallback? onRewind;

  /// Callback when channel up is pressed.
  final VoidCallback? onChannelUp;

  /// Callback when channel down is pressed.
  final VoidCallback? onChannelDown;

  /// Callback when info button is pressed.
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _tvShortcuts,
      child: Actions(
        actions: {
          TVBackIntent: CallbackAction<TVBackIntent>(
            onInvoke: (_) {
              onBackPressed?.call();
              return null;
            },
          ),
          TVPlayPauseIntent: CallbackAction<TVPlayPauseIntent>(
            onInvoke: (_) {
              onPlayPause?.call();
              return null;
            },
          ),
          TVFastForwardIntent: CallbackAction<TVFastForwardIntent>(
            onInvoke: (_) {
              onFastForward?.call();
              return null;
            },
          ),
          TVRewindIntent: CallbackAction<TVRewindIntent>(
            onInvoke: (_) {
              onRewind?.call();
              return null;
            },
          ),
          TVChannelUpIntent: CallbackAction<TVChannelUpIntent>(
            onInvoke: (_) {
              onChannelUp?.call();
              return null;
            },
          ),
          TVChannelDownIntent: CallbackAction<TVChannelDownIntent>(
            onInvoke: (_) {
              onChannelDown?.call();
              return null;
            },
          ),
          TVInfoIntent: CallbackAction<TVInfoIntent>(
            onInvoke: (_) {
              onInfo?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }

  static final _tvShortcuts = <ShortcutActivator, Intent>{
    // Back button
    const SingleActivator(LogicalKeyboardKey.goBack): const TVBackIntent(),
    const SingleActivator(LogicalKeyboardKey.escape): const TVBackIntent(),
    const SingleActivator(LogicalKeyboardKey.browserBack): const TVBackIntent(),

    // Media keys
    const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
        const TVPlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPlay):
        const TVPlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPause):
        const TVPlayPauseIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaFastForward):
        const TVFastForwardIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaRewind):
        const TVRewindIntent(),

    // Channel up/down (Page Up/Down on some remotes)
    const SingleActivator(LogicalKeyboardKey.channelUp):
        const TVChannelUpIntent(),
    const SingleActivator(LogicalKeyboardKey.pageUp): const TVChannelUpIntent(),
    const SingleActivator(LogicalKeyboardKey.channelDown):
        const TVChannelDownIntent(),
    const SingleActivator(LogicalKeyboardKey.pageDown):
        const TVChannelDownIntent(),

    // Info button
    const SingleActivator(LogicalKeyboardKey.info): const TVInfoIntent(),
    const SingleActivator(LogicalKeyboardKey.f1): const TVInfoIntent(),
  };
}

// Custom intents for TV actions
class TVBackIntent extends Intent {
  const TVBackIntent();
}

class TVPlayPauseIntent extends Intent {
  const TVPlayPauseIntent();
}

class TVFastForwardIntent extends Intent {
  const TVFastForwardIntent();
}

class TVRewindIntent extends Intent {
  const TVRewindIntent();
}

class TVChannelUpIntent extends Intent {
  const TVChannelUpIntent();
}

class TVChannelDownIntent extends Intent {
  const TVChannelDownIntent();
}

class TVInfoIntent extends Intent {
  const TVInfoIntent();
}

/// Extension to help with focus traversal.
extension FocusNodeExtensions on FocusNode {
  /// Request focus if not already focused.
  void requestFocusIfNeeded() {
    if (!hasFocus) {
      requestFocus();
    }
  }
}

/// A helper widget for managing initial focus in a TV screen.
///
/// Use this to ensure a specific widget gets initial focus when
/// the screen is first displayed.
class TVInitialFocus extends StatefulWidget {
  const TVInitialFocus({
    super.key,
    required this.child,
    this.focusNode,
  });

  /// The child widget that should receive initial focus.
  final Widget child;

  /// Optional focus node to use.
  final FocusNode? focusNode;

  @override
  State<TVInitialFocus> createState() => _TVInitialFocusState();
}

class _TVInitialFocusState extends State<TVInitialFocus> {
  late FocusNode _focusNode;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _ownsNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();

    // Request focus after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
