import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/network_status_service.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// A page displaying detailed network interface information.
///
/// Shows all network adapters, their types, connection status,
/// link speeds, and assigned IP addresses.
class NetworkInterfacesPage extends StatefulWidget {
  /// Creates the network interfaces page.
  const NetworkInterfacesPage({super.key});

  @override
  State<NetworkInterfacesPage> createState() => _NetworkInterfacesPageState();
}

class _NetworkInterfacesPageState extends State<NetworkInterfacesPage> {
  List<NetworkInterfaceInfo> _interfaces = [];
  bool _isLoading = true;
  String? _error;
  late final FocusNode _backButtonFocusNode;

  @override
  void initState() {
    super.initState();
    _backButtonFocusNode = FocusNode(debugLabel: 'NetworkInterfacesBackButton');
    _loadInterfaces();
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInterfaces() async {
    try {
      final service = getIt<NetworkStatusService>();
      final interfaces = await service.getNetworkInterfaces();
      if (mounted) {
        setState(() {
          _interfaces = interfaces;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    SoundService.instance.playFocusBack();
    context.go('/settings');
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
                    'Network Interfaces',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.error,
          ),
        ),
      );
    }

    if (_interfaces.isEmpty) {
      return const Center(
        child: Text('No network interfaces found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._interfaces.map((iface) => _buildInterfaceCard(context, iface)),
        ],
      ),
    );
  }

  Widget _buildInterfaceCard(BuildContext context, NetworkInterfaceInfo iface) {
    final IconData typeIcon;
    final Color typeColor;
    switch (iface.type) {
      case NetworkInterfaceType.wired:
        typeIcon = Icons.settings_ethernet;
        typeColor = AppColors.secondaryAccent;
      case NetworkInterfaceType.wireless:
        typeIcon = Icons.wifi;
        typeColor = AppColors.primaryAccent;
      case NetworkInterfaceType.loopback:
        typeIcon = Icons.loop;
        typeColor = AppColors.textMuted;
      case NetworkInterfaceType.other:
        typeIcon = Icons.network_check;
        typeColor = AppColors.textSecondary;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, color: typeColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  iface.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: iface.isConnected
                      ? AppColors.success.withAlpha(51)
                      : AppColors.error.withAlpha(51),
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
                child: Text(
                  iface.isConnected ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: iface.isConnected
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.textMuted, height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(context, 'Type', _typeLabel(iface.type)),
          if (iface.speed != null)
            _buildInfoRow(context, 'Speed', '${iface.speed} Mbps'),
          _buildInfoRow(context, 'Status', iface.isUp ? 'Up' : 'Down'),
          if (iface.ipAddresses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'IP Addresses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...iface.ipAddresses.map(
              (ip) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  ip,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(NetworkInterfaceType type) {
    switch (type) {
      case NetworkInterfaceType.wired:
        return 'Wired Ethernet';
      case NetworkInterfaceType.wireless:
        return 'Wireless (Wi-Fi)';
      case NetworkInterfaceType.loopback:
        return 'Loopback';
      case NetworkInterfaceType.other:
        return 'Other';
    }
  }
}
