import 'package:auto_route/auto_route.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/overtime_service.dart';
import '../../../models/overtime.dart';
import '../../shared/widgets/states.dart';

import '../../../features/auth/providers/auth_provider.dart';

final myOvertimeProvider = FutureProvider.autoDispose<List<Overtime>>((
  ref,
) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.watch(overtimeServiceProvider).getAllOvertime(employeeId: user.id);
});

@RoutePage()
class EmployeeOvertimeScreen extends ConsumerWidget {
  const EmployeeOvertimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(myOvertimeProvider);

    return AppScaffold(
      backgroundColor: Colors.white, // Match other screens
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOvertimeProvider);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'My Overtime',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: asyncData.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Overtime',
                      message: 'You have not submitted any overtime requests.',
                      icon: Icons.timer_off_outlined,
                    );
                  }
                  return ListView.builder(
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(16)),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];

                      Color statusColor;
                      switch (record.status.toUpperCase()) {
                        case 'APPROVED':
                          statusColor = Colors.green;
                          break;
                        case 'REJECTED':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.orange;
                          break;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    record.dateStr,
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
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      record.status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
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
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${record.overtimeMinutes} minutes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (record.reason != null &&
                                  record.reason!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: ${record.reason}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                              if (record.remarks != null &&
                                  record.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Admin Remarks: ${record.remarks}',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
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
                  onRetry: () => ref.invalidate(myOvertimeProvider),
                ), // Closes ErrorStateWidget
              ), // Closes asyncData.when
            ), // Closes Expanded
          ], // Closes Column children
        ), // Closes Column
      ), // Closes RefreshIndicator
    ); // Closes Scaffold
  }
}
