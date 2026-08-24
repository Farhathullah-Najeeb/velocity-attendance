import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/overtime_service.dart';
import '../../../models/overtime.dart';
import '../../shared/widgets/states.dart';

final adminOvertimeProvider = FutureProvider.autoDispose<List<Overtime>>((ref) {
  return ref.watch(overtimeServiceProvider).getAllOvertime(status: 'PENDING');
});

@RoutePage()
class AdminOvertimeScreen extends ConsumerWidget {
  const AdminOvertimeScreen({super.key});

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    Overtime record,
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
              color: isApprove ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isApprove ? 'Approve Overtime' : 'Reject Overtime'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${isApprove ? 'approve' : 'reject'} this overtime request?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
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
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref
                    .read(overtimeServiceProvider)
                    .updateOvertimeStatus(
                      record.id,
                      isApprove ? 'APPROVED' : 'REJECTED',
                      remarksController.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Overtime request ${isApprove ? 'approved' : 'rejected'}',
                      ),
                      backgroundColor: isApprove ? Colors.green : Colors.red,
                    ),
                  );
                }
                ref.invalidate(adminOvertimeProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ErrorHandler.getUserMessage(e))),
                  );
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
    final asyncData = ref.watch(adminOvertimeProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Overtime Approvals')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminOvertimeProvider);
        },
        child: asyncData.when(
          data: (records) {
            if (records.isEmpty) {
              return const EmptyStateWidget(
                title: 'All caught up!',
                message: 'No pending overtime approvals at the moment.',
                icon: Icons.fact_check_outlined,
              );
            }
            return ListView.builder(
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(16)),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
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
                            Text(
                              record.employeeId is Map
                                  ? (record.employeeId['name'] ?? 'Unknown')
                                  : 'Employee ID: ${record.employeeId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
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
                              record.dateStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${record.overtimeMinutes} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        if (record.reason != null &&
                            record.reason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            record.reason!,
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showApprovalDialog(
                                context,
                                ref,
                                record,
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
                                record,
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
            onRetry: () => ref.invalidate(adminOvertimeProvider),
          ),
        ),
      ),
    );
  }
}

