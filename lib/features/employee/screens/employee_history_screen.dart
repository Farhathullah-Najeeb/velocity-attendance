import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/services/attendance_service.dart';
import '../../../models/attendance.dart';
import '../../shared/widgets/states.dart';
import '../../auth/providers/auth_provider.dart';

final dateRangeProvider = StateProvider.autoDispose<DateTimeRange?>((ref) => null);

final historyListProvider = FutureProvider.autoDispose<List<Attendance>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final range = ref.watch(dateRangeProvider);
  String? startDate;
  String? endDate;
  if (range != null) {
    startDate = DateFormat('yyyy-MM-dd').format(range.start);
    endDate = DateFormat('yyyy-MM-dd').format(range.end);
  }
  return ref.watch(attendanceServiceProvider).getHistory(user.id, startDate: startDate, endDate: endDate);
});

@RoutePage()
class EmployeeHistoryScreen extends ConsumerStatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  ConsumerState<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends ConsumerState<EmployeeHistoryScreen> {
  int _selectedTabIndex = 0; // 0 for Attendance Log, 1 for Summary & Exports

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyListProvider);

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'View daily work logs, analyze attendance stats, and export timesheets.',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 16, color: _selectedTabIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 8),
                              Text('Attendance Log', style: TextStyle(color: _selectedTabIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bar_chart, size: 16, color: _selectedTabIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 8),
                              Text('Summary & Exports', style: TextStyle(color: _selectedTabIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_selectedTabIndex == 0) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final currentRange = ref.read(dateRangeProvider);
                        final newRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: currentRange,
                        );
                        if (newRange != null) {
                          ref.read(dateRangeProvider.notifier).state = newRange;
                        }
                      },
                      icon: const Icon(Icons.filter_alt_outlined, color: Colors.black87),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Filter Logs', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          if (ref.watch(dateRangeProvider) != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                              child: Text('1', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final range = ref.watch(dateRangeProvider);
                        if (range == null) return const SizedBox.shrink();
                        
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Theme.of(context).dividerColor),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                    ),
                                    child: Text(DateFormat('d MMM').format(range.start), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('to', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Theme.of(context).dividerColor),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                    ),
                                    child: Text(DateFormat('d MMM').format(range.end), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    ref.read(dateRangeProvider.notifier).state = null;
                                  },
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                  child: Text('Reset', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(historyListProvider),
                child: historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return ListView(
                        children: const [
                          EmptyStateWidget(
                            title: 'No History',
                            message: 'Your attendance history will appear here once you start checking in.',
                            icon: Icons.history,
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20)),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(history[index]);
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
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Summary & Exports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text('Analytics coming soon.', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Attendance record) {
    String formatTime(String timeStr) {
      if (timeStr == '--:--' || timeStr == '--' || timeStr.isEmpty) return timeStr;
      try {
        final dt = DateTime.parse(timeStr).toLocal();
        return DateFormat.jm().format(dt).toLowerCase();
      } catch (_) {
        return timeStr;
      }
    }

    final inTime = record.checkInTime.isNotEmpty ? formatTime(record.checkInTime) : '--:--';
    final outTime = record.checkOutTime != null ? formatTime(record.checkOutTime!) : '—';
    final duration = record.formattedWorkTime ?? (record.workDurationMinutes != null ? '${record.workDurationMinutes}m' : '—');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(record.dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Text('TIMINGS', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('In: ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
              Text(inTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
              Text(' | Out: ', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
              Text(outTime, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          Text('DURATION', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(duration, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          Text('STATUS DETAILS', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          if (record.isLateArrival == true || record.isEarlyCheckout == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                record.isLateArrival == true ? 'LATE' : 'EARLY EXIT',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'ON TIME',
                style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
