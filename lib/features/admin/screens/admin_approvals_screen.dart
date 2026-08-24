import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leaves/services/leave_service.dart';
import '../../../models/leave.dart';
import '../../shared/widgets/states.dart';
import '../../../core/theme/app_theme.dart';

final pendingLeavesProvider = FutureProvider.autoDispose<List<Leave>>((ref) {
  return ref.watch(leaveServiceProvider).getLeaves(status: 'PENDING');
});

@RoutePage()
class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({Key? key}) : super(key: key);

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    Leave leave,
    bool isApprove,
  ) {
    final _remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle : Icons.cancel,
              color: isApprove ? Colors.green : Colors.red,
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
              controller: _remarksController,
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
              backgroundColor: isApprove ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              try {
                if (isApprove) {
                  await ref
                      .read(leaveServiceProvider)
                      .approveLeave(leave.id, _remarksController.text);
                } else {
                  await ref
                      .read(leaveServiceProvider)
                      .rejectLeave(leave.id, _remarksController.text);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Leave request ${isApprove ? 'approved' : 'rejected'} successfully',
                      ),
                      backgroundColor: isApprove ? Colors.green : Colors.red,
                    ),
                  );
                }
                ref.invalidate(pendingLeavesProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e))));
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
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(16)),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${leave.type} LEAVE',
                                style: const TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Text(
                              'PENDING',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
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
                          style: TextStyle(color: Colors.grey.shade800),
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
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
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
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
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
