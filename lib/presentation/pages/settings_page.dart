import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/core/i18n/locale_cubit.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';

import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/gamepad/gamepad_cubit.dart';
import 'package:squirrel_play/presentation/blocs/settings/settings_bloc.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/focusable_list_tile.dart';
import 'package:squirrel_play/presentation/widgets/focusable_slider.dart';
import 'package:squirrel_play/presentation/widgets/focusable_switch.dart';
import 'package:squirrel_play/presentation/widgets/focusable_text_field.dart';

/// The settings page of the application.
///
/// Features:
/// - Language selection (English/Chinese)
/// - API key configuration (RAWG)
/// - Sound settings (volume, mute)
/// - About section (version, credits)
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc()..add(const SettingsLoadRequested()),
      child: const _SettingsPageContent(),
    );
  }
}

class _SettingsPageContent extends StatefulWidget {
  const _SettingsPageContent();

  @override
  State<_SettingsPageContent> createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<_SettingsPageContent> {
  late final TextEditingController _apiKeyController;
  late final FocusNode _backButtonFocusNode;
  late final FocusNode _apiKeyFocusNode;
  late final FocusNode _saveKeyFocusNode;
  late final FocusNode _clearKeyFocusNode;
  late final FocusNode _testSoundFocusNode;
  late final FocusNode _testGamepadFocusNode;
  // New focus nodes for Sprint 13
  late final FocusNode _englishLanguageFocusNode;
  late final FocusNode _chineseLanguageFocusNode;
  late final FocusNode _muteSwitchFocusNode;
  late final FocusNode _volumeSliderFocusNode;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _backButtonFocusNode = FocusNode(debugLabel: 'SettingsBackButton');
    _apiKeyFocusNode = FocusNode(debugLabel: 'ApiKeyInput');
    _saveKeyFocusNode = FocusNode(debugLabel: 'SaveKeyButton');
    _clearKeyFocusNode = FocusNode(debugLabel: 'ClearKeyButton');
    _testSoundFocusNode = FocusNode(debugLabel: 'TestSoundButton');
    _testGamepadFocusNode = FocusNode(debugLabel: 'TestGamepadButton');
    // New focus nodes for Sprint 13
    _englishLanguageFocusNode = FocusNode(debugLabel: 'EnglishLanguageOption');
    _chineseLanguageFocusNode = FocusNode(debugLabel: 'ChineseLanguageOption');
    _muteSwitchFocusNode = FocusNode(debugLabel: 'MuteSwitch');
    _volumeSliderFocusNode = FocusNode(debugLabel: 'VolumeSlider');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _backButtonFocusNode.dispose();
    _apiKeyFocusNode.dispose();
    _saveKeyFocusNode.dispose();
    _clearKeyFocusNode.dispose();
    _testSoundFocusNode.dispose();
    _testGamepadFocusNode.dispose();
    _englishLanguageFocusNode.dispose();
    _chineseLanguageFocusNode.dispose();
    _muteSwitchFocusNode.dispose();
    _volumeSliderFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    SoundService.instance.playFocusBack();
    context.go('/');
  }

