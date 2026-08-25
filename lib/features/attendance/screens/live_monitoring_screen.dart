import 'package:auto_route/auto_route.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../../../models/attendance.dart';
import '../../shared/widgets/states.dart';

final liveMonitoringProvider = FutureProvider.family.autoDispose<List<Attendance>, String?>((ref, date) {
  return ref.watch(attendanceServiceProvider).getLiveMonitoring(date);
});

@RoutePage()
class LiveMonitoringScreen extends ConsumerStatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  ConsumerState<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends ConsumerState<LiveMonitoringScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final asyncData = ref.watch(liveMonitoringProvider(dateStr));

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary, size: 16),
                  label: Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(liveMonitoringProvider(dateStr));
              },
              child: asyncData.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No Data',
                      message: 'No WFH or Overtime locations recorded for this date.',
                      icon: Icons.location_off,
                    );
                  }
                  return ListView.builder(
                    padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(16)),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final isWFH = record.isWFH == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isWFH ? Colors.purple.shade50 : Colors.blue.shade50,
                            child: Icon(isWFH ? Icons.home : Icons.timer, color: isWFH ? Colors.purple : Colors.blue),
                          ),
                          title: Text(record.employeeId is Map ? (record.employeeId['name'] ?? 'Unknown') : 'Employee ID: ${record.employeeId}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Check In: ${record.checkInTime}'),
                              if (record.checkOutTime != null) Text('Check Out: ${record.checkOutTime}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isWFH ? Colors.purple.shade100 : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isWFH ? 'WFH' : 'OVERTIME',
                              style: TextStyle(
                                color: isWFH ? Colors.purple.shade800 : Colors.blue.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingStateWidget(),
                error: (err, stack) => ErrorStateWidget(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(liveMonitoringProvider(dateStr)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
