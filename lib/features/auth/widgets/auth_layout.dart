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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 950;

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
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildContent(context, isMobile: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left side: Deep Obsidian Black & Velocity Red Ambient Hero
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF141A28),
                    Color(0xFF0A0D14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Ambient Crimson Red Glow Orbs
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -40,
                    child: Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFC62828).withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 64.0,
                      vertical: 56.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const VelocityLogo(height: 52),
                        const SizedBox(height: 48),
                        const Text(
                          'Seamless Workforce &\nAttendance Management',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Empower your team with real-time GPS check-ins, automated leave approvals, and actionable attendance intelligence.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF94A3B8),
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Highlight Feature Badges
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildHeroFeaturePill('⚡ Real-time GPS Attendance'),
                            _buildHeroFeaturePill('🛡️ Role-based Permissions'),
                            _buildHeroFeaturePill('📊 Instant Timesheet Exports'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right side: Glassmorphism Login Card
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56.0,
                    vertical: 40.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935)
                                .withValues(alpha: 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildContent(context, isMobile: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeaturePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
        if (isMobile) ...[
          const Center(child: VelocityLogo(height: 48)),
          const SizedBox(height: 28),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 32),
        ...formChildren,
        if (bottomContent != null) ...[
          const SizedBox(height: 16),
          bottomContent!,
        ],
      ],
    );
  }
}