  void _handleSaveApiKey() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      context.read<SettingsBloc>().add(SettingsApiKeySaved(apiKey: apiKey));
      // Also save to ApiKeyService
      // Note: This would need to be injected properly in a real implementation
      SoundService.instance.playFocusSelect();
      _showSnackBar('API Key saved');
    }
  }

  void _handleClearApiKey() {
    _apiKeyController.clear();
    context.read<SettingsBloc>().add(const SettingsApiKeyCleared());
    SoundService.instance.playFocusSelect();
    _showSnackBar('API Key cleared');
  }

  void _handleTestSound() {
    SoundService.instance.playFocusSelect();
  }

  void _handleTestGamepad() {
    SoundService.instance.playFocusSelect();
    context.go('/settings/gamepad-test');
  }

  void _handleLanguageChanged(String languageCode) {
    context.read<LocaleCubit>().setLocale(Locale(languageCode));
    context.read<SettingsBloc>().add(SettingsLanguageChanged(languageCode: languageCode));
    SoundService.instance.playFocusSelect();
  }

  void _handleVolumeChanged(double volume) {
    SoundService.instance.volume = volume;
    context.read<SettingsBloc>().add(SettingsVolumeChanged(volume: volume));
  }

  void _handleMuteToggled(SettingsLoaded state) {
    final newMuteState = !state.isMuted;
    context.read<SettingsBloc>().add(const SettingsMuteToggled());
    SoundService.instance.isMuted = newMuteState;
    if (!newMuteState) {
      // Only play sound when unmuting
      SoundService.instance.playFocusSelect();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              _handleBack();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  FocusableButton(
                    focusNode: _backButtonFocusNode,
                    label: l10n?.buttonBack ?? 'Back',
                    icon: Icons.arrow_back,
                    onPressed: _handleBack,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    l10n?.pageSettings ?? 'Settings',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Settings content
            Expanded(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  if (state is SettingsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is SettingsError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    );
                  }

                  if (state is SettingsLoaded) {
                    return _buildSettingsContent(context, state, l10n);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language Section
          _buildSectionTitle(context, l10n?.settingsLanguage ?? 'Language'),
          const SizedBox(height: AppSpacing.md),
          _buildLanguageSelector(context, state, l10n),
          const SizedBox(height: AppSpacing.xxl),

          // API Key Section
          _buildSectionTitle(context, l10n?.settingsApiKey ?? 'API Key'),
          const SizedBox(height: AppSpacing.md),
          _buildApiKeySection(context, state, l10n),
          const SizedBox(height: AppSpacing.xxl),

          // Sound Section
          _buildSectionTitle(context, l10n?.settingsSound ?? 'Sound'),
          const SizedBox(height: AppSpacing.md),
          _buildSoundSection(context, state, l10n),
          const SizedBox(height: AppSpacing.xxl),

          // Gamepad Section
          _buildSectionTitle(context, l10n?.settingsGamepad ?? 'Gamepad'),
          const SizedBox(height: AppSpacing.md),
          _buildGamepadSection(context, state, l10n),
          const SizedBox(height: AppSpacing.xxl),

          // About Section
          _buildSectionTitle(context, l10n?.settingsAbout ?? 'About'),
          const SizedBox(height: AppSpacing.md),
          _buildAboutSection(context, state, l10n),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            context,
            l10n?.settingsLanguageEnglish ?? 'English',
            'en',
            state.languageCode == 'en',
            _englishLanguageFocusNode,
            l10n?.settingsLanguageEnglishLabel ?? 'English language option',
          ),
          const Divider(color: AppColors.textMuted),
          _buildLanguageOption(
            context,
            l10n?.settingsLanguageChinese ?? 'Chinese (Simplified)',
            'zh',
            state.languageCode == 'zh',
            _chineseLanguageFocusNode,
            l10n?.settingsLanguageChineseLabel ?? 'Chinese language option',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    String languageCode,
    bool isSelected,
    FocusNode focusNode,
    String? semanticLabel,
  ) {
    return FocusableListTile(
      focusNode: focusNode,
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primaryAccent)
          : null,
      onTap: () => _handleLanguageChanged(languageCode),
      semanticLabel: semanticLabel,
    );
  }

  Widget _buildApiKeySection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API Status indicator
          Row(
            children: [
              Icon(
                state.isApiConnected ? Icons.check_circle : Icons.warning,
                color: state.isApiConnected
                    ? AppColors.secondaryAccent
                    : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                state.isApiConnected
                    ? (l10n?.settingsApiKeyConnected ?? 'API Connected')
                    : (l10n?.settingsApiKeyDegraded ?? 'Degraded Mode'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: state.isApiConnected
                      ? AppColors.secondaryAccent
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // API Key input with focus styling
          FocusableTextField(
            focusNode: _apiKeyFocusNode,
            controller: _apiKeyController,
            labelText: l10n?.settingsApiKeyLabel ?? 'RAWG API Key',
            hintText: l10n?.settingsApiKeyPlaceholder ?? 'Enter your RAWG API key',
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // Help text
          Text(
            l10n?.settingsApiKeyHelp ?? 'Get your free API key from rawg.io',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              FocusableButton(
                focusNode: _saveKeyFocusNode,
                label: l10n?.buttonSave ?? 'Save',
                isPrimary: true,
                onPressed: _handleSaveApiKey,
              ),
              const SizedBox(width: AppSpacing.md),
              FocusableButton(
                focusNode: _clearKeyFocusNode,
                label: l10n?.buttonCancel ?? 'Clear',
                onPressed: _handleClearApiKey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume label
          Text(
            l10n?.settingsSoundVolume ?? 'Master Volume',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Volume slider with focus styling and gamepad control
          FocusableSlider(
            focusNode: _volumeSliderFocusNode,
            value: state.volume,
            onChanged: _handleVolumeChanged,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: '${(state.volume * 100).round()}%',
            step: 0.1,
            semanticLabel: l10n?.settingsSoundVolumeHint ?? 'Volume slider - use left and right to adjust',
            activeColor: AppColors.primaryAccent,
          ),
          const SizedBox(height: AppSpacing.md),

          // Mute toggle with focus styling
          FocusableSwitch(
            focusNode: _muteSwitchFocusNode,
            value: state.isMuted,
            onChanged: (_) => _handleMuteToggled(state),
            title: Text(
              l10n?.settingsSoundMute ?? 'Mute',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            semanticLabel: l10n?.settingsSoundMuteHint ?? 'Mute toggle - press to toggle mute on or off',
          ),
          const SizedBox(height: AppSpacing.md),

          // Test sound button
          FocusableButton(
            focusNode: _testSoundFocusNode,
            label: l10n?.settingsSoundTest ?? 'Test Sound',
            onPressed: _handleTestSound,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.settingsAboutVersion('1.0.0') ?? 'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n?.settingsAboutCredits ?? 'Powered by RAWG API',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamepadSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status preview
          BlocBuilder<GamepadCubit, GamepadState>(
            builder: (context, gamepadState) {
              final isConnected = gamepadState is GamepadConnected;
              return Row(
                children: [
                  Icon(
                    isConnected
                        ? Icons.videogame_asset
                        : Icons.videogame_asset_off,
                    color: isConnected
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isConnected
                        ? (l10n?.settingsGamepadConnected ?? 'Gamepad: Connected')
                        : (l10n?.settingsGamepadDisconnected ?? 'Gamepad: Not connected'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isConnected
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Test Gamepad button
          FocusableButton(
            focusNode: _testGamepadFocusNode,
            label: l10n?.settingsGamepadTest ?? 'Test Gamepad',
            icon: Icons.gamepad,
            onPressed: _handleTestGamepad,
          ),
        ],
      ),
    );
  }
}