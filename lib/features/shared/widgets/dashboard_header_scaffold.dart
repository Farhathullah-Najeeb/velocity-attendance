import 'package:flutter/material.dart';
import '../../../core/theme/velocity_colors.dart';
import 'app_scaffold.dart';

/// A content layout used for Dashboard screens.
/// Does NOT create a Scaffold — the AppShell's Scaffold wraps everything.
class DashboardHeaderScaffold extends StatelessWidget {
  final Widget headerContent;
  final Widget bodyContent;
  final double headerHeight;
  final Future<void> Function()? onRefresh;

  const DashboardHeaderScaffold({
    super.key,
    required this.headerContent,
    required this.bodyContent,
    this.headerHeight = 220.0,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: AppScaffold.getScrollPadding(context),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Surface Banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: VelocityColors.baseWhite,
              border: Border(
                bottom: BorderSide(color: VelocityColors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: SafeArea(
              bottom: false,
              child: headerContent,
            ),
          ),
          const SizedBox(height: 16),
          // 2. Body content
          bodyContent,
          const SizedBox(height: 40),
        ],
      ),
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return ColoredBox(
      color: VelocityColors.background,
      child: content,
    );
  }
}
