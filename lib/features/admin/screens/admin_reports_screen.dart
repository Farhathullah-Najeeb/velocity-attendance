import 'dart:io';
import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../attendance/services/attendance_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/states.dart';

typedef AdminReportParams = ({String type, String? startDate, String? endDate});

final adminReportDataProvider =
    FutureProvider.family.autoDispose<Map<String, dynamic>, AdminReportParams>(
  (ref, params) async {
    final type = params.type;
    final startDate = params.startDate;
    final endDate = params.endDate;
    final service = ref.watch(attendanceServiceProvider);

    if (type == 'MONTHLY') {
      return service.getMonthlyReport();
    } else if (type == 'CUSTOM' && startDate != null && endDate != null) {
      return service.getCustomReport(startDate: startDate, endDate: endDate);
    } else {
      return service.getWeeklyReport();
    }
  },
);

@RoutePage()
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedReportType = 'WEEKLY'; // 'WEEKLY', 'MONTHLY', 'CUSTOM'
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedReportType = 'CUSTOM';
      });
    }
  }

  Future<void> _exportReport(String format) async {
    if (_selectedReportType == 'CUSTOM' &&
        (_startDate == null || _endDate == null)) {
      SnackbarUtils.showError(
        context,
        'Please select a valid date range for the custom report',
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final df = DateFormat('yyyy-MM-dd');
      final bytes = await ref.read(attendanceServiceProvider).exportReport(
            format: format.toLowerCase(),
            type: _selectedReportType == 'CUSTOM'
                ? null
                : _selectedReportType.toLowerCase(),
            startDate: _startDate != null ? df.format(_startDate!) : null,
            endDate: _endDate != null ? df.format(_endDate!) : null,
          );

      final ext = format.toLowerCase() == 'pdf' ? 'pdf' : 'xlsx';
      final mimeType = format.toLowerCase() == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final fileName =
          'attendance_report_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (kIsWeb) {
        await SharePlus.instance.share(ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: fileName,
              mimeType: mimeType,
            ),
          ],
        ));
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        await SharePlus.instance.share(ShareParams(
          files: [
            XFile(file.path, mimeType: mimeType),
          ],
          subject: 'Attendance & Total Work Hours Report',
        ));
      }

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Report exported successfully as ${format.toUpperCase()}',
        );
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    final queryParams = (
      type: _selectedReportType,
      startDate: _startDate != null ? df.format(_startDate!) : null,
      endDate: _endDate != null ? df.format(_endDate!) : null,
    );

    final reportAsync = ref.watch(adminReportDataProvider(queryParams));

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(adminReportDataProvider(queryParams)),
        child: CustomScrollView(
          slivers: [
            // Top Controls & Summary Bar
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Employee Work Hours & Attendance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Comprehensive tracking of total work hours, presence, and delays per staff member.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time Period Selector Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: VelocityColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: VelocityColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PeriodTab(
                              title: 'Weekly',
                              icon: Icons.view_week_outlined,
                              isSelected: _selectedReportType == 'WEEKLY',
                              onTap: () =>
                                  setState(() => _selectedReportType = 'WEEKLY'),
                            ),
                          ),
                          Expanded(
                            child: _PeriodTab(
                              title: 'Monthly',
                              icon: Icons.calendar_month_outlined,
                              isSelected: _selectedReportType == 'MONTHLY',
                              onTap: () =>
                                  setState(() => _selectedReportType = 'MONTHLY'),
                            ),
                          ),
                          Expanded(
                            child: _PeriodTab(
                              title: 'Custom',
                              icon: Icons.date_range_outlined,
                              isSelected: _selectedReportType == 'CUSTOM',
                              onTap: () {
                                setState(() => _selectedReportType = 'CUSTOM');
                                if (_startDate == null) {
                                  _pickDateRange();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_selectedReportType == 'CUSTOM') ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: VelocityColors.surfaceAlt,
                            border: Border.all(color: VelocityColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: VelocityColors.primaryRed,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _startDate != null && _endDate != null
                                      ? '${df.format(_startDate!)} to ${df.format(_endDate!)}'
                                      : 'Click to select custom date range',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: VelocityColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.edit,
                                size: 16,
                                color: VelocityColors.textSubtle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Search & Export Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: VelocityColors.baseWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VelocityColors.border),
                            ),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search employee name / ID...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: VelocityColors.textMuted,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: VelocityColors.textSubtle,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VelocityColors.primaryRed,
                            foregroundColor: VelocityColors.baseWhite,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isExporting ? null : () => _exportReport('PDF'),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: const Text(
                            'PDF',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VelocityColors.textPrimary,
                            side: const BorderSide(color: VelocityColors.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isExporting ? null : () => _exportReport('EXCEL'),
                          icon: const Icon(Icons.table_chart_outlined, size: 16),
                          label: const Text(
                            'Excel',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Divider(height: 1),
            ),

            // Employee Work Hours List
            reportAsync.when(
              data: (data) {
                // Extract items list safely from possible structures
                List<dynamic> items = [];
                if (data['report'] is List) {
                  items = data['report'];
                } else if (data['data'] is List) {
                  items = data['data'];
                } else if (data['employees'] is List) {
                  items = data['employees'];
                } else if (data['items'] is List) {
                  items = data['items'];
                } else if (data['summary'] is List) {
                  items = data['summary'];
                }

                final filtered = items.where((item) {
                  if (_searchQuery.trim().isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final name = (item['employeeName'] ??
                          item['name'] ??
                          item['employee']?['name'] ??
                          '')
                      .toString()
                      .toLowerCase();
                  final dept = (item['department'] ??
                          item['employee']?['department'] ??
                          '')
                      .toString()
                      .toLowerCase();
                  return name.contains(q) || dept.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              size: 54,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Work Hours Data Recorded',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No employee attendance sessions were logged in this time range.',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: AppScaffold.getScrollPadding(
                    context,
                    basePadding: const EdgeInsets.all(16.0),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final emp = filtered[index];
                        return _EmployeeWorkHoursCard(empData: emp);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingStateWidget(),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(
                  error: ErrorHandler.getUserMessage(err),
                  onRetry: () =>
                      ref.invalidate(adminReportDataProvider(queryParams)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeWorkHoursCard extends StatelessWidget {
  final dynamic empData;
  const _EmployeeWorkHoursCard({required this.empData});

  @override
  Widget build(BuildContext context) {
    final name = (empData['employeeName'] ??
            empData['name'] ??
            empData['employee']?['name'] ??
            'Employee')
        .toString();

    final dept = (empData['department'] ??
            empData['employee']?['department'] ??
            'General')
        .toString();

    final email = (empData['email'] ??
            empData['employee']?['email'] ??
            '')
        .toString();

    // Total Work Hours
    final totalHours = (empData['totalWorkHours'] ??
            empData['workHours'] ??
            empData['totalHours'] ??
            0)
        .toString();

    final formattedHours = empData['formattedWorkTime'] ??
        '${double.tryParse(totalHours)?.toStringAsFixed(1) ?? totalHours} hrs';

    // Days Present
    final daysPresent = empData['daysPresent'] ??
        empData['totalDaysPresent'] ??
        empData['presentDays'] ??
        empData['attendanceCount'] ??
        '—';

    // Late Arrivals
    final lateCount = empData['lateArrivalsCount'] ??
        empData['lateCount'] ??
        empData['totalLate'] ??
        0;

    // Early Exits
    final earlyCount = empData['earlyCheckoutsCount'] ??
        empData['earlyCount'] ??
        empData['totalEarly'] ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Info Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dept ${email.isNotEmpty ? "• $email" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Work Hours & Stats Metric Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  // Total Work Hours
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'TOTAL WORK HOURS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedHours,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),

                  // Days Present
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAYS PRESENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$daysPresent days',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),

                  // Exceptions (Late / Early)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXCEPTIONS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (lateCount > 0)
                                Text(
                                  '${lateCount}L ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              if (earlyCount > 0)
                                Text(
                                  '${earlyCount}E',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              if (lateCount == 0 && earlyCount == 0)
                                const Text(
                                  'None (0)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: VelocityColors.success,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? VelocityColors.baseWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? VelocityColors.cardShadow : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? VelocityColors.primaryRed
                  : VelocityColors.textSubtle,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? VelocityColors.primaryRed
                    : VelocityColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
