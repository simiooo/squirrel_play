import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_button_icon.dart';

/// Modes for the file browser.
enum FileBrowserMode {
  /// Select a single file.
  file,

  /// Select a single directory.
  directory,

  /// Select multiple directories.
  multiDirectory,
}

/// A custom gamepad-operable file/directory browser widget.
///
/// Replaces native OS file pickers with a Steam Big Picture-inspired
/// browser that can be fully controlled by gamepad or keyboard.
///
/// Features:
/// - Browse directories using dart:io
/// - Persistent last path via shared_preferences
/// - Directory-first sorting
/// - Extension filtering for file mode
/// - Multi-selection support (multiDirectory mode)
/// - Full gamepad/keyboard control
/// - Focus trapping via [FocusScope]
class GamepadFileBrowser extends StatefulWidget {
  /// Creates a gamepad file browser.
  const GamepadFileBrowser({
    super.key,
    required this.mode,
    this.allowedExtensions,
    required this.onSelected,
  });

  /// The browser mode (file, directory, or multiDirectory).
  final FileBrowserMode mode;

  /// Allowed file extensions for file mode (e.g., ['exe']).
  /// Ignored in directory modes.
  final List<String>? allowedExtensions;

  /// Callback invoked when the user confirms a selection.
  final ValueChanged<List<String>> onSelected;

  /// Shows the file browser as a dialog.
  static Future<void> show(
    BuildContext context, {
    FileBrowserMode mode = FileBrowserMode.file,
    List<String>? allowedExtensions,
    required ValueChanged<List<String>> onSelected,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamepadFileBrowser(
        mode: mode,
        allowedExtensions: allowedExtensions,
        onSelected: (paths) {
          Navigator.of(context).pop();
          onSelected(paths);
        },
      ),
    );
  }

  @override
  State<GamepadFileBrowser> createState() => _GamepadFileBrowserState();
}

class _GamepadFileBrowserState extends State<GamepadFileBrowser> {
  static const String _prefsKey = 'last_file_browser_path';

  String _currentPath = '';
  List<FileSystemEntity> _items = [];
  bool _isLoading = true;
  String? _error;

  final List<FocusNode> _itemFocusNodes = [];
  final List<String> _selectedPaths = [];

  late final FocusNode _selectButtonFocusNode;
  late final FocusNode _cancelButtonFocusNode;
  late final FocusNode _keyboardFocusNode;

  int? _lastFocusedItemIndex;

  @override
  void initState() {
    super.initState();
    _selectButtonFocusNode = FocusNode(debugLabel: 'FileBrowserSelect');
    _cancelButtonFocusNode = FocusNode(debugLabel: 'FileBrowserCancel');
    _keyboardFocusNode = FocusNode(
      debugLabel: 'FileBrowserKeyboardListener',
      canRequestFocus: false,
    );
    _loadInitialPath();
  }

  @override
  void dispose() {
    _disposeItemFocusNodes();
    _selectButtonFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _disposeItemFocusNodes() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    _itemFocusNodes.clear();
    _lastFocusedItemIndex = null;
  }

  void _onItemFocusChanged(int index) {
    if (_itemFocusNodes[index].hasFocus && _lastFocusedItemIndex != index) {
      _lastFocusedItemIndex = index;
      SoundService.instance.playFocusMove();
      // Ensure the focused item is scrolled into view
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _itemFocusNodes[index].context;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
      setState(() {});
    }
  }

  Future<void> _loadInitialPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPath = prefs.getString(_prefsKey);

      String initialPath;
      if (lastPath != null && Directory(lastPath).existsSync()) {
        initialPath = lastPath;
      } else {
        initialPath = Platform.environment['HOME'] ?? '/';
      }

