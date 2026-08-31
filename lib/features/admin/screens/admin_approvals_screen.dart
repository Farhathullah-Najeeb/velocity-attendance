import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../leaves/services/leave_service.dart';
import '../../overtime/services/overtime_service.dart';
import '../../attendance/services/attendance_service.dart';
import '../../employees/services/employee_service.dart';
import '../../../models/user.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../shared/widgets/states.dart';

enum RequestType { all, wfh, overtime, regularization, exception, leave }

enum RequestStatus { all, pending, approved, rejected }

class UnifiedRequestItem {
  final String id;
  final RequestType type;
  final String employeeId;
  final String employeeName;
  final String employeeDept;
  final String dateStr;
  final String periodOrTime;
  final String specificType;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final dynamic originalData;

  UnifiedRequestItem({
    required this.id,
    required this.type,
    required this.employeeId,
    required this.employeeName,
    required this.employeeDept,
    required this.dateStr,
    required this.periodOrTime,
    required this.specificType,
    required this.reason,
    required this.status,
    required this.originalData,
  });
}

final allOrganizationRequestsProvider =
    FutureProvider.autoDispose<List<UnifiedRequestItem>>((ref) async {
  final List<UnifiedRequestItem> items = [];

  // 1. Fetch Leaves
  try {
    final leaves = await ref.read(leaveServiceProvider).getLeaves();
    for (final l in leaves) {
      final emp = l.employeeId;
      final empName =
          emp is Map ? (emp['name'] ?? 'Employee') : 'Employee';
      final empDept =
          emp is Map ? (emp['department'] ?? 'General') : 'General';

      items.add(UnifiedRequestItem(
        id: l.id,
        type: RequestType.leave,
        employeeId: emp is Map ? (emp['_id'] ?? emp['id'] ?? '') : '',
        employeeName: empName,
        employeeDept: empDept,
        dateStr: l.fromDate,
        periodOrTime: (l.fromDate.isNotEmpty && l.toDate.isNotEmpty)
            ? 'Period: ${l.fromDate} to ${l.toDate}'
            : 'Date: ${l.fromDate}',
        specificType: l.type,
        reason: l.reason.isNotEmpty ? l.reason : 'Personal work',
        status: l.status.toUpperCase(),
        originalData: l,
      ));
    }
  } catch (_) {}

  // 2. Fetch Overtime
  try {
    final overtimes = await ref.read(overtimeServiceProvider).getAllOvertime();
    for (final ot in overtimes) {
      final emp = ot.employeeId;
      final empName =
          emp is Map ? (emp['name'] ?? 'Employee') : 'Employee';
      final empDept =
          emp is Map ? (emp['department'] ?? 'General') : 'General';

      items.add(UnifiedRequestItem(
        id: ot.id,
        type: RequestType.overtime,
        employeeId: emp is Map ? (emp['_id'] ?? emp['id'] ?? '') : '',
        employeeName: empName,
        employeeDept: empDept,
        dateStr: ot.dateStr,
        periodOrTime: 'Hours: ${ot.startTime ?? '—'} - ${ot.endTime ?? '—'}',
        specificType: 'OVERTIME',
        reason: ot.workSummary ?? ot.reason ?? 'Overtime work logged',
        status: ot.status.toUpperCase(),
        originalData: ot,
      ));
    }
  } catch (_) {}

  // 3. Fetch WFH Requests
  try {
    final wfhList =
        await ref.read(attendanceServiceProvider).getWfhRequests();
    for (final w in wfhList) {
      final emp = w['employeeId'];
      final empName =
          emp is Map ? (emp['name'] ?? 'Employee') : 'Employee';
      final empDept =
          emp is Map ? (emp['department'] ?? 'General') : 'General';

      items.add(UnifiedRequestItem(
        id: w['_id'] ?? w['id'] ?? '',
        type: RequestType.wfh,
        employeeId: emp is Map ? (emp['_id'] ?? emp['id'] ?? '') : '',
        employeeName: empName,
        employeeDept: empDept,
        dateStr: w['dateStr'] ?? '—',
        periodOrTime: 'Date: ${w['dateStr'] ?? '—'}',
        specificType: 'WORK FROM HOME',
        reason: w['reason'] ?? 'Work from home requested',
        status: (w['status'] ?? 'PENDING').toString().toUpperCase(),
        originalData: w,
      ));
    }
  } catch (_) {}

  // 4. Fetch Regularization Requests
  try {
    final regList = await ref
        .read(attendanceServiceProvider)
        .getRegularizationRequests();
    for (final r in regList) {
      final emp = r['employeeId'];
      final empName =
          emp is Map ? (emp['name'] ?? 'Employee') : 'Employee';
      final empDept =
          emp is Map ? (emp['department'] ?? 'General') : 'General';

      items.add(UnifiedRequestItem(
        id: r['_id'] ?? r['id'] ?? '',
        type: RequestType.regularization,
        employeeId: emp is Map ? (emp['_id'] ?? emp['id'] ?? '') : '',
        employeeName: empName,
        employeeDept: empDept,
        dateStr: r['dateStr'] ?? '—',
        periodOrTime:
            'Regularize ${r['type'] ?? 'Punch'}: ${r['requestedTime'] ?? '—'}',
        specificType: (r['type'] ?? 'REGULARIZATION').toString().toUpperCase(),
        reason: r['reason'] ?? 'Attendance adjustment',
        status: (r['status'] ?? 'PENDING').toString().toUpperCase(),
        originalData: r,
      ));
    }
  } catch (_) {}

  // 5. Fetch Attendance Exceptions (Pending Approvals)
  try {
    final exceptions =
        await ref.read(attendanceServiceProvider).getPendingApprovals();
    for (final ex in exceptions) {
      final emp = ex.employeeId;
      final empName =
          emp is Map ? (emp['name'] ?? 'Employee') : 'Employee';
      final empDept =
          emp is Map ? (emp['department'] ?? 'General') : 'General';

      final reason = ex.isLateArrival == true
          ? 'Late Arrival exception'
          : (ex.isEarlyCheckout == true
              ? 'Early Checkout exception'
              : 'Shift exception');

      items.add(UnifiedRequestItem(
        id: ex.id,
        type: RequestType.exception,
        employeeId: emp is Map ? (emp['_id'] ?? emp['id'] ?? '') : '',
        employeeName: empName,
        employeeDept: empDept,
        dateStr: ex.dateStr,
        periodOrTime: 'Date: ${ex.dateStr}',
        specificType: 'ATTENDANCE EXCEPTION',
        reason: reason,
        status: ex.approvalStatus.toUpperCase(),
        originalData: ex,
      ));
    }
  } catch (_) {}

  return items;
});

