import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import 'app_scaffold.dart';

class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const dotRadius = 1.2;
    const spacing = 18.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final nx = x / size.width;
        final ny = y / size.height;
        final noise = math.sin(nx * 15) * math.cos(ny * 10) + math.sin(nx * 25);
        if (noise > 0.3 && x > size.width * 0.3) {
          canvas.drawCircle(Offset(x, y), dotRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardHeaderScaffold extends StatelessWidget {
  final Widget headerContent;
  final Widget bodyContent;
  final double headerHeight;
  final Future<void> Function()? onRefresh;

  const DashboardHeaderScaffold({
    super.key,
    required this.headerContent,
    required this.bodyContent,
    this.headerHeight = 280.0,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: AppScaffold.getScrollPadding(context),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Stack(
        children: [
          // 1. Off-white background for the content area (everything below the header)
          // We start it slightly higher than headerHeight so it sits behind the rounded corners
          // of the header, making them visible against this lighter background.
          Positioned.fill(
            top: headerHeight - 64, // Extends up behind the header's bottom edge
            child: Container(color: AppTheme.lightBackground),
          ),

          // 2. Dark Navy Background Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkNavy,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: CustomPaint(painter: DottedBackgroundPainter()),
            ),
          ),

          // 3. Foreground Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Content (e.g. logos, welcome text)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: headerContent,
                ),
              ),
              // Body Content (e.g. stat cards, lists)
              bodyContent,
            ],
          ),
        ],
      ),
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return AppScaffold(
      // We set the main background to darkNavy so the top overscroll (pull to refresh) looks seamless!
      backgroundColor: AppTheme.darkNavy,
      body: content,
    );
  }
}