      await _loadDirectory(initialPath);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDirectory(String path) async {
    final pathToRestore = _currentPath.isNotEmpty ? _currentPath : '';

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final directory = Directory(path);
      if (!directory.existsSync()) {
        throw Exception('Directory does not exist: $path');
      }

      final entities = directory.listSync();

      // Separate directories and files
      final dirs = <FileSystemEntity>[];
      final files = <FileSystemEntity>[];

      for (final entity in entities) {
        if (entity is Directory) {
          dirs.add(entity);
        } else if (entity is File) {
          // Filter by extension if provided
          if (widget.mode == FileBrowserMode.file &&
              widget.allowedExtensions != null &&
              widget.allowedExtensions!.isNotEmpty) {
            final ext = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
            if (widget.allowedExtensions!.contains(ext)) {
              files.add(entity);
            }
          } else {
            files.add(entity);
          }
        }
      }

      // Sort each group alphabetically
      dirs.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(
            p.basename(b.path).toLowerCase(),
          ));
      files.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(
            p.basename(b.path).toLowerCase(),
          ));

      // Unfocus any item node before disposing to avoid invalid focus state
      final hasFocusedItem = _itemFocusNodes.any((node) => node.hasFocus);
      if (hasFocusedItem) {
        FocusManager.instance.primaryFocus?.unfocus();
      }

      // Create new focus nodes for items with sound feedback
      _disposeItemFocusNodes();
      final allItems = <FileSystemEntity>[...dirs, ...files];

      // Add parent directory entry (..) if not at root
      if (path != '/') {
        allItems.insert(0, Directory(p.dirname(path)));
      }

      for (var i = 0; i < allItems.length; i++) {
        final node = FocusNode(debugLabel: 'FileBrowserItem_$i');
        node.addListener(() => _onItemFocusChanged(i));
        _itemFocusNodes.add(node);
      }

      setState(() {
        _currentPath = path;
        _items = allItems;
        _isLoading = false;
      });

      // Focus first item after frame
      if (_itemFocusNodes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _itemFocusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      // Return to previous path if available
      if (pathToRestore.isNotEmpty && pathToRestore != path) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadDirectory(pathToRestore);
        });
      }
    }
  }

  void _goToParent() {
    final parent = p.dirname(_currentPath);
    if (parent != _currentPath) {
      _loadDirectory(parent);
    }
  }

  void _openItem(int index) {
    // Parent directory entry (..)
    if (index == 0 && _currentPath != '/') {
      _goToParent();
      return;
    }

    final item = _items[index];
    if (item is Directory) {
      _loadDirectory(item.path);
    } else if (item is File) {
      if (widget.mode == FileBrowserMode.file) {
        _saveLastPath(_currentPath);
        widget.onSelected([item.path]);
      }
    }
  }

  void _toggleSelection(int index) {
    if (widget.mode != FileBrowserMode.multiDirectory) return;

    // Don't allow selecting the parent directory entry
    if (index == 0 && _currentPath != '/') return;

    final item = _items[index];
    if (item is! Directory) return;

    final path = item.path;
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _confirmSelection() {
    if (widget.mode == FileBrowserMode.file) {
      // Find focused file
      for (var i = 0; i < _itemFocusNodes.length; i++) {
        if (_itemFocusNodes[i].hasFocus && _items[i] is File) {
          _saveLastPath(_currentPath);
          widget.onSelected([_items[i].path]);
          return;
        }
      }
    } else if (widget.mode == FileBrowserMode.directory) {
      // Select current directory
      _saveLastPath(_currentPath);
      widget.onSelected([_currentPath]);
    } else if (widget.mode == FileBrowserMode.multiDirectory) {
      if (_selectedPaths.isNotEmpty) {
        _saveLastPath(_currentPath);
        widget.onSelected(List.unmodifiable(_selectedPaths));
      }
    }
  }

  Future<void> _saveLastPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, path);
    } catch (_) {
      // Ignore persistence errors
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _goToParent();
        break;
      case LogicalKeyboardKey.escape:
        _cancel();
        break;
    }
  }

  List<String> _buildBreadcrumb() {
    final parts = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
        title: Text(
          l10n?.fileBrowserTitle ?? 'Select File',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: FocusScope(
          autofocus: true,
          child: SizedBox(
            width: 700,
            height: 500,
            child: Column(
              children: [
                // Breadcrumb header
                _buildBreadcrumbHeader(),
                const SizedBox(height: AppSpacing.md),

                // File list
                Expanded(
                  child: _buildContent(),
                ),

                const SizedBox(height: AppSpacing.md),

                // Footer with actions and hints
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbHeader() {
    final breadcrumbs = _buildBreadcrumb();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        children: [
          // Root indicator
          GestureDetector(
            onTap: () => _loadDirectory('/'),
            child: Text(
              '/',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryAccent,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < breadcrumbs.length; i++) ...[
                    Text(
                      ' / ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final path = '/${breadcrumbs.take(i + 1).join('/')}';
                        _loadDirectory(path);
                      },
                      child: Text(
                        breadcrumbs[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.error,
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)?.fileBrowserNoItems ?? 'No items',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isParentEntry = index == 0 && _currentPath != '/';
        final isDirectory = isParentEntry || item is Directory;
        final name = isParentEntry ? '..' : p.basename(item.path);
        final isFocused = _itemFocusNodes[index].hasFocus;
        final isSelected = _selectedPaths.contains(item.path);

        return Focus(
          focusNode: _itemFocusNodes[index],
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              switch (event.logicalKey) {
                case LogicalKeyboardKey.arrowUp:
                  if (index > 0) {
                    _itemFocusNodes[index - 1].requestFocus();
                  }
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.arrowDown:
                  if (index < _items.length - 1) {
                    _itemFocusNodes[index + 1].requestFocus();
                  }
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.arrowLeft:
                  _goToParent();
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.enter:
                case LogicalKeyboardKey.select:
                case LogicalKeyboardKey.gameButtonA:
                  if (isDirectory) {
                    _openItem(index);
                  } else if (widget.mode == FileBrowserMode.file) {
                    // File mode: select the file
                    _saveLastPath(_currentPath);
                    widget.onSelected([item.path]);
                  }
                  // In directory mode, A does nothing on files (use Select button)
                  return KeyEventResult.handled;
                case LogicalKeyboardKey.gameButtonX:
                  if (widget.mode == FileBrowserMode.multiDirectory &&
                      isDirectory && !isParentEntry) {
                    _toggleSelection(index);
                    return KeyEventResult.handled;
                  }
                  break;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  if (isDirectory) {
                    _openItem(index);
                  } else if (widget.mode == FileBrowserMode.file) {
                    _saveLastPath(_currentPath);
                    widget.onSelected([item.path]);
                  }
                  // Return non-null to indicate the intent was handled
                  return true;
                },
              ),
            },
            child: GestureDetector(
              onTap: () => _openItem(index),
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: isFocused
                    ? AppColors.surfaceElevated
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.small),
                border: isFocused
                    ? Border.all(
                        color: AppColors.primaryAccent,
                        width: 2,
                      )
                    : null,
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    isParentEntry
                        ? Icons.arrow_upward
                        : (isDirectory
                            ? Icons.folder
                            : Icons.insert_drive_file),
                    color: isDirectory
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.secondaryAccent,
                      size: 20,
                    ),
                ],
              ),
            ),
          )
        ));
      },
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action buttons
        Row(
          children: [
            Expanded(
              child: FocusableButton(
                focusNode: _selectButtonFocusNode,
                label: l10n?.fileBrowserSelect ?? 'Select',
                isPrimary: true,
                onPressed: _confirmSelection,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FocusableButton(
                focusNode: _cancelButtonFocusNode,
                label: l10n?.fileBrowserCancel ?? 'Cancel',
                onPressed: _cancel,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Gamepad hints
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHint(
              'A',
              widget.mode == FileBrowserMode.file ? 'Select' : 'Open',
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildHint('B', l10n?.gamepadNavBack ?? 'Back'),
            if (widget.mode == FileBrowserMode.directory) ...[
              const SizedBox(width: AppSpacing.lg),
              _buildHint('Select', 'Select Current'),
            ],
            if (widget.mode == FileBrowserMode.multiDirectory) ...[
              const SizedBox(width: AppSpacing.lg),
              _buildHint('X', l10n?.gamepadNavToggle ?? 'Toggle'),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHint(String button, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GamepadButtonIcon(label: button),
        const SizedBox(width: AppSpacing.xs),
        Text(
          action,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}