import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/features/shared/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../leaves/services/leave_service.dart';
import '../../../models/leave.dart';
import '../../shared/widgets/states.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/snackbar_utils.dart';

import '../../../core/theme/velocity_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/widgets/leave_balance_cards.dart';

// Removed leaveBalanceProvider as it is centralized in leave_service.dart

final leavesListProvider = FutureProvider.autoDispose<List<Leave>>((ref) {
  return ref.watch(leaveServiceProvider).getLeaves();
});

@RoutePage()
class EmployeeLeavesScreen extends ConsumerWidget {
  const EmployeeLeavesScreen({super.key});

  void _showApplyLeaveDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      context: context,
      builder: (context) => const _ApplyLeaveDialog(),
    ).then((_) {
      // Refresh after closing dialog (in case of submission)
      final user = ref.read(authProvider).user;
      ref.invalidate(employeeLeaveBalanceProvider(user?.id ?? ''));
      ref.invalidate(leavesListProvider);
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
        title: const Text('Cancel Leave'),
        content: const Text(
          'Are you sure you want to cancel this leave application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
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

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final user = ref.read(authProvider).user;
          ref.invalidate(employeeLeaveBalanceProvider(user?.id ?? ''));
          ref.invalidate(leavesListProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: leaveBalanceAsync.when(
                data: (balance) => LeaveBalanceCards(balance: balance),
                loading: () =>
                    const SizedBox(height: 200, child: LoadingStateWidget()),
                error: (err, stack) => ErrorStateWidget(
                  error: err.toString(),
                  onRetry: () {
                    final user = ref.read(authProvider).user;
                    ref.invalidate(
                      employeeLeaveBalanceProvider(user?.id ?? ''),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Leave History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const EmptyStateWidget(
                          icon: Icons.assignment_outlined,
                          title: 'No leaves found',
                          message: 'You have not applied for any leaves yet.',
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                                Expanded(
                                  child: Text(
                                    leave.type,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _StatusBadge(status: leave.status),
                              ],
                            ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.date_range,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${leave.fromDate} to ${leave.toDate}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                leave.reason,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              if (leave.remarks != null &&
                                  leave.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Admin Remarks: ${leave.remarks}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              if (leave.status == 'PENDING') ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _cancelLeave(context, ref, leave.id),
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Cancel Request'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      );
                    }, childCount: leaves.length),
                  ),
                );
              },
              loading: () =>
                  const SliverToBoxAdapter(child: LoadingStateWidget()),
              error: (err, stack) => SliverToBoxAdapter(
                child: ErrorStateWidget(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(leavesListProvider),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeaveDialog(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Apply Leave',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bgColor = VelocityColors.success.withValues(alpha: 0.1);
        textColor = VelocityColors.success;
        break;
      case 'REJECTED':
        bgColor = VelocityColors.error.withValues(alpha: 0.1);
        textColor = VelocityColors.error;
        break;
      default:
        bgColor = VelocityColors.warning.withValues(alpha: 0.1);
        textColor = VelocityColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null; // Reset toDate
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_fromDate == null || _toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select dates'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final df = DateFormat('yyyy-MM-dd');
        await ref
            .read(leaveServiceProvider)
            .applyLeave(
              _apiLeaveType,
              df.format(_fromDate!),
              df.format(_toDate!),
              _reasonController.text,
            );
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave applied successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorHandler.getUserMessage(e)),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
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
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
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
                          gradient: LinearGradient(
                            colors: [
                              VelocityColors.primaryRed.withValues(alpha: 0.2),
                              VelocityColors.primaryRed.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.edit_calendar_rounded,
                          color: VelocityColors.primaryRed,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply for Leave',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Submit a new time-off request',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Leave Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: inputDecoration.copyWith(
                  prefixIcon: const Icon(Icons.category_rounded, size: 22),
                  hintText: 'Select leave type',
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _leaveTypes.map((type) {
                  return DropdownMenuItem(
                    value: type, 
                    child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _fromDate != null
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: _fromDate != null ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fromDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_fromDate!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      color: _fromDate != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).hintColor,
                                      fontWeight: _fromDate != null ? FontWeight.w700 : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _toDate != null
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 20,
                                  color: _toDate != null ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _toDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_toDate!)
                                        : 'Select Date',
                                    style: TextStyle(
                                      color: _toDate != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).hintColor,
                                      fontWeight: _toDate != null ? FontWeight.w700 : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
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
              const SizedBox(height: 24),
              if (calculatedDays > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50.withValues(alpha: 0.5),
                        Colors.blue.shade100.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_rounded, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Duration',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$calculatedDays Days',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.blue[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Reason for Leave',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: inputDecoration.copyWith(
                  hintText: 'Provide a brief explanation...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: VelocityColors.primaryRed.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VelocityColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
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
    );
  }
}
