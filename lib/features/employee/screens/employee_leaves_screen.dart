import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_app/features/shared/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../leaves/services/leave_service.dart';
import '../../../models/leave.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/leave_balance_cards.dart';
import '../../leaves/widgets/premium_leave_calendar.dart';
import '../../leaves/services/leave_pdf_service.dart';

final leavesListProvider = FutureProvider.autoDispose<List<Leave>>((ref) {
  return ref.watch(leaveServiceProvider).getLeaves();
});

String _formatLeaveDate(String raw) {
  if (raw.isEmpty) return '—';
  try {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('dd MMM yyyy').format(dt);
  } catch (_) {
    return raw;
  }
}

@RoutePage()
class EmployeeLeavesScreen extends ConsumerWidget {
  const EmployeeLeavesScreen({super.key});

  void _showPrintDialog(
    BuildContext context, {
    required String employeeName,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required int totalDays,
    required String reason,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Leave Request Submitted!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your $leaveType application from $fromDate to $toDate ($totalDays day${totalDays > 1 ? 's' : ''}) was submitted successfully.'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to print or download a receipt now?',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Print Receipt'),
            onPressed: () {
              Navigator.pop(ctx);
              LeavePdfService.printLeaveReceipt(
                employeeName: employeeName,
                leaveType: leaveType,
                fromDate: fromDate,
                toDate: toDate,
                totalDays: totalDays,
                reason: reason,
                status: 'PENDING',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      context: context,
      builder: (context) => const _ApplyLeaveDialog(),
    ).then((result) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.invalidate(employeeLeaveBalanceProvider(user.id));
      }
      ref.invalidate(leavesListProvider);

      if (result is Map<String, dynamic> && context.mounted) {
        _showPrintDialog(
          context,
          employeeName: result['employeeName'] ?? (user?.name ?? 'Employee'),
          leaveType: result['leaveType'] ?? 'Leave',
          fromDate: result['fromDate'] ?? '',
          toDate: result['toDate'] ?? '',
          totalDays: result['totalDays'] ?? 1,
          reason: result['reason'] ?? '',
        );
      }
    });
  }

  Future<void> _cancelLeave(
    BuildContext context,
    WidgetRef ref,
    String leaveId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cancel Leave Request',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this leave application? This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Keep It',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(leaveServiceProvider).cancelLeave(leaveId);
        if (context.mounted) {
          SnackbarUtils.showSuccess(context, 'Leave cancelled successfully');
        }
        ref.invalidate(leavesListProvider);
        final user = ref.read(authProvider).user;
        ref.invalidate(employeeLeaveBalanceProvider(user?.id ?? ''));
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.handleApiError(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final leaveBalanceAsync = ref.watch(
      employeeLeaveBalanceProvider(user?.id ?? ''),
    );
    final leavesListAsync = ref.watch(leavesListProvider);
    final isDesktop = kIsWeb && MediaQuery.of(context).size.width > 900;

    return AppScaffold(
      body: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async {
          final user = ref.read(authProvider).user;
          ref.invalidate(employeeLeaveBalanceProvider(user?.id ?? ''));
          ref.invalidate(leavesListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // --- Page Header ---
            if (isDesktop)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Container(
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
                      horizontal: 28,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE53935,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.beach_access_rounded,
                                size: 28,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Leave Management',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Apply for time off and review your previous requests',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE53935,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showApplyLeaveDialog(context, ref),
                              icon: const Icon(Icons.add_rounded, size: 22),
                              label: const Text(
                                'Apply for Leave',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // --- Leave Balance Cards ---
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 28 : 16,
                  isDesktop ? 28 : 16,
                  isDesktop ? 28 : 16,
                  isDesktop ? 28 : 20,
                ),
                child: leaveBalanceAsync.when(
                  data: (balance) => LeaveBalanceCards(
                    balance: balance,
                    forceDesktop: isDesktop,
                  ),
                  loading: () => Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: VelocityColors.primaryRed,
                      ),
                    ),
                  ),
                  error: (err, stack) => LeaveBalanceCards(
                    balance: LeaveBalance(
                      employee: {'id': user?.id ?? ''},
                      balances: {
                        'CASUAL': LeaveBalanceDetail(
                          allowed: 12,
                          taken: 0,
                          remaining: 12,
                        ),
                        'SICK': LeaveBalanceDetail(
                          allowed: 12,
                          taken: 0,
                          remaining: 12,
                        ),
                        'COMPENSATORY': LeaveBalanceDetail(
                          allowed: 0,
                          taken: 0,
                          remaining: 0,
                          earned: 0,
                          used: 0,
                        ),
                      },
                    ),
                    forceDesktop: isDesktop,
                  ),
                ),
              ),
            ),

            // --- Premium Interactive Leave Calendar ---
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 28 : 16,
                  0,
                  isDesktop ? 28 : 16,
                  24,
                ),
                child: leavesListAsync.when(
                  data: (leaves) => PremiumLeaveCalendar(
                    leaves: leaves,
                    onApplyLeaveRange: (start, end) {
                      _showApplyLeaveDialog(context, ref);
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => PremiumLeaveCalendar(
                    leaves: const [],
                    onApplyLeaveRange: (start, end) {
                      _showApplyLeaveDialog(context, ref);
                    },
                  ),
                ),
              ),
            ),

