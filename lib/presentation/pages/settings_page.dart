import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/core/i18n/locale_cubit.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/data/services/system_power_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/gamepad/gamepad_cubit.dart';
import 'package:squirrel_play/presentation/blocs/settings/settings_bloc.dart';
import 'package:squirrel_play/presentation/widgets/error_localizer.dart';
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
/// - Display settings (fullscreen)
/// - System power actions (lock, sleep, reboot, shutdown)
/// - System volume control
/// - About section with system info entry
///
/// Layout is responsive:
/// - Compact/Medium (< 1024px): Single column, stacked sections
/// - Expanded/Large (>= 1024px): Two-column grid for related sections
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
  late final FocusNode _englishLanguageFocusNode;
  late final FocusNode _chineseLanguageFocusNode;
  late final FocusNode _muteSwitchFocusNode;
  late final FocusNode _volumeSliderFocusNode;
  // New focus nodes for Sprint 13
  late final FocusNode _fullscreenSwitchFocusNode;
  late final FocusNode _lockButtonFocusNode;
  late final FocusNode _sleepButtonFocusNode;
  late final FocusNode _rebootButtonFocusNode;
  late final FocusNode _shutdownButtonFocusNode;
  late final FocusNode _systemInfoButtonFocusNode;
  late final FocusNode _networkInterfacesButtonFocusNode;

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
    _englishLanguageFocusNode = FocusNode(debugLabel: 'EnglishLanguageOption');
    _chineseLanguageFocusNode = FocusNode(debugLabel: 'ChineseLanguageOption');
    _muteSwitchFocusNode = FocusNode(debugLabel: 'MuteSwitch');
    _volumeSliderFocusNode = FocusNode(debugLabel: 'VolumeSlider');
    _fullscreenSwitchFocusNode = FocusNode(debugLabel: 'FullscreenSwitch');
    _lockButtonFocusNode = FocusNode(debugLabel: 'LockButton');
    _sleepButtonFocusNode = FocusNode(debugLabel: 'SleepButton');
    _rebootButtonFocusNode = FocusNode(debugLabel: 'RebootButton');
    _shutdownButtonFocusNode = FocusNode(debugLabel: 'ShutdownButton');
    _systemInfoButtonFocusNode = FocusNode(debugLabel: 'SystemInfoButton');
    _networkInterfacesButtonFocusNode = FocusNode(debugLabel: 'NetworkInterfacesButton');
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
    _fullscreenSwitchFocusNode.dispose();
    _lockButtonFocusNode.dispose();
    _sleepButtonFocusNode.dispose();
    _rebootButtonFocusNode.dispose();
    _shutdownButtonFocusNode.dispose();
    _systemInfoButtonFocusNode.dispose();
    _networkInterfacesButtonFocusNode.dispose();
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

  void _handleSystemVolumeChanged(double volume) {
    context.read<SettingsBloc>().add(SettingsSystemVolumeChanged(volume: volume));
  }

  void _handleSystemMuteToggled(SettingsLoaded state) {
    context.read<SettingsBloc>().add(const SettingsSystemMuteToggled());
    if (!state.isSystemMuted) {
      SoundService.instance.playFocusSelect();
    }
  }

  void _handleFullscreenToggled() {
    context.read<SettingsBloc>().add(const SettingsFullscreenToggled());
    SoundService.instance.playFocusSelect();
  }

  Future<void> _handlePowerAction(
    Future<PowerActionResult> Function() action,
    String actionName,
  ) async {
    SoundService.instance.playFocusSelect();
    final result = await action();
    if (mounted) {
      if (result.success) {
        _showSnackBar('$actionName initiated');
      } else {
        _showSnackBar(result.error ?? '$actionName failed');
      }
    }
  }

  void _handleSystemInfo() {
    SoundService.instance.playPageTransition();
    context.go('/settings/system-info');
  }

  void _handleNetworkInterfaces() {
    SoundService.instance.playPageTransition();
    context.go('/settings/network-interfaces');
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
                        localizeError(
                          l10n,
                          state.localizationKey ?? '',
                          details: state.details,
                        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = Breakpoints.getBreakpoint(constraints.maxWidth);
        final isWide = breakpoint == ResponsiveLayout.expanded ||
            breakpoint == ResponsiveLayout.large;

        final horizontalPadding = switch (breakpoint) {
          ResponsiveLayout.compact => AppSpacing.lg,
          ResponsiveLayout.medium => AppSpacing.xl,
          ResponsiveLayout.expanded => AppSpacing.xxl,
          ResponsiveLayout.large => AppSpacing.xxxl,
        };

        final sectionGap = switch (breakpoint) {
          ResponsiveLayout.compact => AppSpacing.xl,
          ResponsiveLayout.medium => AppSpacing.xxl,
          ResponsiveLayout.expanded => AppSpacing.xxl,
          ResponsiveLayout.large => AppSpacing.xxxl,
        };

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding)
              .copyWith(bottom: horizontalPadding),
          child: isWide
              ? _buildWideLayout(context, state, l10n, sectionGap)
              : _buildNarrowLayout(context, state, l10n, sectionGap),
        );
      },
    );
  }

  /// Narrow layout: single column, stacked sections.
  Widget _buildNarrowLayout(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
    double sectionGap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsSectionCard(
          title: l10n?.settingsLanguage ?? 'Language',
          child: _buildLanguageSelector(context, state, l10n),
        ),
        SizedBox(height: sectionGap),
        _SettingsSectionCard(
          title: l10n?.settingsApiKey ?? 'API Key',
          child: _buildApiKeySection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),
        _SettingsSectionCard(
          title: l10n?.settingsDisplay ?? 'Display',
          child: _buildDisplaySection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),
        _SettingsSectionCard(
          title: l10n?.settingsSound ?? 'Sound',
          child: _buildSoundSection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),
        _SettingsSectionCard(
          title: l10n?.settingsGamepad ?? 'Gamepad',
          child: _buildGamepadSection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),
        _SettingsSectionCard(
          title: l10n?.settingsSystem ?? 'System',
          child: _buildSystemSection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),
        _SettingsSectionCard(
          title: l10n?.settingsAbout ?? 'About',
          child: _buildAboutSection(context, state, l10n),
        ),
      ],
    );
  }

  /// Wide layout: two-column grid for related sections.
  ///
  /// Focus order follows natural reading direction (left-to-right,
  /// top-to-bottom) to maintain intuitive gamepad navigation.
  Widget _buildWideLayout(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
    double sectionGap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Language | Display
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SettingsSectionCard(
                title: l10n?.settingsLanguage ?? 'Language',
                child: _buildLanguageSelector(context, state, l10n),
              ),
            ),
            SizedBox(width: sectionGap),
            Expanded(
              child: _SettingsSectionCard(
                title: l10n?.settingsDisplay ?? 'Display',
                child: _buildDisplaySection(context, state, l10n),
              ),
            ),
          ],
        ),
        SizedBox(height: sectionGap),

        // Row 2: API Key (full width for comfortable input)
        _SettingsSectionCard(
          title: l10n?.settingsApiKey ?? 'API Key',
          child: _buildApiKeySection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),

        // Row 3: Sound | Gamepad
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SettingsSectionCard(
                title: l10n?.settingsSound ?? 'Sound',
                child: _buildSoundSection(context, state, l10n),
              ),
            ),
            SizedBox(width: sectionGap),
            Expanded(
              child: _SettingsSectionCard(
                title: l10n?.settingsGamepad ?? 'Gamepad',
                child: _buildGamepadSection(context, state, l10n),
              ),
            ),
          ],
        ),
        SizedBox(height: sectionGap),

        // Row 4: System (full width for button row)
        _SettingsSectionCard(
          title: l10n?.settingsSystem ?? 'System',
          child: _buildSystemSection(context, state, l10n),
        ),
        SizedBox(height: sectionGap),

        // Row 5: About (full width for list tiles)
        _SettingsSectionCard(
          title: l10n?.settingsAbout ?? 'About',
          child: _buildAboutSection(context, state, l10n),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        _buildLanguageOption(
          context,
          l10n?.settingsLanguageEnglish ?? 'English',
          'en',
          state.languageCode == 'en',
          _englishLanguageFocusNode,
          l10n?.settingsLanguageEnglishLabel ?? 'English language option',
        ),
        const Divider(color: AppColors.textMuted, height: 1),
        _buildLanguageOption(
          context,
          l10n?.settingsLanguageChinese ?? 'Chinese (Simplified)',
          'zh',
          state.languageCode == 'zh',
          _chineseLanguageFocusNode,
          l10n?.settingsLanguageChineseLabel ?? 'Chinese language option',
        ),
      ],
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
    return Column(
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
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            FocusableButton(
              focusNode: _saveKeyFocusNode,
              label: l10n?.buttonSave ?? 'Save',
              isPrimary: true,
              onPressed: _handleSaveApiKey,
            ),
            FocusableButton(
              focusNode: _clearKeyFocusNode,
              label: l10n?.buttonCancel ?? 'Clear',
              onPressed: _handleClearApiKey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplaySection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return FocusableSwitch(
      focusNode: _fullscreenSwitchFocusNode,
      value: state.isFullscreen,
      onChanged: (_) => _handleFullscreenToggled(),
      title: Text(
        l10n?.settingsFullscreen ?? 'Fullscreen',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      semanticLabel:
          l10n?.settingsFullscreenHint ?? 'Toggle fullscreen mode',
    );
  }

  Widget _buildSystemSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    final powerService = getIt<SystemPowerService>();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        FocusableButton(
          focusNode: _lockButtonFocusNode,
          label: l10n?.settingsLock ?? 'Lock',
          icon: Icons.lock,
          onPressed: () => _handlePowerAction(
            powerService.lock,
            l10n?.settingsLock ?? 'Lock',
          ),
        ),
        FocusableButton(
          focusNode: _sleepButtonFocusNode,
          label: l10n?.settingsSleep ?? 'Sleep',
          icon: Icons.bedtime,
          onPressed: () => _handlePowerAction(
            powerService.suspend,
            l10n?.settingsSleep ?? 'Sleep',
          ),
        ),
        FocusableButton(
          focusNode: _rebootButtonFocusNode,
          label: l10n?.settingsReboot ?? 'Reboot',
          icon: Icons.restart_alt,
          onPressed: () => _handlePowerAction(
            powerService.reboot,
            l10n?.settingsReboot ?? 'Reboot',
          ),
        ),
        FocusableButton(
          focusNode: _shutdownButtonFocusNode,
          label: l10n?.settingsShutdown ?? 'Shutdown',
          icon: Icons.power_settings_new,
          onPressed: () => _handlePowerAction(
            powerService.powerOff,
            l10n?.settingsShutdown ?? 'Shutdown',
          ),
        ),
      ],
    );
  }

  Widget _buildSoundSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Volume label
        Text(
          l10n?.settingsSystemVolume ?? 'System Volume',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Volume slider with focus styling and gamepad control
        FocusableSlider(
          focusNode: _volumeSliderFocusNode,
          value: state.systemVolume,
          onChanged: _handleSystemVolumeChanged,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: '${(state.systemVolume * 100).round()}%',
          step: 0.1,
          semanticLabel: l10n?.settingsSystemVolumeHint ??
              'System volume slider - use left and right to adjust',
          activeColor: AppColors.primaryAccent,
        ),
        const SizedBox(height: AppSpacing.md),

        // Mute toggle with focus styling
        FocusableSwitch(
          focusNode: _muteSwitchFocusNode,
          value: state.isSystemMuted,
          onChanged: (_) => _handleSystemMuteToggled(state),
          title: Text(
            l10n?.settingsSystemMute ?? 'Mute',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          semanticLabel: l10n?.settingsSystemMuteHint ??
              'Mute toggle - press to toggle system mute on or off',
        ),
        const SizedBox(height: AppSpacing.md),

        // Test sound button
        FocusableButton(
          focusNode: _testSoundFocusNode,
          label: l10n?.settingsSoundTest ?? 'Test Sound',
          onPressed: _handleTestSound,
        ),
      ],
    );
  }

  Widget _buildAboutSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Column(
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
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.textMuted, height: 1),
        const SizedBox(height: AppSpacing.md),
        FocusableListTile(
          focusNode: _systemInfoButtonFocusNode,
          leading: const Icon(
            Icons.computer,
            color: AppColors.primaryAccent,
          ),
          title: Text(
            l10n?.settingsAboutDevice ?? 'About This Device',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'OS, hardware, memory, storage and uptime',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
          ),
          onTap: _handleSystemInfo,
          semanticLabel: 'View detailed system information',
        ),
        const Divider(color: AppColors.textMuted, height: 1),
        FocusableListTile(
          focusNode: _networkInterfacesButtonFocusNode,
          leading: const Icon(
            Icons.settings_ethernet,
            color: AppColors.primaryAccent,
          ),
          title: Text(
            'Network Interfaces',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'View network adapter details and IP addresses',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
          ),
          onTap: _handleNetworkInterfaces,
          semanticLabel: 'View network interface details',
        ),
      ],
    );
  }

  Widget _buildGamepadSection(
    BuildContext context,
    SettingsLoaded state,
    AppLocalizations? l10n,
  ) {
    return Column(
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
    );
  }
}

/// A reusable card widget for settings sections.
///
/// Provides consistent styling with:
/// - Surface background color
/// - Subtle border for visual separation
/// - Resting elevation shadow
/// - Medium border radius
/// - Accent-colored title with a left indicator bar
class _SettingsSectionCard extends StatelessWidget {
  /// The section title displayed at the top.
  final String title;

  /// The section content widget.
  final Widget child;

  /// Creates a settings section card.
  const _SettingsSectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: AppColors.textMuted.withAlpha(38),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title with accent indicator bar
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
