import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leaves/services/leave_service.dart';
import '../../../models/leave.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/states.dart';
import '../../../core/theme/velocity_colors.dart';

final pendingLeavesProvider = FutureProvider.autoDispose<List<Leave>>((ref) {
  return ref.watch(leaveServiceProvider).getLeaves(status: 'PENDING');
});

@RoutePage()
class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({super.key});

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    Leave leave,
    bool isApprove,
  ) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle : Icons.cancel,
              color: isApprove ? VelocityColors.success : VelocityColors.error,
            ),
            const SizedBox(width: 8),
            Text(isApprove ? 'Approve Leave' : 'Reject Leave'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${isApprove ? 'approve' : 'reject'} this leave request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Add a note for the employee...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove
                  ? VelocityColors.success
                  : VelocityColors.error,
              foregroundColor: VelocityColors.baseWhite,
            ),
            onPressed: () async {
              try {
                if (isApprove) {
                  await ref
                      .read(leaveServiceProvider)
                      .approveLeave(leave.id, remarksController.text);
                } else {
                  await ref
                      .read(leaveServiceProvider)
                      .rejectLeave(leave.id, remarksController.text);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  SnackbarUtils.showSuccess(
                    context,
                    'Leave request ${isApprove ? 'approved' : 'rejected'} successfully',
                  );
                }
                ref.invalidate(pendingLeavesProvider);
              } catch (e) {
                if (context.mounted) {
                  SnackbarUtils.handleApiError(context, e);
                }
              }
            },
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(pendingLeavesProvider);

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingLeavesProvider);
        },
        child: leavesAsync.when(
          data: (leaves) {
            if (leaves.isEmpty) {
              return const EmptyStateWidget(
                title: 'All caught up!',
                message: 'There are no pending leave approvals at the moment.',
                icon: Icons.fact_check_outlined,
              );
            }
            return ListView.builder(
              padding: AppScaffold.getScrollPadding(
                context,
                basePadding: const EdgeInsets.all(16),
              ),
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final leave = leaves[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    leave.employeeId is Map
                                        ? (leave.employeeId['name'] ?? 'Unknown Employee')
                                        : 'Employee ID: ${leave.employeeId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${leave.type} LEAVE',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'PENDING',
                              style: TextStyle(
                                color: VelocityColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).unselectedWidgetColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${leave.fromDate} to ${leave.toDate}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          leave.reason,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showApprovalDialog(
                                context,
                                ref,
                                leave,
                                false,
                              ),
                              icon: Icon(
                                Icons.close,
                                color: VelocityColors.error,
                              ),
                              label: Text(
                                'Reject',
                                style: TextStyle(color: VelocityColors.error),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: VelocityColors.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showApprovalDialog(
                                context,
                                ref,
                                leave,
                                true,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VelocityColors.success,
                                foregroundColor: VelocityColors.baseWhite,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingStateWidget(),
          error: (err, stack) => ErrorStateWidget(
            error: err.toString(),
            onRetry: () => ref.invalidate(pendingLeavesProvider),
          ),
        ),
      ),
    );
  }
}
