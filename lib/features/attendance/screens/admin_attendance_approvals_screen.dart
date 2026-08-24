import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../../../models/attendance.dart';
import '../../shared/widgets/states.dart';
import '../../../core/theme/app_theme.dart';

final pendingAttendanceProvider = FutureProvider.autoDispose<List<Attendance>>((ref) {
  return ref.watch(attendanceServiceProvider).getPendingApprovals();
});

@RoutePage()
class AdminAttendanceApprovalsScreen extends ConsumerWidget {
  const AdminAttendanceApprovalsScreen({super.key});

  void _showApprovalDialog(BuildContext context, WidgetRef ref, Attendance record, bool isApprove) {
    final remarksController = TextEditingController();
    String penaltyType = 'NONE'; // NONE, RED_MARK, HALF_DAY

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(isApprove ? Icons.check_circle : Icons.cancel, color: isApprove ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(isApprove ? 'Approve Exception' : 'Reject Exception', style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to ${isApprove ? 'approve' : 'reject'} this attendance record?'),
                const SizedBox(height: 16),
                
                if (isApprove) ...[
                  const Text('Apply Penalty:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: penaltyType,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('No Penalty')),
                      DropdownMenuItem(value: 'RED_MARK', child: Text('Red Mark (Warning)')),
                      DropdownMenuItem(value: 'HALF_DAY', child: Text('Half Day Deduction')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => penaltyType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: remarksController,
                  decoration: InputDecoration(
                    labelText: 'Remarks ${isApprove ? '(Optional)' : '(Required)'}',
                    hintText: 'Add a note...',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApprove ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!isApprove && remarksController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remarks are required for rejection.')));
                    return;
                  }

                  try {
                    if (isApprove) {
                      await ref.read(attendanceServiceProvider).approveAttendance(record.id, remarksController.text, penaltyType);
                    } else {
                      await ref.read(attendanceServiceProvider).rejectAttendance(record.id, remarksController.text);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Attendance ${isApprove ? 'approved' : 'rejected'} successfully'),
                          backgroundColor: isApprove ? Colors.green : Colors.red,
                        ),
                      );
                    }
                    ref.invalidate(pendingAttendanceProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
                    }
                  }
                },
                child: Text(isApprove ? 'Approve' : 'Reject'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pendingAttendanceProvider);

    return AppScaffold(
      appBar: MediaQuery.of(context).size.width > 800 ? AppBar(title: const Text('Attendance Approvals')) : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingAttendanceProvider);
        },
        child: asyncData.when(
          data: (records) {
            if (records.isEmpty) {
              return const EmptyStateWidget(
                title: 'All caught up!',
                message: 'No pending attendance exceptions.',
                icon: Icons.fact_check_outlined,
              );
            }
            return ListView.builder(
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(16)),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDateStr(record.dateStr),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (record.isLateArrival == true)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildTag('LATE IN', Colors.deepOrange),
                              ),
                            if (record.isEarlyCheckout == true)
                              _buildTag('EARLY OUT', Colors.amber.shade700),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTimeRow(Icons.login, 'Check In', record.checkInTime),
                        if (record.checkOutTime != null) ...[
                          const SizedBox(height: 8),
                          _buildTimeRow(Icons.logout, 'Check Out', record.checkOutTime),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showApprovalDialog(context, ref, record, false),
                              icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
                              label: Text('Reject', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showApprovalDialog(context, ref, record, true),
                              icon: const Icon(Icons.check, size: 20),
                              label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _buildTimeRow(IconData icon, String label, String? isoTime) {
    String formattedTime = '--:--';
    if (isoTime != null) {
      try {
        final date = DateTime.parse(isoTime).toLocal();
        formattedTime = DateFormat('hh:mm a').format(date);
      } catch (_) {
        formattedTime = isoTime;
      }
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(width: 8),
        Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}

