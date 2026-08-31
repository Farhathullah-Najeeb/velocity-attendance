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

final pendingWfhProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(attendanceServiceProvider).getWfhRequests(status: 'PENDING');
});

final pendingRegularizationProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(attendanceServiceProvider).getPendingRegularizations();
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
  int _selectedTabIndex = 0; // 0 for Exceptions, 1 for WFH, 2 for Regularizations
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
    return AppScaffold(
      body: Column(
        children: [
          // Modern Segmented Tab Bar Banner
          Container(
            decoration: const BoxDecoration(
              color: VelocityColors.baseWhite,
              border: Border(
                bottom: BorderSide(color: VelocityColors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VelocityColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VelocityColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      title: 'Exceptions',
                      icon: Icons.warning_amber_rounded,
                      isSelected: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      title: 'WFH Requests',
                      icon: Icons.home_work_outlined,
                      isSelected: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      title: 'Regularization',
                      icon: Icons.update_rounded,
                      isSelected: _selectedTabIndex == 2,
                      onTap: () => setState(() => _selectedTabIndex = 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildSelectedTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTab() {
    if (_selectedTabIndex == 0) {
      return _buildExceptionsTab();
    } else if (_selectedTabIndex == 1) {
      return const _WfhApprovalsTab();
    } else {
      return const _RegularizationApprovalsTab();
    }
  }

  Widget _buildExceptionsTab() {
    final asyncData = ref.watch(pendingAttendanceProvider);
    return RefreshIndicator(
        color: VelocityColors.primaryRed,
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
                // Top Summary Header Banner
                SliverToBoxAdapter(
                  child: Container(
                    color: VelocityColors.baseWhite,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: VelocityColors.warningBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: VelocityColors.warning,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Attendance Exceptions Review',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: VelocityColors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Review and resolve employee late check-ins and early departures.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: VelocityColors.textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats Summary Metric Chips
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMetricChip(
                                label: 'All Exceptions',
                                count: records.length,
                                isSelected: _selectedFilter == 'ALL',
                                color: VelocityColors.primaryRed,
                                onTap: () =>
                                    setState(() => _selectedFilter = 'ALL'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryMetricChip(
                                label: 'Late Arrivals',
                                count: lateRecords.length,
                                isSelected: _selectedFilter == 'LATE',
                                color: VelocityColors.warning,
                                onTap: () =>
                                    setState(() => _selectedFilter = 'LATE'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryMetricChip(
                                label: 'Early Exits',
                                count: earlyRecords.length,
                                isSelected: _selectedFilter == 'EARLY',
                                color: VelocityColors.purple,
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
                  child: Divider(height: 1, color: VelocityColors.border),
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: VelocityColors.successBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_outlined,
                                size: 48,
                                color: VelocityColors.success,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All Clear & Caught Up!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: VelocityColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedFilter == 'ALL'
                                  ? 'There are no pending attendance exceptions to review.'
                                  : 'No $_selectedFilter exceptions pending review.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: VelocityColors.textSubtle,
                                fontSize: 13,
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
                      basePadding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
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
      );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? VelocityColors.baseWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? VelocityColors.cardShadow : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? VelocityColors.primaryRed
                  : VelocityColors.textSubtle,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? VelocityColors.primaryRed
                      : VelocityColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WfhApprovalsTab extends ConsumerWidget {
  const _WfhApprovalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pendingWfhProvider);
    return RefreshIndicator(
      color: VelocityColors.primaryRed,
      onRefresh: () async => ref.invalidate(pendingWfhProvider),
      child: asyncData.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Pending WFH Requests',
              message: 'All work-from-home applications have been processed.',
              icon: Icons.home_work_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final name = req['employeeId']?['name'] ?? 'Unknown Employee';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VelocityColors.baseWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VelocityColors.border),
                  boxShadow: VelocityColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VelocityColors.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.home_work_outlined, color: VelocityColors.info, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: VelocityColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Date: ${req['dateStr']} • ${req['reason'] ?? "No reason specified"}', style: const TextStyle(fontSize: 12.5, color: VelocityColors.textSubtle)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Approve WFH',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: VelocityColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VelocityColors.successBorder),
                            ),
                            child: const Icon(Icons.check, color: VelocityColors.success, size: 18),
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(attendanceServiceProvider).approveWfhRequest(req['_id'], 'Approved by Admin');
                              ref.invalidate(pendingWfhProvider);
                              if (context.mounted) SnackbarUtils.showSuccess(context, 'WFH Approved');
                            } catch (e) {
                              if (context.mounted) SnackbarUtils.handleApiError(context, e);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Reject WFH',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: VelocityColors.dangerBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VelocityColors.dangerBorder),
                            ),
                            child: const Icon(Icons.close, color: VelocityColors.danger, size: 18),
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(attendanceServiceProvider).rejectWfhRequest(req['_id'], 'Rejected by Admin');
                              ref.invalidate(pendingWfhProvider);
                              if (context.mounted) SnackbarUtils.showSuccess(context, 'WFH Rejected');
                            } catch (e) {
                              if (context.mounted) SnackbarUtils.handleApiError(context, e);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingStateWidget(),
        error: (e, _) => ErrorStateWidget(error: e.toString(), onRetry: () => ref.invalidate(pendingWfhProvider)),
      ),
    );
  }
}

class _RegularizationApprovalsTab extends ConsumerWidget {
  const _RegularizationApprovalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pendingRegularizationProvider);
    return RefreshIndicator(
      color: VelocityColors.primaryRed,
      onRefresh: () async => ref.invalidate(pendingRegularizationProvider),
      child: asyncData.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Pending Regularizations',
              message: 'All regularization requests have been reviewed.',
              icon: Icons.update_rounded,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final name = req['employeeId']?['name'] ?? 'Unknown Employee';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VelocityColors.baseWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VelocityColors.border),
                  boxShadow: VelocityColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VelocityColors.purpleBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.update_rounded, color: VelocityColors.purple, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: VelocityColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Date: ${req['dateStr']} • ${req['type'] ?? "Regularization"} • ${req['reason'] ?? ""}', style: const TextStyle(fontSize: 12.5, color: VelocityColors.textSubtle)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Approve Regularization',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: VelocityColors.successBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VelocityColors.successBorder),
                            ),
                            child: const Icon(Icons.check, color: VelocityColors.success, size: 18),
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(attendanceServiceProvider).approveRegularizationRequest(req['_id'], 'Approved by Admin');
                              ref.invalidate(pendingRegularizationProvider);
                              if (context.mounted) SnackbarUtils.showSuccess(context, 'Regularization Approved');
                            } catch (e) {
                              if (context.mounted) SnackbarUtils.handleApiError(context, e);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Reject Regularization',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: VelocityColors.dangerBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VelocityColors.dangerBorder),
                            ),
                            child: const Icon(Icons.close, color: VelocityColors.danger, size: 18),
                          ),
                          onPressed: () async {
                            try {
                              await ref.read(attendanceServiceProvider).rejectRegularizationRequest(req['_id'], 'Rejected by Admin');
                              ref.invalidate(pendingRegularizationProvider);
                              if (context.mounted) SnackbarUtils.showSuccess(context, 'Regularization Rejected');
                            } catch (e) {
                              if (context.mounted) SnackbarUtils.handleApiError(context, e);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingStateWidget(),
        error: (e, _) => ErrorStateWidget(error: e.toString(), onRetry: () => ref.invalidate(pendingRegularizationProvider)),
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: VelocityColors.baseWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VelocityColors.border),
        boxShadow: VelocityColors.cardShadow,
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: VelocityColors.primaryRedLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VelocityColors.primaryRedBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    empName.isNotEmpty ? empName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: VelocityColors.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: VelocityColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$empDept ${empEmail.isNotEmpty ? "• $empEmail" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: VelocityColors.textSubtle,
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
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: VelocityColors.warningBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: VelocityColors.warningBorder),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: VelocityColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
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
                    color: VelocityColors.warning,
                  ),
                if (isEarly)
                  _BadgePill(
                    icon: Icons.logout,
                    label: record.earlyExitMinutes != null &&
                            record.earlyExitMinutes! > 0
                        ? 'EARLY CHECKOUT (-${record.earlyExitMinutes}m)'
                        : 'EARLY CHECKOUT',
                    color: VelocityColors.purple,
                  ),
                _BadgePill(
                  icon: Icons.calendar_today_outlined,
                  label: record.dateStr,
                  color: VelocityColors.textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Timing Metric Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: VelocityColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VelocityColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.login_rounded,
                              size: 13,
                              color: VelocityColors.success,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'CHECK IN',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: VelocityColors.textSubtle,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inTimeFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: VelocityColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: VelocityColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.logout_rounded,
                              size: 13,
                              color: VelocityColors.warning,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'CHECK OUT',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: VelocityColors.textSubtle,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          outTimeFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: VelocityColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: VelocityColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.timelapse_rounded,
                              size: 13,
                              color: VelocityColors.primaryRed,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'DURATION',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: VelocityColors.textSubtle,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: VelocityColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (record.remarks != null && record.remarks!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VelocityColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: VelocityColors.warningBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 15,
                      color: VelocityColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.remarks!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: VelocityColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: VelocityColors.divider),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VelocityColors.danger,
                      side: const BorderSide(
                        color: VelocityColors.dangerBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VelocityColors.success,
                      foregroundColor: VelocityColors.baseWhite,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : VelocityColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : VelocityColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : VelocityColors.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : VelocityColors.textSubtle,
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
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : Theme.of(context).unselectedWidgetColor,
            ),
          ],
        ),
      ),
    );
  }
}
