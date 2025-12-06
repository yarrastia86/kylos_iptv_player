// Kylos IPTV Player - Promo Code Dialog
// UI for entering and redeeming promotional codes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/home/presentation/kylos_dashboard_theme.dart';
import 'package:kylos_iptv_player/features/monetization/domain/entities/promo_code.dart';
import 'package:kylos_iptv_player/features/monetization/presentation/providers/promo_code_providers.dart';

/// Dialog for entering and redeeming promo codes.
class PromoCodeDialog extends ConsumerStatefulWidget {
  const PromoCodeDialog({super.key});

  /// Show the promo code dialog.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PromoCodeDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends ConsumerState<PromoCodeDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a promo code';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ref.read(promoCodeRepositoryProvider).redeemCode(code);

      if (result is PromoCodeSuccess) {
        setState(() {
          _successMessage = result.message;
          _errorMessage = null;
        });

        // Refresh the Pro status
        ref.invalidate(hasProFromPromoCodeProvider);

        // Close dialog after showing success
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else if (result is PromoCodeError) {
        setState(() {
          _errorMessage = result.message;
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _successMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KylosColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KylosRadius.l),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(KylosSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 48,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: KylosSpacing.l),

              // Title
              Text(
                'Redeem Promo Code',
                style: KylosTvTextStyles.sectionHeader.copyWith(
                  color: KylosColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.s),

              // Description
              Text(
                'Enter your promo code to unlock premium features or ad-free access.',
                style: KylosTvTextStyles.body.copyWith(
                  color: KylosColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KylosSpacing.l),

              // Code input
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: KylosColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'ENTER CODE',
                  hintStyle: TextStyle(
                    color: KylosColors.textMuted,
                    letterSpacing: 2,
                  ),
                  filled: true,
                  fillColor: KylosColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KylosRadius.m),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KylosRadius.m),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD700),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => _redeemCode(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: KylosSpacing.m),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(KylosSpacing.s),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(KylosRadius.s),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(KylosSpacing.s),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(KylosRadius.s),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: KylosSpacing.l),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: KylosTvTextStyles.button.copyWith(
                          color: KylosColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KylosSpacing.m),
                  // Redeem button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _redeemCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KylosRadius.m),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Redeem',
                              style: KylosTvTextStyles.button.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact button to show the promo code dialog.
class PromoCodeButton extends StatelessWidget {
  const PromoCodeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => PromoCodeDialog.show(context),
      icon: const Icon(Icons.card_giftcard_rounded, size: 18),
      label: const Text('Have a promo code?'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFFFD700),
      ),
    );
  }
}
