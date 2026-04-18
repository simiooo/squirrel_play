import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// A reusable text field with visible focus styling and sound feedback.
///
/// Features:
/// - 2px [AppColors.primaryAccent] border when focused
/// - [AppColors.surfaceElevated] background when focused
/// - 200ms focus-in / 150ms focus-out animations
/// - [SoundService.playFocusMove] on focus gain
class FocusableTextField extends StatefulWidget {
  /// The focus node for this text field.
  final FocusNode focusNode;

  /// Optional text editing controller.
  final TextEditingController? controller;

  /// Optional label text for the input decoration.
  final String? labelText;

  /// Optional hint text for the input decoration.
  final String? hintText;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Error text to display below the field.
  final String? errorText;

  /// Creates a focusable text field.
  const FocusableTextField({
    super.key,
    required this.focusNode,
    this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
  });

  @override
  State<FocusableTextField> createState() => _FocusableTextFieldState();
}

class _FocusableTextFieldState extends State<FocusableTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    _isFocused = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant FocusableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
      _updateFocusState();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final hadFocus = _isFocused;
    _updateFocusState();
    if (_isFocused && !hadFocus) {
      SoundService.instance.playFocusMove();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _updateFocusState() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _isFocused
          ? AppAnimationDurations.focusIn
          : AppAnimationDurations.focusOut,
      curve: _isFocused
          ? AppAnimationCurves.focusIn
          : AppAnimationCurves.focusOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: _isFocused
            ? Border.all(
                color: AppColors.primaryAccent,
                width: 2,
              )
            : null,
        color: _isFocused ? AppColors.surfaceElevated : Colors.transparent,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(
              color: AppColors.primaryAccent,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        style: const TextStyle(color: AppColors.textPrimary),
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
      ),
    );
  }
}