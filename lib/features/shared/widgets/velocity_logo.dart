import 'package:flutter/material.dart';

class VelocityLogo extends StatelessWidget {
  final double height;
  final bool showText;

  const VelocityLogo({
    super.key,
    this.height = 40,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // The Red Square with Black Circle
          Container(
            width: height,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Padding(
              padding: EdgeInsets.all(height * 0.15),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.secondary, width: height * 0.12),
                ),
                child: Center(
                  child: Container(
                    width: height * 0.15,
                    height: height * 0.15,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VELOCITY',
                  style: TextStyle(
                    fontSize: height * 0.6,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    height: 1.0,
                    color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  'THE PROJECT MANAGEMENT PEOPLE',
                  style: TextStyle(
                    fontSize: height * 0.18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: (Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.secondary).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

