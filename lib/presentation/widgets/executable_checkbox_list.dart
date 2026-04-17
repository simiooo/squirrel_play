import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/models/discovered_executable_model.dart';

/// A scrollable list of discovered executables with checkboxes.
///
/// Features:
/// - Checkbox for each executable
/// - Filename and path display
/// - Gamepad-navigable (up/down arrows)
/// - A/Enter to toggle checkbox
class ExecutableCheckboxList extends StatefulWidget {
  /// Creates the executable checkbox list.
  const ExecutableCheckboxList({
    super.key,
    required this.executables,
    required this.onToggle,
  });

  /// List of discovered executables to display.
  final List<DiscoveredExecutableModel> executables;

  /// Callback when an executable's selection is toggled.
  final ValueChanged<String> onToggle;

  @override
  State<ExecutableCheckboxList> createState() => _ExecutableCheckboxListState();
}

class _ExecutableCheckboxListState extends State<ExecutableCheckboxList> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.executables.length,
      (index) => FocusNode(debugLabel: 'ExecutableCheckbox_$index'),
    );

    // Focus first item after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(ExecutableCheckboxList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adjust focus nodes if executables list changes
    if (widget.executables.length != _focusNodes.length) {
      // Dispose old nodes
      for (final node in _focusNodes) {
        node.dispose();
      }
      // Create new nodes
      _focusNodes.clear();
      _focusNodes.addAll(
        List.generate(
          widget.executables.length,
          (index) => FocusNode(debugLabel: 'ExecutableCheckbox_$index'),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          if (index < _focusNodes.length - 1) {
            _focusNodes[index + 1].requestFocus();
          }
          break;
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.gameButtonA:
          widget.onToggle(widget.executables[index].path);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.executables.isEmpty) {
      return const Center(
        child: Text(
          'No executables found',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.executables.length,
      itemBuilder: (context, index) {
        final executable = widget.executables[index];
        final isFocused = _focusNodes[index].hasFocus;

        return Focus(
          focusNode: _focusNodes[index],
          onKeyEvent: (node, event) {
            _handleKeyEvent(event, index);
            return KeyEventResult.handled;
          },
          child: GestureDetector(
            onTap: () => widget.onToggle(executable.path),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: isFocused
                    ? AppColors.surfaceElevated
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.small),
                border: isFocused
                    ? Border.all(color: AppColors.primaryAccent, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Checkbox(
                    value: executable.isSelected,
                    onChanged: (_) => widget.onToggle(executable.path),
                    activeColor: AppColors.primaryAccent,
                    checkColor: AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          executable.fileName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: executable.isAlreadyAdded
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: executable.isAlreadyAdded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          executable.path,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (executable.isAlreadyAdded)
                          Text(
                            'Already in library',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
