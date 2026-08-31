import 'package:auto_route/auto_route.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance/services/attendance_service.dart';
import '../../../models/attendance.dart';
import '../../shared/widgets/states.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/velocity_colors.dart';

final dateRangeProvider =
    StateProvider.autoDispose<DateTimeRange?>((ref) => null);

final historyListProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) {
      final user = ref.watch(authProvider).user;
      if (user == null) return [];
      final range = ref.watch(dateRangeProvider);
      String? startDate;
      String? endDate;
      if (range != null) {
        startDate = DateFormat('yyyy-MM-dd').format(range.start);
        endDate = DateFormat('yyyy-MM-dd').format(range.end);
      }
      return ref
          .watch(attendanceServiceProvider)
          .getHistory(user.id, startDate: startDate, endDate: endDate);
    });

@RoutePage()
class EmployeeHistoryScreen extends ConsumerStatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  ConsumerState<EmployeeHistoryScreen> createState() =>
      _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState
    extends ConsumerState<EmployeeHistoryScreen> {
  int _selectedTabIndex = 0; // 0 for Attendance Log, 1 for Summary & Exports

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyListProvider);
    final isDesktop = kIsWeb && MediaQuery.of(context).size.width > 800;

    return AppScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 16,
            isDesktop ? 20 : 16,
            isDesktop ? 24 : 16,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 28,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Attendance History & Logs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'View daily work logs, analyze attendance stats, and export timesheets',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

              // Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? VelocityColors.primaryRed
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Attendance Log',
                                style: TextStyle(
                                  color: _selectedTabIndex == 0
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? VelocityColors.primaryRed
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 16,
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Summary & Exports',
                                style: TextStyle(
                                  color: _selectedTabIndex == 1
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedTabIndex == 0) ...[
                const SizedBox(height: 20),
                // Filter controls
                Row(
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
                          ref.read(dateRangeProvider.notifier).state =
                              newRange;
                        }
                      },
                      icon: const Icon(
                        Icons.filter_alt_outlined,
                        color: Color(0xFF0F172A),
                        size: 18,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Filter Logs',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (ref.watch(dateRangeProvider) != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: VelocityColors.primaryRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                    if (ref.watch(dateRangeProvider) != null) ...[
                      const SizedBox(width: 12),
                      Builder(
                        builder: (context) {
                          final range = ref.watch(dateRangeProvider)!;
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  '${DateFormat('d MMM yyyy').format(range.start)} → ${DateFormat('d MMM yyyy').format(range.end)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => ref
                                    .read(dateRangeProvider.notifier)
                                    .state = null,
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    color: VelocityColors.primaryRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Table / List Content
                historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'No attendance history records found.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section Title & Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              color: Colors.white,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: VelocityColors.primaryRed.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.list_alt_rounded,
                                      size: 16,
                                      color: VelocityColors.primaryRed,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'ATTENDANCE LOGS',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${history.length} RECORDS',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),

                            // Table Header Row & Body
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: isDesktop ? 600 : 500,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: isDesktop ? 800 : 550,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      color: const Color(0xFFF8FAFC),
                                      child: Row(
                                        children: [
                                          _desktopHeader('DATE', flex: 2),
                                          _desktopHeader('CHECK IN', flex: 2),
                                          _desktopHeader('CHECK OUT', flex: 2),
                                          _desktopHeader('DURATION', flex: 2),
                                          _desktopHeader('STATUS', flex: 2),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    SizedBox(
                                      width: isDesktop ? 800 : 550,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: history.length,
                                        separatorBuilder: (context, index) => const Divider(
                                          height: 1,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                        itemBuilder: (context, index) {
                                          return _buildDesktopHistoryRow(
                                            history[index],
                                            index == history.length - 1,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LoadingStateWidget(),
                  ),
                  error: (err, stack) => ErrorStateWidget(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(historyListProvider),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 56,
                        color: Color(0xFFCBD5E1),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Summary & Exports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Detailed monthly analytics and report export coming soon.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildDesktopHistoryRow(Attendance record, bool isLast) {
    String formatTime(String timeStr) {
      if (timeStr == '--:--' || timeStr == '--' || timeStr.isEmpty) return '—';
      try {
        final dt = DateTime.parse(timeStr).toLocal();
        return DateFormat.jm().format(dt).toLowerCase();
      } catch (_) {
        return timeStr;
      }
    }

    final inTime = record.checkInTime.isNotEmpty
        ? formatTime(record.checkInTime)
        : '—';
    final outTime = record.checkOutTime != null
        ? formatTime(record.checkOutTime!)
        : '—';
    final duration = record.formattedWorkTime ??
        (record.workDurationMinutes != null
            ? '${record.workDurationMinutes}m'
            : '—');
    final isLate = record.isLateArrival == true;
    final isEarly = record.isEarlyCheckout == true;
    final statusText = isLate ? 'LATE' : (isEarly ? 'EARLY EXIT' : 'ON TIME');

    Color badgeBg;
    Color badgeText;
    Color badgeBorder;
    if (isLate || isEarly) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFD97706);
      badgeBorder = const Color(0xFFFDE68A);
    } else {
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = const Color(0xFF059669);
      badgeBorder = const Color(0xFFA7F3D0);
    }

    return _HoverableRow(
      isLast: isLast,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              record.dateStr,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              inTime,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              outTime,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              duration,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: badgeText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverableRow extends StatefulWidget {
  final Widget child;
  final bool isLast;

  const _HoverableRow({required this.child, required this.isLast});

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: _hovered ? const Color(0xFFF8FAFC) : Colors.white,
        child: widget.child,
      ),
    );
  }
}
