import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';

/// The content area wrapper for application pages.
///
/// Provides the content area with:
/// - Gradient background
/// - FocusScope for automatic focus containment
///
/// Note: The TopBar is now provided by ShellRoute in router.dart and persists
/// across navigation. This widget only wraps the page content.
class AppShell extends StatefulWidget {
  /// Creates the app shell content wrapper.
  const AppShell({
    super.key,
    required this.body,
  });

  /// The content to display in the body area.
  final Widget body;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _contentFocusNode = FocusScopeNode(debugLabel: 'ContentScope');

  @override
  void initState() {
    super.initState();
    // Register the content container focus scope node with the traversal service
    // This enables focus wrapping between top bar and content area
    FocusTraversalService.instance.setContentContainer(_contentFocusNode);
  }

  @override
  void dispose() {
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.backgroundDeep,
          ],
        ),
      ),
      child: FocusScope(
        node: _contentFocusNode,
        child: widget.body,
      ),
    );
  }
}
