import 'package:flutter/material.dart';

class VelocityLogo extends StatelessWidget {
  final double height;
  final bool showText;

  const VelocityLogo({
    super.key,
    this.height = 40,
    this.showText = true, // Ignored since the asset has text
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