final employeesFilterListProvider =
    FutureProvider.autoDispose<List<User>>((ref) {
  return ref.watch(employeeServiceProvider).getEmployees(status: 'APPROVED');
});

@RoutePage()
class AdminApprovalsScreen extends ConsumerStatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  ConsumerState<AdminApprovalsScreen> createState() =>
      _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends ConsumerState<AdminApprovalsScreen> {
  RequestType _selectedType = RequestType.all;
  RequestStatus _selectedStatus = RequestStatus.all;
  DateTime? _selectedDate;
  String? _selectedEmployeeId;

  void _handleApprove(UnifiedRequestItem item) async {
    final remarksController = TextEditingController();
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Approve Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approve ${item.specificType} for ${item.employeeName}?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Approval Remarks (Optional)',
                hintText: 'e.g. Approved as per policy',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      final remarks = remarksController.text.trim();
      try {
        if (item.type == RequestType.leave) {
          await ref.read(leaveServiceProvider).approveLeave(item.id, remarks);
        } else if (item.type == RequestType.overtime) {
          await ref
              .read(overtimeServiceProvider)
              .updateOvertimeStatus(item.id, 'APPROVED', remarks);
        } else if (item.type == RequestType.wfh) {
          await ref
              .read(attendanceServiceProvider)
              .approveWfhRequest(item.id, remarks);
        } else if (item.type == RequestType.regularization) {
          await ref
              .read(attendanceServiceProvider)
              .approveRegularizationRequest(item.id, remarks);
        } else if (item.type == RequestType.exception) {
          await ref
              .read(attendanceServiceProvider)
              .approveAttendance(item.id, remarks, 'NONE');
        }

        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Request approved successfully!');
        }
        ref.invalidate(allOrganizationRequestsProvider);
      } catch (e) {
        if (mounted) SnackbarUtils.handleApiError(context, e);
      }
    }
  }

  void _handleReject(UnifiedRequestItem item) async {
    final remarksController = TextEditingController();
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VelocityColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: VelocityColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reject Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${item.specificType} for ${item.employeeName}?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (Required)',
                hintText: 'e.g. Schedule clash / Missing justification',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (remarksController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      final remarks = remarksController.text.trim();
      try {
        if (item.type == RequestType.leave) {
          await ref.read(leaveServiceProvider).rejectLeave(item.id, remarks);
        } else if (item.type == RequestType.overtime) {
          await ref
              .read(overtimeServiceProvider)
              .updateOvertimeStatus(item.id, 'REJECTED', remarks);
        } else if (item.type == RequestType.wfh) {
          await ref
              .read(attendanceServiceProvider)
              .rejectWfhRequest(item.id, remarks);
        } else if (item.type == RequestType.regularization) {
          await ref
              .read(attendanceServiceProvider)
              .rejectRegularizationRequest(item.id, remarks);
        } else if (item.type == RequestType.exception) {
          await ref
              .read(attendanceServiceProvider)
              .rejectAttendance(item.id, remarks);
        }

        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Request rejected.');
        }
        ref.invalidate(allOrganizationRequestsProvider);
      } catch (e) {
        if (mounted) SnackbarUtils.handleApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allOrganizationRequestsProvider);
    final employeesAsync = ref.watch(employeesFilterListProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async => ref.invalidate(allOrganizationRequestsProvider),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            isDesktop ? 24 : 16,
            isDesktop ? 32 : 16,
            48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===============================================================
              // 1. HEADER BANNER (Matches Organization Requests Dark Navy Hero)
              // ===============================================================
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Organization Requests',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Unified dashboard for Overtime, WFH, Regularization, Exceptions, and Leaves',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    requestsAsync.when(
                      data: (items) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              size: 15,
                              color: Color(0xFFE2E8F0),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${items.length} Total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // 2. FILTER CONTROLS CARD
              // ===============================================================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TYPE FILTER ROW ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'TYPE:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _buildFilterPill(
                            label: 'All Types',
                            isSelected: _selectedType == RequestType.all,
                            onTap: () =>
                                setState(() => _selectedType = RequestType.all),
                          ),
                          _buildFilterPill(
                            label: 'WFH',
                            isSelected: _selectedType == RequestType.wfh,
                            onTap: () =>
                                setState(() => _selectedType = RequestType.wfh),
                          ),
                          _buildFilterPill(
                            label: 'Overtime',
                            isSelected: _selectedType == RequestType.overtime,
                            onTap: () => setState(
                                () => _selectedType = RequestType.overtime),
                          ),
                          _buildFilterPill(
                            label: 'Regularization',
                            isSelected:
                                _selectedType == RequestType.regularization,
                            onTap: () => setState(() =>
                                _selectedType = RequestType.regularization),
                          ),
                          _buildFilterPill(
                            label: 'Exception',
                            isSelected: _selectedType == RequestType.exception,
                            onTap: () => setState(
                                () => _selectedType = RequestType.exception),
                          ),
                          _buildFilterPill(
                            label: 'Leave',
                            isSelected: _selectedType == RequestType.leave,
                            onTap: () => setState(
                                () => _selectedType = RequestType.leave),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- STATUS FILTER ROW ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text(
                            'STATUS:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _buildFilterPill(
                            label: 'All Status',
                            isSelected: _selectedStatus == RequestStatus.all,
                            onTap: () => setState(
                                () => _selectedStatus = RequestStatus.all),
                          ),
                          _buildFilterPill(
                            label: 'Pending',
                            isSelected:
                                _selectedStatus == RequestStatus.pending,
                            onTap: () => setState(
                                () => _selectedStatus = RequestStatus.pending),
                          ),
                          _buildFilterPill(
                            label: 'Approved',
                            isSelected:
                                _selectedStatus == RequestStatus.approved,
                            onTap: () => setState(
                                () => _selectedStatus = RequestStatus.approved),
                          ),
                          _buildFilterPill(
                            label: 'Rejected',
                            isSelected:
                                _selectedStatus == RequestStatus.rejected,
                            onTap: () => setState(
                                () => _selectedStatus = RequestStatus.rejected),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- DATE & EMPLOYEE DROPDOWN ROW ---
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 650;

                        final datePickerWidget = InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_selectedDate!)
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedDate != null
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedDate != null)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    onPressed: () =>
                                        setState(() => _selectedDate = null),
                                  ),
                              ],
                            ),
                          ),
                        );

                        final employeeDropdownWidget = Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: employeesAsync.when(
                            data: (employees) => DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedEmployeeId,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF64748B),
                                ),
                                hint: Row(
                                  children: const [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'All Employees',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      'All Employees',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ...employees.map(
                                    (e) => DropdownMenuItem<String?>(
                                      value: e.id,
                                      child: Text(
                                        e.name,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedEmployeeId = v),
                              ),
                            ),
                            loading: () => const Center(
                              child: LinearProgressIndicator(),
                            ),
                            error: (err, stack) => const Text('Error'),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              datePickerWidget,
                              const SizedBox(height: 10),
                              employeeDropdownWidget,
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: datePickerWidget),
                              const SizedBox(width: 16),
                              Expanded(child: employeeDropdownWidget),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===============================================================
              // 3. UNIFIED REQUESTS CARDS GRID
              // ===============================================================
              requestsAsync.when(
                data: (items) {
                  // Filter logic
                  final filtered = items.where((it) {
                    // Type filter
                    if (_selectedType != RequestType.all &&
                        it.type != _selectedType) {
                      return false;
                    }
                    // Status filter
                    if (_selectedStatus != RequestStatus.all) {
                      final s = _selectedStatus.name.toUpperCase();
                      if (it.status != s) return false;
                    }
                    // Date filter
                    if (_selectedDate != null) {
                      final dStr =
                          DateFormat('dd/MM/yyyy').format(_selectedDate!);
                      if (!it.dateStr.contains(dStr) &&
                          !it.periodOrTime.contains(dStr)) {
                        return false;
                      }
                    }
                    // Employee filter
                    if (_selectedEmployeeId != null &&
                        it.employeeId != _selectedEmployeeId) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.0),
                      child: EmptyStateWidget(
                        title: 'No Matching Requests',
                        message:
                            'No requests found matching the current filter options.',
                        icon: Icons.done_all_rounded,
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 850) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 580) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 260,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final req = filtered[i];
                          return _RequestCard(
                            item: req,
                            onApprove: () => _handleApprove(req),
                            onReject: () => _handleReject(req),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(80.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: VelocityColors.primaryRed,
                    ),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: ErrorStateWidget(
                    error: err.toString(),
                    onRetry: () =>
                        ref.invalidate(allOrganizationRequestsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? VelocityColors.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? VelocityColors.primaryRed
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final UnifiedRequestItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _hovered = false;

  IconData _getTypeIcon(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return Icons.calendar_month_outlined;
      case RequestType.overtime:
        return Icons.timer_outlined;
      case RequestType.wfh:
        return Icons.home_work_outlined;
      case RequestType.regularization:
        return Icons.update_rounded;
      case RequestType.exception:
        return Icons.warning_amber_rounded;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _getTypeLabel(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return 'LEAVE';
      case RequestType.overtime:
        return 'OVERTIME';
      case RequestType.wfh:
        return 'WFH';
      case RequestType.regularization:
        return 'REGULARIZATION';
      case RequestType.exception:
        return 'EXCEPTION';
      default:
        return 'REQUEST';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPending = item.status == 'PENDING';
    final isApproved = item.status == 'APPROVED';
    final initial =
        item.employeeName.isNotEmpty ? item.employeeName[0].toUpperCase() : 'U';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header: Type Label & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTypeIcon(item.type),
                      size: 14,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getTypeLabel(item.type),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproved
                          ? Icons.check_rounded
                          : (isPending
                              ? Icons.schedule_rounded
                              : Icons.close_rounded),
                      size: 13,
                      color: isApproved
                          ? const Color(0xFF059669)
                          : (isPending
                              ? const Color(0xFFD97706)
                              : const Color(0xFFDC2626)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isApproved
                          ? 'Approved'
                          : (isPending ? 'Pending' : 'Rejected'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isApproved
                            ? const Color(0xFF059669)
                            : (isPending
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            // Employee Avatar & Name
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.employeeName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.employeeDept,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Metadata Lines
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.specificType != 'OVERTIME' &&
                    item.specificType != 'WORK FROM HOME')
                  Text(
                    'Leave Type:${item.specificType}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  item.periodOrTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Summary / Reason:\n${item.reason}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF334155),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // Actions Footer (if pending)
            if (isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onReject,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: widget.onApprove,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
