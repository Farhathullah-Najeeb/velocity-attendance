import 'package:flutter/material.dart';

import '../../shared/widgets/velocity_logo.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> formChildren;
  final Widget? bottomContent;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.formChildren,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildWebLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: _buildContent(context, isMobile: true),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                child: _buildContent(context, isMobile: false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: VelocityLogo(height: 60)),
        const SizedBox(height: 48),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ...formChildren,
        if (bottomContent != null) ...[
          const SizedBox(height: 12),
          bottomContent!,
        ],
      ],
    );
  }
}
