import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/role.dart';
import '../../../models/site.dart';
import '../../../models/user.dart';
import '../../admin/services/roles_service.dart';
import '../../admin/services/settings_service.dart';
import '../services/employee_service.dart';

final editRolesListProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(rolesServiceProvider).getRoles();
});

final editSitesListProvider = FutureProvider.autoDispose<List<Site>>((ref) {
  return ref.watch(settingsServiceProvider).getSites();
});

@RoutePage()
class EmployeeProfileEditScreen extends ConsumerStatefulWidget {
  final User employee;
  const EmployeeProfileEditScreen({super.key, required this.employee});

  @override
  ConsumerState<EmployeeProfileEditScreen> createState() =>
      _EmployeeProfileEditScreenState();
}

class _EmployeeProfileEditScreenState
    extends ConsumerState<EmployeeProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _locationController;

  late bool _isActive;
  String? _selectedRoleId;
  String? _selectedSiteId;
  String? _staffType;
  TimeOfDay? _officeStartTime;
  TimeOfDay? _officeEndTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _departmentController =
        TextEditingController(text: widget.employee.department);
    _locationController =
        TextEditingController(text: widget.employee.location);
    _isActive = widget.employee.isActive ?? true;
    _selectedSiteId = widget.employee.assignedSite;
    _staffType = widget.employee.staffType ?? 'OFFICE';
    if (widget.employee.officeStartTime != null) {
      final parts = widget.employee.officeStartTime!.split(':');
      if (parts.length == 2) {
        _officeStartTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    if (widget.employee.officeEndTime != null) {
      final parts = widget.employee.officeEndTime!.split(':');
      if (parts.length == 2) {
        _officeEndTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(bool newStatus) async {
    if (!newStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate Employee?'),
          content: Text(
            'Are you sure you want to deactivate ${widget.employee.name}? They will not be able to log in or mark attendance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VelocityColors.error,
                foregroundColor: VelocityColors.baseWhite,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ref
          .read(employeeServiceProvider)
          .toggleStatus(widget.employee.id, newStatus);
      setState(() {
        _isActive = newStatus;
      });
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Employee ${newStatus ? "activated" : "deactivated"} successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update basic details
      await ref.read(employeeServiceProvider).updateEmployee(
        widget.employee.id,
        {
          'name': _nameController.text.trim(),
          'department': _departmentController.text.trim(),
          'location': _locationController.text.trim(),
          'staffType': _staffType,
          if (_officeStartTime != null)
            'officeStartTime': '${_officeStartTime!.hour.toString().padLeft(2, '0')}:${_officeStartTime!.minute.toString().padLeft(2, '0')}',
          if (_officeEndTime != null)
            'officeEndTime': '${_officeEndTime!.hour.toString().padLeft(2, '0')}:${_officeEndTime!.minute.toString().padLeft(2, '0')}',
        },
      );

      // 2. Assign role if selected
      if (_selectedRoleId != null && _selectedRoleId!.isNotEmpty) {
        await ref
            .read(employeeServiceProvider)
            .assignRole(widget.employee.id, _selectedRoleId!);
      }

      // 3. Assign site
      await ref
          .read(employeeServiceProvider)
          .assignSite(widget.employee.id, _selectedSiteId);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Employee updated successfully');
        context.router.maybePop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(editRolesListProvider);
    final sitesAsync = ref.watch(editSitesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              widget.employee.name.isNotEmpty
                                  ? widget.employee.name[0].toUpperCase()
                                  : 'E',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.employee.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.employee.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Status Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _isActive
                              ? VelocityColors.success.withValues(alpha: 0.08)
                              : VelocityColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isActive
                                ? VelocityColors.success.withValues(alpha: 0.3)
                                : VelocityColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isActive ? 'Account Active' : 'Account Inactive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _isActive
                                        ? VelocityColors.success
                                        : VelocityColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isActive
                                      ? 'Employee can log in and record attendance'
                                      : 'Employee login is restricted',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              activeThumbColor: VelocityColors.success,
                              onChanged: (val) => _toggleStatus(val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location / City',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _staffType,
                        decoration: const InputDecoration(
                          labelText: 'Staff Type',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'OFFICE', child: Text('OFFICE')),
                          DropdownMenuItem(value: 'SITE', child: Text('SITE')),
                        ],
                        onChanged: (val) {
                          setState(() => _staffType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _officeStartTime ?? const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (time != null) {
                                  setState(() => _officeStartTime = time);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Office Start Time',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(_officeStartTime != null ? _officeStartTime!.format(context) : 'Not Set'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _officeEndTime ?? const TimeOfDay(hour: 17, minute: 0),
                                );
                                if (time != null) {
                                  setState(() => _officeEndTime = time);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Office End Time',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                                child: Text(_officeEndTime != null ? _officeEndTime!.format(context) : 'Not Set'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Assign Role Dropdown
                      rolesAsync.when(
                        data: (roles) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedRoleId,
                            decoration: const InputDecoration(
                              labelText: 'Assign Custom Role (Optional)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Default Employee Role'),
                              ),
                              ...roles.map((r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(r.name.replaceAll('_', ' ')),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedRoleId = val);
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Assign Site Dropdown
                      sitesAsync.when(
                        data: (sites) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedSiteId,
                            decoration: const InputDecoration(
                              labelText: 'Assign Work Site (Optional)',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Any / Main Office'),
                              ),
                              ...sites.map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  )),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedSiteId = val);
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SAVE CHANGES',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
