import 'package:auto_route/auto_route.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/services/attendance_service.dart';
import '../../../models/attendance.dart';
import '../../shared/widgets/states.dart';
import '../../auth/providers/auth_provider.dart';

final historyListProvider = FutureProvider.autoDispose<List<Attendance>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.watch(attendanceServiceProvider).getHistory(user.id);
});

@RoutePage()
class EmployeeHistoryScreen extends ConsumerWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyListProvider);
        },
        child: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return const EmptyStateWidget(
                title: 'No History',
                message: 'Your attendance history will appear here once you start checking in.',
                icon: Icons.history,
              );
            }
            return ListView.builder(
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24)),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
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
                              record.dateStr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (record.isLateArrival == true || record.isEarlyCheckout == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  record.isLateArrival == true ? 'LATE' : 'EARLY EXIT',
                                  style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  'ON TIME',
                                  style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _TimeColumn(label: 'Check In', time: record.checkInTime),
                            _TimeColumn(label: 'Check Out', time: record.checkOutTime ?? '--:--'),
                            _TimeColumn(
                              label: 'Duration', 
                              time: record.formattedWorkTime ?? (record.workDurationMinutes != null ? '${record.workDurationMinutes}m' : '--'),
                              isHighlight: true,
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
            onRetry: () => ref.invalidate(historyListProvider),
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String label;
  final String time;
  final bool isHighlight;

  const _TimeColumn({required this.label, required this.time, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}

