import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'app_scaffold.dart';

class DottedBackgroundPainter extends CustomPainter {
  final Color dividerColor;
  DottedBackgroundPainter(this.dividerColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dividerColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    const dotRadius = 1.2;
    const spacing = 18.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final nx = x / size.width;
        final ny = y / size.height;
        final noise =
            math.sin(nx * 15) * math.cos(ny * 10) + math.sin(nx * 25);
        if (noise > 0.3 && x > size.width * 0.3) {
          canvas.drawCircle(Offset(x, y), dotRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A content layout used for Dashboard screens.
/// Does NOT create a Scaffold — the AppShell's Scaffold wraps everything.
class DashboardHeaderScaffold extends StatelessWidget {
  final Widget headerContent;
  final Widget bodyContent;
  final double headerHeight;
  final Future<void> Function()? onRefresh;

  // appBar intentionally removed — the shell's Scaffold controls the AppBar.

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
          Positioned.fill(
            top: headerHeight - 64,
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),

          // 2. Coloured header background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: CustomPaint(
                painter: DottedBackgroundPainter(Theme.of(context).dividerColor),
              ),
            ),
          ),

          // 3. Foreground content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

    // Return the content directly — no nested AppScaffold/Scaffold.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: content,
    );
  }
}
