import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.appBar,
    this.backgroundColor,
  });

  static EdgeInsets getScrollPadding(BuildContext context, {EdgeInsets basePadding = EdgeInsets.zero}) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    // Top of nav bar pill is now fixed at ~70px from the absolute bottom (safe area was removed).
    // We add 86px so lists clear the nav bar with a nice ~16px gap.
    final extraBottom = isDesktop ? 0.0 : 86.0;
    return basePadding.copyWith(bottom: basePadding.bottom + extraBottom);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    
    // Scaffold natively places the FAB at 16px + safeArea from the absolute bottom.
    // We want the FAB to sit at 86px from the absolute bottom (16px above the 70px nav pill).
    // So we need: 86 - 16 - safeArea = 70 - safeArea
    double fabPadding = isDesktop ? 0.0 : (70.0 - bottomSafeArea);
    if (fabPadding < 0) fabPadding = 0.0;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.lightBackground,
      appBar: appBar,
      body: body, // Transparent scroll bounds, no clipping!
      floatingActionButton: floatingActionButton != null 
          ? Padding(
              padding: EdgeInsets.only(bottom: fabPadding),
              child: floatingActionButton,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
