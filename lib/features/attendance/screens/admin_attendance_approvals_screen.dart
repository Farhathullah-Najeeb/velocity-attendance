import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../../../models/attendance.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/states.dart';

final pendingAttendanceProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) {
      return ref.watch(attendanceServiceProvider).getPendingApprovals();
    });

@RoutePage()
class AdminAttendanceApprovalsScreen extends ConsumerStatefulWidget {
  const AdminAttendanceApprovalsScreen({super.key});

  @override
  ConsumerState<AdminAttendanceApprovalsScreen> createState() =>
      _AdminAttendanceApprovalsScreenState();
}

class _AdminAttendanceApprovalsScreenState
    extends ConsumerState<AdminAttendanceApprovalsScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'LATE', 'EARLY'

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    Attendance record,
    bool isApprove,
  ) {
    final remarksController = TextEditingController();
    String penaltyType = 'NONE'; // NONE, RED_MARK, HALF_DAY
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final empName = record.employeeId is Map
              ? (record.employeeId['name'] ?? 'Employee')
              : 'Employee';

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isApprove
                        ? VelocityColors.success.withValues(alpha: 0.1)
                        : VelocityColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isApprove ? Icons.check_circle : Icons.cancel_outlined,
                    color: isApprove
                        ? VelocityColors.success
                        : VelocityColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isApprove ? 'Approve Exception' : 'Reject Exception',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review attendance exception for $empName on ${record.dateStr}.',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (isApprove) ...[
                    const Text(
                      'APPLY PENALTY POLICY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PenaltyOptionTile(
                      title: 'Standard Approval (No Penalty)',
                      subtitle: 'Full day marked as valid without penalties',
                      icon: Icons.check_circle_outline,
                      color: VelocityColors.success,
                      isSelected: penaltyType == 'NONE',
                      onTap: () => setDialogState(() => penaltyType = 'NONE'),
                    ),
                    const SizedBox(height: 8),
                    _PenaltyOptionTile(
                      title: 'Red Mark (Warning)',
                      subtitle: 'Approve hours but record a disciplinary warning flag',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                      isSelected: penaltyType == 'RED_MARK',
                      onTap: () =>
                          setDialogState(() => penaltyType = 'RED_MARK'),
                    ),
                    const SizedBox(height: 8),
                    _PenaltyOptionTile(
                      title: 'Half Day Deduction',
                      subtitle: 'Deduct 0.5 day wage/quota for significant delay',
                      icon: Icons.hourglass_bottom,
                      color: VelocityColors.error,
                      isSelected: penaltyType == 'HALF_DAY',
                      onTap: () =>
                          setDialogState(() => penaltyType = 'HALF_DAY'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'REMARKS / AUDIT NOTE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      hintText: isApprove
                          ? 'Optional note (e.g. Traffic delay pre-informed)'
                          : 'Reason for rejection (Required)',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApprove
                      ? VelocityColors.success
                      : VelocityColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (!isApprove &&
                            remarksController.text.trim().isEmpty) {
                          SnackbarUtils.showError(
                            dialogCtx,
                            'Please provide remarks for rejecting this exception.',
                          );
                          return;
                        }

                        setDialogState(() => isProcessing = true);
                        try {
                          if (isApprove) {
                            await ref
                                .read(attendanceServiceProvider)
                                .approveAttendance(
                                  record.id,
                                  remarksController.text.trim(),
                                  penaltyType,
                                );
                          } else {
                            await ref
                                .read(attendanceServiceProvider)
                                .rejectAttendance(
                                  record.id,
                                  remarksController.text.trim(),
                                );
                          }

                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            SnackbarUtils.showSuccess(
                              dialogCtx,
                              'Attendance exception ${isApprove ? 'approved' : 'rejected'} successfully',
                            );
                          }
                          ref.invalidate(pendingAttendanceProvider);
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            SnackbarUtils.handleApiError(dialogCtx, e);
                          }
                        } finally {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isProcessing = false);
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isApprove ? 'Confirm Approval' : 'Reject Exception'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(pendingAttendanceProvider);

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pendingAttendanceProvider),
        child: asyncData.when(
          data: (records) {
            final lateRecords =
                records.where((r) => r.isLateArrival == true).toList();
            final earlyRecords =
                records.where((r) => r.isEarlyCheckout == true).toList();

            final filteredRecords = records.where((r) {
              if (_selectedFilter == 'LATE') {
                return r.isLateArrival == true;
              }
              if (_selectedFilter == 'EARLY') {
                return r.isEarlyCheckout == true;
              }
              return true;
            }).toList();

            return CustomScrollView(
              slivers: [
                // Top Summary Header
                SliverToBoxAdapter(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade800,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Attendance Exceptions Review',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Review and resolve late check-ins and early departures.',
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

                        // Stats Summary Row
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMetricChip(
                                label: 'All Exceptions',
                                count: records.length,
                                isSelected: _selectedFilter == 'ALL',
                                color: Theme.of(context).colorScheme.primary,
                                onTap: () =>
                                    setState(() => _selectedFilter = 'ALL'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryMetricChip(
                                label: 'Late Arrivals',
                                count: lateRecords.length,
                                isSelected: _selectedFilter == 'LATE',
                                color: Colors.deepOrange,
                                onTap: () =>
                                    setState(() => _selectedFilter = 'LATE'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryMetricChip(
                                label: 'Early Exits',
                                count: earlyRecords.length,
                                isSelected: _selectedFilter == 'EARLY',
                                color: Colors.purple,
                                onTap: () =>
                                    setState(() => _selectedFilter = 'EARLY'),
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

                if (filteredRecords.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_outlined,
                                size: 54,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All Clear & Caught Up!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'ALL'
                                  ? 'There are no pending attendance exceptions to review.'
                                  : 'No $_selectedFilter exceptions pending review.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: AppScaffold.getScrollPadding(
                      context,
                      basePadding: const EdgeInsets.all(16),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final record = filteredRecords[index];
                          return _ExceptionCard(
                            record: record,
                            onApprove: () => _showApprovalDialog(
                              context,
                              ref,
                              record,
                              true,
                            ),
                            onReject: () => _showApprovalDialog(
                              context,
                              ref,
                              record,
                              false,
                            ),
                          );
                        },
                        childCount: filteredRecords.length,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const LoadingStateWidget(),
          error: (err, stack) => ErrorStateWidget(
            error: err.toString(),
            onRetry: () => ref.invalidate(pendingAttendanceProvider),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// EXCEPTION REVIEW CARD WIDGET
// ==========================================
class _ExceptionCard extends StatelessWidget {
  final Attendance record;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ExceptionCard({
    required this.record,
    required this.onApprove,
    required this.onReject,
  });

  String _formatTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty || isoTime == '--:--') return '—';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final empName = record.employeeId is Map
        ? (record.employeeId['name'] ?? 'Unknown Employee')
        : 'Employee ID: ${record.employeeId}';

    final empEmail = record.employeeId is Map
        ? (record.employeeId['email'] ?? '')
        : '';

    final empDept = record.employeeId is Map
        ? (record.employeeId['department'] ?? 'General')
        : 'General';

    final isLate = record.isLateArrival == true;
    final isEarly = record.isEarlyCheckout == true;

    final inTimeFormatted = _formatTime(record.checkInTime);
    final outTimeFormatted = _formatTime(record.checkOutTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Employee info + Exception tags
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    empName.isNotEmpty ? empName[0].toUpperCase() : 'E',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                        empName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$empDept ${empEmail.isNotEmpty ? "• $empEmail" : ""}',
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exception Type Badge Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isLate)
                  _BadgePill(
                    icon: Icons.schedule,
                    label: record.lateMinutes != null && record.lateMinutes! > 0
                        ? 'LATE ARRIVAL (+${record.lateMinutes}m)'
                        : 'LATE ARRIVAL',
                    color: Colors.deepOrange,
                  ),
                if (isEarly)
                  _BadgePill(
                    icon: Icons.logout,
                    label: record.earlyExitMinutes != null &&
                            record.earlyExitMinutes! > 0
                        ? 'EARLY CHECKOUT (-${record.earlyExitMinutes}m)'
                        : 'EARLY CHECKOUT',
                    color: Colors.purple,
                  ),
                _BadgePill(
                  icon: Icons.calendar_today,
                  label: record.dateStr,
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Timing Metric Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.login,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CHECK IN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inTimeFormatted,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CHECK OUT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          outTimeFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timelapse,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DURATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.formattedWorkTime ??
                              (record.workDurationMinutes != null
                                  ? '${record.workDurationMinutes}m'
                                  : '—'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (record.remarks != null && record.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.remarks!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VelocityColors.error,
                      side: BorderSide(
                        color: VelocityColors.error.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VelocityColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SummaryMetricChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Theme.of(context).hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PenaltyOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PenaltyOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
