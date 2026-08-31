import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/leave.dart';

class LeaveBalanceCards extends StatelessWidget {
  final LeaveBalance balance;
  final bool forceDesktop;
  final int? daysLoggedThisMonth;

  const LeaveBalanceCards({
    super.key,
    required this.balance,
    this.forceDesktop = false,
    this.daysLoggedThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    final casual = balance.balances['CASUAL'];
    final sick = balance.balances['SICK'];
    final comp = balance.balances['COMPENSATORY'];

    final casualAllowed = casual?.allowed ?? 6;
    final casualTaken = casual?.taken ?? 0;
    final casualAvailable = (casualAllowed - casualTaken).clamp(0, 999);

    final sickAllowed = sick?.allowed ?? 6;
    final sickTaken = sick?.taken ?? 0;
    final sickAvailable = (sickAllowed - sickTaken).clamp(0, 999);

    final compEarned = comp?.earned ?? 0;
    final compUsed = comp?.used ?? 0;
    final compAvailable = (compEarned - compUsed).clamp(0, 999);

    final currentMonthName = DateFormat('MMMM').format(DateTime.now());
    final loggedDays = daysLoggedThisMonth ?? 3;

    final isDesktop = forceDesktop ||
        (kIsWeb && MediaQuery.of(context).size.width > 800);

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _LeaveMiniCard(
              title: 'CASUAL LEAVE',
              icon: Icons.beach_access_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              count: casualAvailable,
              total: casualAllowed,
              countLabel: 'Days Available',
              footerLeft: 'Taken: $casualTaken',
              footerRight: 'Allowed: $casualAllowed',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _LeaveMiniCard(
              title: 'SICK LEAVE',
              icon: Icons.medical_services_outlined,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              count: sickAvailable,
              total: sickAllowed,
              countLabel: 'Days Available',
              footerLeft: 'Taken: $sickTaken',
              footerRight: 'Allowed: $sickAllowed',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _LeaveMiniCard(
              title: 'COMP OFFS',
              icon: Icons.card_giftcard_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              count: compAvailable,
              total: compEarned > 0 ? compEarned : 1,
              countLabel: 'Days Available',
              footerLeft: 'Earned: $compEarned',
              footerRight: 'Used: $compUsed',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _LeaveMiniCard(
              title: 'THIS MONTH',
              icon: Icons.calendar_month_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              count: loggedDays,
              total: 22,
              countLabel: 'Days Logged',
              footerLeft: currentMonthName,
              footerRight: 'Active',
              footerRightColor: const Color(0xFF10B981),
            ),
          ),
        ],
      );
    }

    // Mobile / Tablet layout
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _LeaveMiniCard(
            width: 155,
            title: 'CASUAL LEAVE',
            icon: Icons.beach_access_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFC62828)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            count: casualAvailable,
            total: casualAllowed,
            countLabel: 'Days Left',
            footerLeft: 'Taken: $casualTaken',
            footerRight: 'Max: $casualAllowed',
          ),
          const SizedBox(width: 12),
          _LeaveMiniCard(
            width: 155,
            title: 'SICK LEAVE',
            icon: Icons.medical_services_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            count: sickAvailable,
            total: sickAllowed,
            countLabel: 'Days Left',
            footerLeft: 'Taken: $sickTaken',
            footerRight: 'Max: $sickAllowed',
          ),
          const SizedBox(width: 12),
          _LeaveMiniCard(
            width: 155,
            title: 'COMP OFFS',
            icon: Icons.card_giftcard_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            count: compAvailable,
            total: compEarned > 0 ? compEarned : 1,
            countLabel: 'Days Left',
            footerLeft: 'Earned: $compEarned',
            footerRight: 'Used: $compUsed',
          ),
          const SizedBox(width: 12),
          _LeaveMiniCard(
            width: 155,
            title: 'THIS MONTH',
            icon: Icons.calendar_month_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            count: loggedDays,
            total: 22,
            countLabel: 'Logged',
            footerLeft: currentMonthName,
            footerRight: 'Active',
            footerRightColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _LeaveMiniCard extends StatefulWidget {
  final double? width;
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final int count;
  final int total;
  final String countLabel;
  final String footerLeft;
  final String footerRight;
  final Color? footerRightColor;

  const _LeaveMiniCard({
    this.width,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.count,
    required this.total,
    required this.countLabel,
    required this.footerLeft,
    required this.footerRight,
    this.footerRightColor,
  });

  @override
  State<_LeaveMiniCard> createState() => _LeaveMiniCardState();
}

class _LeaveMiniCardState extends State<_LeaveMiniCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.total > 0
        ? (widget.count / widget.total).clamp(0.0, 1.0)
        : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.gradient.colors.first.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: _hovered ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.gradient.colors.first.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Title & Icon Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.colors.first
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Count & Label
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.count.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.countLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Line
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 5,
                color: const Color(0xFFF1F5F9),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.footerLeft,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.footerRight,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: widget.footerRightColor ?? const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
