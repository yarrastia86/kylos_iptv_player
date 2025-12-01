// Kylos IPTV Player - Secondary Action Button
// Smaller action button for secondary dashboard features.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A smaller action button for secondary dashboard features.
///
/// Used for EPG, Multi-screen, Catch Up, etc.
class SecondaryActionButton extends StatefulWidget {
  const SecondaryActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.focusNode,
  });

  /// The title displayed on the button.
  final String title;

  /// The icon displayed on the button.
  final IconData icon;

  /// Callback when the button is tapped or selected.
  final VoidCallback onTap;

  /// Optional focus node for TV navigation.
  final FocusNode? focusNode;

  @override
  State<SecondaryActionButton> createState() => _SecondaryActionButtonState();
}

class _SecondaryActionButtonState extends State<SecondaryActionButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onTap();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _isFocused
                ? Colors.white.withOpacity(0.2)
                : _isPressed
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? Colors.white.withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: Colors.white.withOpacity(_isFocused ? 1.0 : 0.8),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(_isFocused ? 1.0 : 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
