import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/data/services/system_info_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// A page displaying system information in a fastfetch-inspired layout.
///
/// Shows OS, kernel, hostname, CPU, memory, GPU, storage (with usage bars),
/// and uptime.
class SystemInfoPage extends StatefulWidget {
  /// Creates the system info page.
  const SystemInfoPage({super.key});

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  SystemInfo? _systemInfo;
  bool _isLoading = true;
  String? _error;
  late final FocusNode _backButtonFocusNode;

  @override
  void initState() {
    super.initState();
    _backButtonFocusNode = FocusNode(debugLabel: 'SystemInfoBackButton');
    _loadSystemInfo();
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSystemInfo() async {
    try {
      final info = await getIt<SystemInfoService>().getSystemInfo();
      if (mounted) {
        setState(() {
          _systemInfo = info;
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
                    l10n?.systemInfoTitle ?? 'About This Device',
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

    final info = _systemInfo;
    if (info == null) {
      return const Center(
        child: Text('No system information available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            title: 'Operating System',
            icon: Icons.computer,
            rows: [
              _InfoRow(label: 'OS', value: info.osName),
              if (info.osVersion.isNotEmpty)
                _InfoRow(label: 'Version', value: info.osVersion),
              if (info.kernel.isNotEmpty)
                _InfoRow(label: 'Kernel', value: info.kernel),
              if (info.hostname.isNotEmpty)
                _InfoRow(label: 'Hostname', value: info.hostname),
              if (info.architecture != null)
                _InfoRow(label: 'Architecture', value: info.architecture!),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoCard(
            context,
            title: 'Hardware',
            icon: Icons.memory,
            rows: [
              if (info.cpuModel.isNotEmpty)
                _InfoRow(label: 'CPU', value: info.cpuModel),
              if (info.cpuCores > 0)
                _InfoRow(label: 'Cores', value: '${info.cpuCores}'),
              if (info.gpuModel != null)
                _InfoRow(label: 'GPU', value: info.gpuModel!),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoCard(
            context,
            title: 'Memory',
            icon: Icons.storage,
            rows: [
              _InfoRow(
                label: 'Total',
                value: _formatBytes(info.memoryTotal),
              ),
              _InfoRow(
                label: 'Used',
                value: _formatBytes(info.memoryUsed),
              ),
              _InfoRow(
                label: 'Usage',
                value: '${(info.memoryUsageRatio * 100).toStringAsFixed(1)}%',
              ),
            ],
            extra: info.memoryTotal > 0
                ? _buildUsageBar(
                    context,
                    ratio: info.memoryUsageRatio,
                    usedText: _formatBytes(info.memoryUsed),
                    totalText: _formatBytes(info.memoryTotal),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoCard(
            context,
            title: 'Storage',
            icon: Icons.storage,
            rows: info.storageDevices.isEmpty
                ? const [_InfoRow(label: 'Status', value: 'No storage info')]
                : const [],
            extra: info.storageDevices.isNotEmpty
                ? Column(
                    children: info.storageDevices.map((device) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                Text(
                                  device.mountPoint,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _buildUsageBar(
                              context,
                              ratio: device.usageRatio,
                              usedText: device.usedFormatted,
                              totalText: device.totalFormatted,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (info.uptime.isNotEmpty)
            _buildInfoCard(
              context,
              title: 'Uptime',
              icon: Icons.timer,
              rows: [
                _InfoRow(label: 'Duration', value: info.uptime),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
    Widget? extra,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.textMuted, height: 1),
          const SizedBox(height: AppSpacing.md),
          ...rows.map((row) => _buildInfoRow(context, row)),
          if (extra != null) ...[
            const SizedBox(height: AppSpacing.md),
            extra,
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, _InfoRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(
    BuildContext context, {
    required double ratio,
    required String usedText,
    required String totalText,
  }) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final barColor = clampedRatio > 0.9
        ? AppColors.error
        : clampedRatio > 0.75
            ? Colors.orange
            : AppColors.secondaryAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: Container(
            height: 8,
            width: double.infinity,
            color: AppColors.backgroundDeep,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$usedText / $totalText',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes <= 0) return '0 B';
    var i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
}
