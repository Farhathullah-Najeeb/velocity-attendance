import 'package:flutter/material.dart';
import '../../../models/leave.dart';

class LeaveBalanceCards extends StatelessWidget {
  final LeaveBalance balance;

  const LeaveBalanceCards({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    // Check if the balance is effectively empty
    final isEffectivelyEmpty = balance.balances.isEmpty ||
        balance.balances.values.every((b) => b.allowed == 0 && b.earned == 0 && b.taken == 0 && b.used == 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'LEAVE BALANCES',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isEffectivelyEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Theme.of(context).unselectedWidgetColor),
                    const SizedBox(height: 12),
                    Text(
                      'No leave balances assigned yet.',
                      style: TextStyle(color: Theme.of(context).unselectedWidgetColor, fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Expanded(
                        child: _BalanceCard(
                          title: 'CASUAL LEAVES',
                          total: (balance.balances['CASUAL']?.allowed ?? 0).toString(),
                          subtitle: 'Taken: ${balance.balances['CASUAL']?.taken ?? 0} / ${balance.balances['CASUAL']?.allowed ?? 0} Days',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BalanceCard(
                          title: 'SICK LEAVES',
                          total: (balance.balances['SICK']?.allowed ?? 0).toString(),
                          subtitle: 'Taken: ${balance.balances['SICK']?.taken ?? 0} / ${balance.balances['SICK']?.allowed ?? 0} Days',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _BalanceCard(
                          title: 'COMP-OFFS',
                          total: (balance.balances['COMPENSATORY']?.earned ?? 0).toString(),
                          subtitle: 'Earned: ${balance.balances['COMPENSATORY']?.earned ?? 0} | Used: ${balance.balances['COMPENSATORY']?.used ?? 0}',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BalanceCard(
                          title: 'OTHER LEAVES',
                          total: (balance.balances['OTHER']?.taken ?? 0).toString(), 
                          subtitle: 'Total Taken',
                          color: Theme.of(context).unselectedWidgetColor,
                        ),
                      ),
                      ],
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

class _BalanceCard extends StatelessWidget {
  final String title;
  final String total;
  final String subtitle;
  final Color color;

  const _BalanceCard({
    required this.title,
    required this.total,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              total,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