            // --- Desktop: Leave History Table ---
            if (isDesktop)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE53935,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    size: 20,
                                    color: VelocityColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'YOUR LEAVE HISTORY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: leavesListAsync.when(
                                    data: (leaves) => Text(
                                      '${leaves.length} RECORDS',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    loading: () => const SizedBox.shrink(),
                                    error: (err, stack) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Column Headers
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            color: const Color(0xFFF1F5F9),
                            child: Row(
                              children: [
                                _tableHeader('TYPE', flex: 2),
                                const SizedBox(width: 8),
                                _tableHeader('DATE RANGE', flex: 4),
                                const SizedBox(width: 8),
                                _tableHeader('DAYS', flex: 1),
                                const SizedBox(width: 8),
                                _tableHeader('REASON', flex: 3),
                                const SizedBox(width: 8),
                                _tableHeader('STATUS', flex: 2),
                                const SizedBox(width: 8),
                                _tableHeader('REMARKS', flex: 2),
                                const SizedBox(width: 8),
                                _tableHeader('ACTION', flex: 2),
                              ],
                            ),
                          ),

                          // Table Rows
                          leavesListAsync.when(
                            data: (leaves) {
                              if (leaves.isEmpty) {
                                return _buildEmptyState(context, ref);
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: leaves.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9),
                                      thickness: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  final leave = leaves[index];
                                  final fromDate = _formatLeaveDate(
                                    leave.fromDate,
                                  );
                                  final toDate = _formatLeaveDate(leave.toDate);
                                  final days = _calcDays(
                                    leave.fromDate,
                                    leave.toDate,
                                  );

                                  return _DesktopLeaveRow(
                                    leave: leave,
                                    fromDate: fromDate,
                                    toDate: toDate,
                                    days: days,
                                    onCancel: () =>
                                        _cancelLeave(context, ref, leave.id),
                                  );
                                },
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: VelocityColors.primaryRed,
                                ),
                              ),
                            ),
                            error: (err, stack) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Color(0xFFDC2626),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Failed to load leaves',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () =>
                                          ref.invalidate(leavesListProvider),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // --- Mobile Layout ---
            if (!isDesktop) ...[
              // Mobile Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          size: 22,
                          color: VelocityColors.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Leave History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      leavesListAsync.when(
                        data: (leaves) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${leaves.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              leavesListAsync.when(
                data: (leaves) {
                  if (leaves.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.beach_access_rounded,
                                size: 56,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Leave Records Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Apply for your first leave now',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showApplyLeaveDialog(context, ref),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Apply for Leave'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VelocityColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
                      basePadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final leave = leaves[index];
                        return _MobileLeaveCard(
                          leave: leave,
                          onCancel: () => _cancelLeave(context, ref, leave.id),
                        );
                      }, childCount: leaves.length),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: VelocityColors.primaryRed,
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load leaves',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(leavesListProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                onPressed: () => _showApplyLeaveDialog(context, ref),
                backgroundColor: VelocityColors.primaryRed,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Apply Leave',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Leave Records Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apply for your first leave request',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showApplyLeaveDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Apply for Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

int _calcDays(String from, String to) {
  try {
    final f = DateTime.parse(from);
    final t = DateTime.parse(to);
    return t.difference(f).inDays + 1;
  } catch (_) {
    return 1;
  }
}

// ===========================================================================
// DESKTOP LEAVE ROW
// ===========================================================================
class _DesktopLeaveRow extends StatefulWidget {
  final Leave leave;
  final String fromDate;
  final String toDate;
  final int days;
  final VoidCallback onCancel;

  const _DesktopLeaveRow({
    required this.leave,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.onCancel,
  });

  @override
  State<_DesktopLeaveRow> createState() => _DesktopLeaveRowState();
}

class _DesktopLeaveRowState extends State<_DesktopLeaveRow> {
  bool _hovered = false;

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CASUAL':
        return const Color(0xFFE53935);
      case 'SICK':
        return const Color(0xFF2563EB);
      case 'COMPENSATORY':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tColor = _typeColor(widget.leave.type);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: _hovered ? const Color(0xFFF8FAFC) : Colors.white,
        child: Row(
          children: [
            // Leave Type Badge
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.leave.type.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                    color: tColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Date Duration
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    size: 15,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${widget.fromDate} → ${widget.toDate}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Days
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.days}d',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Reason
            Expanded(
              flex: 3,
              child: Text(
                widget.leave.reason,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: widget.leave.status),
              ),
            ),
            const SizedBox(width: 8),
            // Remarks
            Expanded(
              flex: 2,
              child: Text(
                widget.leave.remarks?.isNotEmpty == true
                    ? widget.leave.remarks!
                    : '—',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Action
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.print_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    tooltip: 'Print Receipt',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      LeavePdfService.printLeaveReceipt(
                        employeeName: widget.leave.employeeId,
                        leaveType: widget.leave.type,
                        fromDate: widget.fromDate,
                        toDate: widget.toDate,
                        totalDays: widget.days,
                        reason: widget.leave.reason,
                        status: widget.leave.status,
                      );
                    },
                  ),
                  if (widget.leave.status == 'PENDING') ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onCancel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  size: 12,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// MOBILE LEAVE CARD
// ===========================================================================
class _MobileLeaveCard extends StatelessWidget {
  final Leave leave;
  final VoidCallback onCancel;

  const _MobileLeaveCard({required this.leave, required this.onCancel});

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CASUAL':
        return const Color(0xFFE53935);
      case 'SICK':
        return const Color(0xFF2563EB);
      case 'COMPENSATORY':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tColor = _typeColor(leave.type);
    final fromDate = _formatLeaveDate(leave.fromDate);
    final toDate = _formatLeaveDate(leave.toDate);
    final days = _calcDays(leave.fromDate, leave.toDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  leave.type.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                    color: tColor,
                  ),
                ),
              ),
              _StatusBadge(status: leave.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$fromDate → $toDate',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${days}d',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            leave.reason,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.comment_outlined,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin: ${leave.remarks}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (leave.status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 14,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Cancel Request',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// STATUS BADGE
// ===========================================================================
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        borderColor = const Color(0xFFA7F3D0);
        icon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        borderColor = const Color(0xFFFECACA);
        icon = Icons.cancel_rounded;
        break;
      default:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.pending_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// APPLY LEAVE DIALOG
// ===========================================================================
class _ApplyLeaveDialog extends ConsumerStatefulWidget {
  const _ApplyLeaveDialog();

  @override
  ConsumerState<_ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends ConsumerState<_ApplyLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedType = 'Casual Leave';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Compensatory Leave',
    'Other',
  ];

  String get _apiLeaveType {
    if (_selectedType.startsWith('Casual')) return 'CASUAL';
    if (_selectedType.startsWith('Sick')) return 'SICK';
    if (_selectedType.startsWith('Comp')) return 'COMPENSATORY';
    return 'OTHER';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initial = isFromDate
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    final minDate = isFromDate
        ? DateTime(2020)
        : (_fromDate ?? DateTime(2020));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(minDate) ? minDate : initial,
      firstDate: minDate,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: VelocityColors.primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
        }
        _errorMessage = null;
      });
    }
  }

  void _submit() async {
    debugPrint('====================================================');
    debugPrint('🚀 [LEAVE SUBMIT] Submit button clicked!');
    final isValid = _formKey.currentState?.validate() ?? false;
    debugPrint('🚀 [LEAVE SUBMIT] Form Validation Result: $isValid');
    debugPrint('🚀 [LEAVE SUBMIT] From Date: $_fromDate, To Date: $_toDate');
    debugPrint('🚀 [LEAVE SUBMIT] Selected Type: $_selectedType (API Type: $_apiLeaveType)');
    debugPrint('🚀 [LEAVE SUBMIT] Reason: ${_reasonController.text}');

    if (isValid) {
      if (_fromDate == null || _toDate == null) {
        debugPrint('❌ [LEAVE SUBMIT] Missing dates. Aborting.');
        SnackbarUtils.showError(context, 'Please select both start and end dates');
        return;
      }

      if (_toDate!.isBefore(_fromDate!)) {
        debugPrint('❌ [LEAVE SUBMIT] To Date is before From Date. Aborting.');
        const err = 'End date cannot be before start date';
        SnackbarUtils.showError(context, err);
        setState(() => _errorMessage = err);
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final df = DateFormat('yyyy-MM-dd');
        final fromStr = df.format(_fromDate!);
        final toStr = df.format(_toDate!);
        final reasonText = _reasonController.text.trim();
        final leaveTypeName = _selectedType;
        final daysCount = _toDate!.difference(_fromDate!).inDays + 1;

        debugPrint('📡 [LEAVE SUBMIT] Sending request to backend: type=$_apiLeaveType, fromDate=$fromStr, toDate=$toStr, reason=$reasonText');

        await ref
            .read(leaveServiceProvider)
            .applyLeave(
              _apiLeaveType,
              fromStr,
              toStr,
              reasonText,
            );

        debugPrint('✅ [LEAVE SUBMIT] Request successfully completed!');

        if (mounted) {
          final user = ref.read(authProvider).user;
          Navigator.pop(context, {
            'employeeName': user?.name ?? 'Employee',
            'leaveType': leaveTypeName,
            'fromDate': fromStr,
            'toDate': toStr,
            'totalDays': daysCount,
            'reason': reasonText,
          });
          SnackbarUtils.showSuccess(context, 'Leave request submitted successfully');
        }
      } catch (e, stack) {
        debugPrint('💥 [LEAVE SUBMIT ERROR] Exception: $e');
        debugPrint('💥 [LEAVE SUBMIT ERROR] StackTrace: $stack');
        final errMsg = SnackbarUtils.extractErrorMessage(e);
        if (mounted) {
          setState(() {
            _errorMessage = errMsg;
          });
          SnackbarUtils.showError(context, errMsg);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int calculatedDays = 0;
    if (_fromDate != null && _toDate != null) {
      calculatedDays = _toDate!.difference(_fromDate!).inDays + 1;
    }

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: VelocityColors.primaryRed,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFC62828)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE53935,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Apply for Leave',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Submit a new time-off request',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Leave Type Dropdown
                const Text(
                  'Leave Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: inputDecoration,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items: _leaveTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            type == 'Casual Leave'
                                ? Icons.celebration_rounded
                                : type == 'Sick Leave'
                                ? Icons.health_and_safety_rounded
                                : type == 'Compensatory Leave'
                                ? Icons.access_time_rounded
                                : Icons.more_horiz_rounded,
                            size: 18,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            type,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Date Pickers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _fromDate != null
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFFE2E8F0),
                                  width: _fromDate != null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: _fromDate != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _fromDate != null
                                        ? DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_fromDate!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      color: _fromDate != null
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF94A3B8),
                                      fontWeight: _fromDate != null
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_fromDate != null)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: const Color(0xFF059669),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'To Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _toDate != null
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFFE2E8F0),
                                  width: _toDate != null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 20,
                                    color: _toDate != null
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _toDate != null
                                        ? DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_toDate!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      color: _toDate != null
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFF94A3B8),
                                      fontWeight: _toDate != null
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_toDate != null)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: const Color(0xFF059669),
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

                if (calculatedDays > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total Duration: $calculatedDays day${calculatedDays > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${calculatedDays}d',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Reason
                const Text(
                  'Reason for Leave',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  decoration: inputDecoration.copyWith(
                    hintText: 'Provide a brief explanation...',
                    hintStyle: TextStyle(color: const Color(0xFF94A3B8)),
                  ),
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VelocityColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submit Leave Request',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
