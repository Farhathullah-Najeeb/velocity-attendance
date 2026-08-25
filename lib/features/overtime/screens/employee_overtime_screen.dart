import 'package:auto_route/auto_route.dart';
import '../../../core/router/app_router.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/overtime_service.dart';
import '../../../models/overtime.dart';
import '../../shared/widgets/states.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/velocity_colors.dart';

final myOvertimeProvider = FutureProvider.autoDispose<List<Overtime>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.watch(overtimeServiceProvider).getMyOvertime(employeeId: user.id);
});

@RoutePage()
class EmployeeOvertimeScreen extends ConsumerWidget {
  const EmployeeOvertimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(myOvertimeProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      body: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(myOvertimeProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VelocityColors.primaryRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: VelocityColors.primaryRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My Overtime',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            asyncData.when(
              loading: () => const SliverFillRemaining(
                child: LoadingStateWidget(),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorStateWidget(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(myOvertimeProvider),
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.timer_off_outlined,
                      title: 'No Overtime Records',
                      message:
                          'You have not submitted any overtime requests yet.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: AppScaffold.getScrollPadding(
                    context,
                    basePadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _OvertimeCard(record: records[index]),
                      childCount: records.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.router.push(const RequestOvertimeRoute());
        },
        backgroundColor: VelocityColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Request Overtime',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  final Overtime record;

  const _OvertimeCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    switch (record.status.toUpperCase()) {
      case 'APPROVED':
        statusColor = VelocityColors.success;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        statusColor = VelocityColors.error;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = VelocityColors.warning;
        statusIcon = Icons.hourglass_top_outlined;
    }

    // Parse date for nicer formatting
    String formattedDate = record.dateStr;
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(record.dateStr);
      formattedDate = DateFormat('EEE, dd MMM yyyy').format(parsed);
    } catch (_) {}

    final hours = record.overtimeMinutes ~/ 60;
    final minutes = record.overtimeMinutes % 60;
    final durationLabel = hours > 0
        ? '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        record.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: VelocityColors.primaryRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: VelocityColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    durationLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: VelocityColors.primaryRed,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (record.reason != null && record.reason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                record.reason!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
            if (record.remarks != null && record.remarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.remarks!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
