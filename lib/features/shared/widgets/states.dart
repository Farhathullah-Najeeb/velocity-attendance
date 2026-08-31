import 'package:flutter/material.dart';
import '../../../core/theme/velocity_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.fontSize,
    this.padding,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase().trim();
    Color bg;
    Color border;
    Color text;

    if (s == 'APPROVED' || s == 'PRESENT' || s == 'ON_TIME' || s == 'ON TIME' || s == 'CHECKED_IN' || s == 'ACTIVE') {
      bg = VelocityColors.successBg;
      border = VelocityColors.successBorder;
      text = VelocityColors.success;
    } else if (s == 'REJECTED' || s == 'ABSENT' || s == 'LATE' || s == 'LATE ARRIVAL' || s == 'NOT_CHECKED_IN' || s == 'DEACTIVATED') {
      bg = VelocityColors.dangerBg;
      border = VelocityColors.dangerBorder;
      text = VelocityColors.danger;
    } else if (s == 'PENDING' || s == 'EARLY_EXIT' || s == 'EARLY CHECKOUT' || s == 'GRACE_PERIOD' || s == 'HALF_DAY') {
      bg = VelocityColors.warningBg;
      border = VelocityColors.warningBorder;
      text = VelocityColors.warning;
    } else if (s == 'WFH' || s == 'WORK FROM HOME' || s == 'INFO' || s == 'OVERTIME') {
      bg = VelocityColors.infoBg;
      border = VelocityColors.infoBorder;
      text = VelocityColors.info;
    } else if (s == 'REGULARIZATION' || s == 'EXCEPTION' || s == 'HOLIDAY' || s == 'COMPENSATORY') {
      bg = VelocityColors.purpleBg;
      border = VelocityColors.purpleBorder;
      text = VelocityColors.purple;
    } else {
      bg = VelocityColors.surfaceHover;
      border = VelocityColors.borderStrong;
      text = VelocityColors.textSubtle;
    }

    final displayText = customLabel ?? s.replaceAll('_', ' ');

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: text,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            displayText,
            style: TextStyle(
              color: text,
              fontSize: fontSize ?? 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? VelocityColors.baseWhite,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border ?? Border.all(color: VelocityColors.border, width: 1),
        boxShadow: VelocityColors.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(
          color: VelocityColors.primaryRed,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VelocityColors.dangerBg,
                shape: BoxShape.circle,
                border: Border.all(color: VelocityColors.dangerBorder),
              ),
              child: const Icon(Icons.error_outline, color: VelocityColors.danger, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: VelocityColors.textSubtle, fontSize: 13),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: VelocityColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: VelocityColors.border),
              ),
              child: Icon(icon, color: VelocityColors.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: VelocityColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: VelocityColors.textSubtle, fontSize: 13),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
