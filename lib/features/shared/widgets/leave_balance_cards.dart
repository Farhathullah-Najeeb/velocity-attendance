import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/leave.dart';

class LeaveBalanceCards extends StatelessWidget {
  final LeaveBalance balance;

  const LeaveBalanceCards({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final casual = balance.balances['CASUAL'];
    final sick = balance.balances['SICK'];
    final comp = balance.balances['COMPENSATORY'];

    final casualAllowed = casual?.allowed ?? 0;
    final casualTaken = casual?.taken ?? 0;
    final casualAvailable = (casualAllowed - casualTaken).clamp(0, 999);

    final sickAllowed = sick?.allowed ?? 0;
    final sickTaken = sick?.taken ?? 0;
    final sickAvailable = (sickAllowed - sickTaken).clamp(0, 999);

    final compEarned = comp?.earned ?? 0;
    final compUsed = comp?.used ?? 0;
    final compAvailable = (compEarned - compUsed).clamp(0, 999);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 500;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ModernBalanceCard(
                  title: 'Casual Leave',
                  icon: Icons.beach_access_rounded,
                  available: casualAvailable,
                  total: casualAllowed,
                  taken: casualTaken,
                  color: const Color(0xFF10B981),
                  isDesktop: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernBalanceCard(
                  title: 'Sick Leave',
                  icon: Icons.medical_services_rounded,
                  available: sickAvailable,
                  total: sickAllowed,
                  taken: sickTaken,
                  color: const Color(0xFF3B82F6),
                  isDesktop: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernBalanceCard(
                  title: 'Comp-Off',
                  icon: Icons.bolt_rounded,
                  available: compAvailable,
                  total: compEarned,
                  taken: compUsed,
                  color: const Color(0xFF8B5CF6),
                  isDesktop: true,
                ),
              ),
            ],
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
            children: [
              _ModernBalanceCard(
                title: 'Casual Leave',
                icon: Icons.beach_access_rounded,
                available: casualAvailable,
                total: casualAllowed,
                taken: casualTaken,
                color: const Color(0xFF10B981),
                isDesktop: false,
              ),
              const SizedBox(width: 12),
              _ModernBalanceCard(
                title: 'Sick Leave',
                icon: Icons.medical_services_rounded,
                available: sickAvailable,
                total: sickAllowed,
                taken: sickTaken,
                color: const Color(0xFF3B82F6),
                isDesktop: false,
              ),
              const SizedBox(width: 12),
              _ModernBalanceCard(
                title: 'Comp-Off',
                icon: Icons.bolt_rounded,
                available: compAvailable,
                total: compEarned,
                taken: compUsed,
                color: const Color(0xFF8B5CF6),
                isDesktop: false,
              ),
            ],
          ),
        ),
        );
      },
    );
  }
}

class _ModernBalanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int available;
  final int total;
  final int taken;
  final Color color;
  final bool isDesktop;

  const _ModernBalanceCard({
    required this.title,
    required this.icon,
    required this.available,
    required this.total,
    required this.taken,
    required this.color,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total > 0
        ? (available / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: isDesktop ? null : 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$available',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'days left',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$taken taken of $total allocated',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
