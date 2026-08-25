import 'package:flutter/material.dart';
import 'responsive_container.dart';

/// A layout container that is used INSIDE the AppShell's Scaffold.
/// It does NOT create its own Scaffold — that would be nested and causes
/// framework assertion errors (!semantics.parentDataDirty, etc.).
///
/// [body]   — the main scrollable/non-scrollable content
/// [floatingActionButton] — rendered as a Stack overlay above the body
/// [backgroundColor] — optional background override
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  // appBar is intentionally REMOVED — the shell's Scaffold controls the AppBar.
  // Any per-screen app bar needs are handled by the shell via the tab index.

  const AppScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  /// Returns padding that ensures scrollable content clears the floating bottom
  /// nav pill on mobile. On desktop the nav is a sidebar, so no extra padding.
  static EdgeInsets getScrollPadding(
    BuildContext context, {
    EdgeInsets basePadding = EdgeInsets.zero,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final extraBottom = isDesktop ? 0.0 : 130.0;
    return basePadding.copyWith(bottom: basePadding.bottom + extraBottom);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final bg = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    Widget content = ResponsiveContainer(
      maxWidth: 1024,
      child: body,
    );

    if (floatingActionButton != null) {
      // Place the FAB in a Stack overlay above the body.
      // On mobile we shift it up by 90px to clear the nav pill.
      final fabBottom = isDesktop ? 16.0 : 106.0;
      content = Stack(
        children: [
          content,
          Positioned(
            bottom: fabBottom,
            right: 16,
            child: floatingActionButton!,
          ),
        ],
      );
    }

    return ColoredBox(
      color: bg,
      child: content,
    );
  }
}
