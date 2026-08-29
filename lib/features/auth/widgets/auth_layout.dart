import 'package:flutter/material.dart';
import '../../shared/widgets/velocity_logo.dart';
import '../../../core/theme/velocity_colors.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        if (isMobile) {
          return _buildMobileLayout(context);
        } else {
          return _buildWebLayout(context);
        }
      },
    );
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
      body: Row(
        children: [
          // Left side: Branding / Premium Gradient
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Colors.black,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VelocityColors.primaryRed.withValues(alpha: 0.15),
                        // Add blur effect natively by avoiding BackdropFilter if possible, or just a soft color
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -50,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const VelocityLogo(height: 70),
                        const SizedBox(height: 40),
                        const Text(
                          'Manage your workforce seamlessly.',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'The all-in-one attendance management system built for modern, fast-paced teams.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side: Login Form
          Expanded(
            flex: 4,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 40.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildContent(context, isMobile: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile) ...[
          const Center(child: VelocityLogo(height: 60)),
          const SizedBox(height: 48),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 40),
        ...formChildren,
        if (bottomContent != null) ...[
          const SizedBox(height: 12),
          bottomContent!,
        ],
      ],
    );
  }
}
