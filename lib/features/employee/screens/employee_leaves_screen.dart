import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/features/shared/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../leaves/services/leave_service.dart';
import '../../../models/leave.dart';
import '../../shared/widgets/states.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';

import '../../auth/providers/auth_provider.dart';

final leaveBalanceProvider = FutureProvider.autoDispose<LeaveBalance>((ref) {
  final user = ref.watch(authProvider).user;
  return ref.watch(leaveServiceProvider).getLeaveBalance(user?.id ?? '');
});

final leavesListProvider = FutureProvider.autoDispose<List<Leave>>((ref) {
  return ref.watch(leaveServiceProvider).getLeaves();
});

@RoutePage()
class EmployeeLeavesScreen extends ConsumerWidget {
  const EmployeeLeavesScreen({Key? key}) : super(key: key);

  void _showApplyLeaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _ApplyLeaveDialog(),
    ).then((_) {
      // Refresh after closing dialog (in case of submission)
      ref.invalidate(leaveBalanceProvider);
      ref.invalidate(leavesListProvider);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveBalanceAsync = ref.watch(leaveBalanceProvider);
    final leavesListAsync = ref.watch(leavesListProvider);

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaveBalanceProvider);
          ref.invalidate(leavesListProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: leaveBalanceAsync.when(
                data: (balance) => _LeaveBalanceSection(balance: balance),
                loading: () =>
                    const SizedBox(height: 200, child: LoadingStateWidget()),
                error: (err, stack) => ErrorStateWidget(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(leaveBalanceProvider),
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
                    ElevatedButton.icon(
                      onPressed: () => _showApplyLeaveDialog(context, ref),
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Apply Leave',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 72,
                                  color: Colors.grey.shade400,
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -8,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      size: 32,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No leaves found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You have not applied for any leaves yet.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    leave.type,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
                                  Text(
                                    '${leave.fromDate} to ${leave.toDate}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                leave.reason,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              if (leave.remarks != null &&
                                  leave.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Admin Remarks: ${leave.remarks}',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'REJECTED':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
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

class _LeaveBalanceSection extends StatelessWidget {
  final LeaveBalance balance;

  const _LeaveBalanceSection({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: AppTheme.primaryRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Your Leave Balances',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppTheme.primaryRed,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _BalanceCard(
                  title: 'CASUAL LEAVE',
                  icon: Icons.calendar_today,
                  color: Colors.blue.shade600,
                  remaining: balance.balances['CASUAL']?.remaining ?? 0,
                  taken: balance.balances['CASUAL']?.taken ?? 0,
                ),
                _BalanceCard(
                  title: 'SICK LEAVE',
                  icon: Icons.thermostat,
                  color: Colors.teal.shade500,
                  remaining: balance.balances['SICK']?.remaining ?? 0,
                  taken: balance.balances['SICK']?.taken ?? 0,
                ),
                _BalanceCard(
                  title: 'COMPENSATORY\nLEAVE',
                  icon: Icons.card_giftcard,
                  color: Colors.purple.shade400,
                  remaining: balance.balances['COMPENSATORY']?.remaining ?? 0,
                  taken: balance.balances['COMPENSATORY']?.taken ?? 0,
                ),
                _BalanceCard(
                  title: 'OTHER LEAVE',
                  icon: Icons.sentiment_satisfied_alt,
                  color: Colors.orange.shade400,
                  remaining: balance.balances['OTHER']?.remaining ?? 0,
                  taken: balance.balances['OTHER']?.taken ?? 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int remaining;
  final int taken;

  const _BalanceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.remaining,
    required this.taken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text(
                      'Remaining',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$taken',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Taken',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  String _selectedType = 'CASUAL';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  final List<String> _leaveTypes = ['CASUAL', 'SICK', 'COMPENSATORY', 'OTHER'];

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
            _toDate = null; // Reset toDate if it's before new fromDate
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select dates'),
          backgroundColor: AppTheme.primaryRed,
        ));
        return;
      }

      final requestedDays = _toDate!.difference(_fromDate!).inDays + 1;
      if (requestedDays > 0) {
        final balanceAsync = ref.read(leaveBalanceProvider);
        final currentBalance = balanceAsync.valueOrNull;
        if (currentBalance != null) {
          final typeBalance = currentBalance.balances[_selectedType];
          if (typeBalance != null && requestedDays > typeBalance.remaining) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Requested $requestedDays day(s), but you only have ${typeBalance.remaining} remaining for $_selectedType.'),
              backgroundColor: AppTheme.primaryRed,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ));
            return;
          }
        }
      }

      setState(() => _isLoading = true);

      try {
        final df = DateFormat('yyyy-MM-dd');
        await ref
            .read(leaveServiceProvider)
            .applyLeave(
              _selectedType,
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ErrorHandler.getUserMessage(e)),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply for Leave'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value:
                    _selectedType, // using value back since DropdownButtonFormField requires it
                decoration: const InputDecoration(labelText: 'Leave Type'),
                items: _leaveTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _fromDate == null
                            ? 'From Date'
                            : DateFormat('MMM dd, yyyy').format(_fromDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _toDate == null
                            ? 'To Date'
                            : DateFormat('MMM dd, yyyy').format(_toDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
