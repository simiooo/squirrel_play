import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// Dialog for configuring the RAWG API key.
///
/// Allows users to input their API key from rawg.io.
/// The dialog is dismissible and the app works in degraded mode without a key.
///
/// Features:
/// - Focus trapping via FocusTraversalService dialog mode
/// - Auto-focus first element on open
/// - B/Escape to close
class ApiKeyDialog extends StatefulWidget {
  /// Whether this is the first launch (can't be dismissed without key).
  final bool isFirstLaunch;

  const ApiKeyDialog({
    super.key,
    this.isFirstLaunch = false,
  });

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();

  /// Shows the API key dialog.
  static Future<String?> show(BuildContext context, {bool isFirstLaunch = false}) {
    final focusNode = FocusManager.instance.primaryFocus;

    // Play open sound
    SoundService.instance.playFocusSelect();

    final result = showDialog<String>(
      context: context,
      barrierDismissible: !isFirstLaunch,
      builder: (context) => ApiKeyDialog(isFirstLaunch: isFirstLaunch),
    );

    // Restore focus when dialog closes
    result.then((_) {
      if (focusNode != null) {
        focusNode.requestFocus();
      }
    });

    return result;
  }
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  final _keyController = TextEditingController();
  final _keyFocusNode = FocusNode();
  final _saveButtonFocusNode = FocusNode();
  final _skipButtonFocusNode = FocusNode();

  bool _isValid = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _keyController.addListener(_validateKey);

    // Auto-focus first element after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _keyFocusNode.dispose();
    _saveButtonFocusNode.dispose();
    _skipButtonFocusNode.dispose();
    super.dispose();
  }

  void _validateKey() {
    final key = _keyController.text.trim();
    // RAWG API keys are 32-character hex strings
    final isValid = key.length == 32 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(key);
    setState(() {
      _isValid = isValid;
    });
  }

  void _save() {
    if (_isValid) {
      SoundService.instance.playFocusSelect();
      Navigator.of(context).pop(_keyController.text.trim());
    }
  }

  void _skip() {
    SoundService.instance.playFocusBack();
    Navigator.of(context).pop(null);
  }

  void _openRawgWebsite() {
    // In a real app, this would use url_launcher
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Visit rawg.io to get your free API key',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(debugLabel: 'ApiKeyDialogKeyboardListener'),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.escape:
              if (!widget.isFirstLaunch) {
                _skip();
              }
              return;
          }
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.large),
            border: Border.all(
              color: AppColors.surfaceElevated,
              width: 1,
            ),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Icon(
                    Icons.key,
                    size: 48,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Configure RAWG API Key',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enter your RAWG API key to fetch game metadata. You can get a free key at rawg.io.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // API Key input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _keyController,
                focusNode: _keyFocusNode,
                obscureText: _isObscured,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your 32-character API key',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
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
                  prefixIcon: const Icon(
                    Icons.vpn_key,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                    child: Icon(
                      _isObscured ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                onSubmitted: (_) => _isValid ? _save() : null,
              ),
            ),

            // Get key link
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GestureDetector(
                onTap: _openRawgWebsite,
                child: Text(
                  'Get your free API key at rawg.io',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            // Degraded mode notice
            if (!widget.isFirstLaunch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withAlpha(128),
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Without an API key, game metadata won\'t be fetched. You can add one later in settings.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!widget.isFirstLaunch) ...[
                    FocusableButton(
                      focusNode: _skipButtonFocusNode,
                      onPressed: _skip,
                      label: 'Skip for now',
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  FocusableButton(
                    focusNode: _saveButtonFocusNode,
                    onPressed: _isValid ? _save : () {},
                    label: 'Save API Key',
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
