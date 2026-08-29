import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../attendance/services/attendance_service.dart';

@RoutePage()
class EmployeeRequestsScreen extends ConsumerStatefulWidget {
  const EmployeeRequestsScreen({super.key});

  @override
  ConsumerState<EmployeeRequestsScreen> createState() => _EmployeeRequestsScreenState();
}

class _EmployeeRequestsScreenState extends ConsumerState<EmployeeRequestsScreen> {
  int _selectedTabIndex = 0; // 0 for WFH, 1 for Regularization

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Requests'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Submit and track Work From Home and Attendance Regularization requests.',
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
                              Icon(Icons.home_work_outlined, size: 16, color: _selectedTabIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 8),
                              Text('WFH', style: TextStyle(color: _selectedTabIndex == 0 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 13)),
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
                              Icon(Icons.update, size: 16, color: _selectedTabIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 8),
                              Text('Regularization', style: TextStyle(color: _selectedTabIndex == 1 ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 13)),
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
          const SizedBox(height: 24),
          Expanded(
            child: _selectedTabIndex == 0
                ? const _WfhRequestsView()
                : const _RegularizationRequestsView(),
          ),
        ],
      ),
    );
  }
}

class _WfhRequestsView extends ConsumerStatefulWidget {
  const _WfhRequestsView();
  @override
  ConsumerState<_WfhRequestsView> createState() => _WfhRequestsViewState();
}

class _WfhRequestsViewState extends ConsumerState<_WfhRequestsView> {
  void _showNewRequestModal() {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New WFH Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              onTap: () async {
                final date = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  dateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dateCtrl.text.isEmpty || reasonCtrl.text.isEmpty) {
                return;
              }
              try {
                await ref.read(attendanceServiceProvider).requestWfh(
                  dateCtrl.text,
                  reasonCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  SnackbarUtils.showSuccess(ctx, 'WFH Request submitted');
                  // Invalidate provider to refresh list
                  setState(() {});
                }
              } catch (e) {
                if (ctx.mounted) SnackbarUtils.handleApiError(ctx, e);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New WFH Request'),
            onPressed: _showNewRequestModal,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder(
            future: ref.read(attendanceServiceProvider).getWfhRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return const Center(child: Text('No WFH requests found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    child: ListTile(
                      title: Text('Date: ${req['dateStr']}'),
                      subtitle: Text('Reason: ${req['reason']}\nStatus: ${req['status']}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegularizationRequestsView extends ConsumerStatefulWidget {
  const _RegularizationRequestsView();
  @override
  ConsumerState<_RegularizationRequestsView> createState() => _RegularizationRequestsViewState();
}

class _RegularizationRequestsViewState extends ConsumerState<_RegularizationRequestsView> {
  void _showNewRequestModal() {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String type = 'ACCIDENTAL_CHECK_OUT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('New Regularization Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().subtract(const Duration(days: 1)),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateCtrl.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'ACCIDENTAL_CHECK_OUT', child: Text('Accidental Check Out')),
                  DropdownMenuItem(value: 'MISSED_CHECK_IN', child: Text('Missed Check In')),
                  DropdownMenuItem(value: 'MISSED_CHECK_OUT', child: Text('Missed Check Out')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other / Early Check Out')),
                ],
                onChanged: (val) {
                  if (val != null) setStateDialog(() => type = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dateCtrl.text.isEmpty || reasonCtrl.text.isEmpty) {
                  return;
                }
                try {
                  await ref.read(attendanceServiceProvider).requestRegularization(
                    dateCtrl.text,
                    type,
                    '00:00', // Default dummy time
                    reasonCtrl.text,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    SnackbarUtils.showSuccess(ctx, 'Request submitted');
                    setState(() {});
                  }
                } catch (e) {
                  if (ctx.mounted) SnackbarUtils.handleApiError(ctx, e);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Regularization Request'),
            onPressed: _showNewRequestModal,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FutureBuilder(
            future: ref.read(attendanceServiceProvider).getRegularizationRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return const Center(child: Text('No Regularization requests found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    child: ListTile(
                      title: Text('Date: ${req['dateStr']} | ${req['type']}'),
                      subtitle: Text('Reason: ${req['reason']}\nStatus: ${req['status']}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
