import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/user.dart';
import '../../employees/services/employee_service.dart';
import '../services/roles_service.dart';
import '../../shared/widgets/permission_picker.dart';

class AdminEditAdminSheet extends ConsumerStatefulWidget {
  final User admin;
  final VoidCallback onSuccess;

  const AdminEditAdminSheet({
    super.key,
    required this.admin,
    required this.onSuccess,
  });

  @override
  ConsumerState<AdminEditAdminSheet> createState() =>
      _AdminEditAdminSheetState();
}

class _AdminEditAdminSheetState extends ConsumerState<AdminEditAdminSheet> {
  List<String> _permissions = [];
  List<String> _systemPermissions = [];
  List<dynamic> _roles = [];
  String? _selectedRoleId;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _permissions = List.from(widget.admin.permissions ?? []);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final perms = await ref.read(rolesServiceProvider).getSystemPermissions();
      final roles = await ref.read(rolesServiceProvider).getRoles();
      if (mounted) {
        setState(() {
          _systemPermissions = perms;
          _roles = roles;
        });
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(employeeServiceProvider)
          .assignAdminPermissions(widget.admin.id, _permissions);
      if (_selectedRoleId != null) {
        await ref
            .read(employeeServiceProvider)
            .assignAdminRole(widget.admin.id, _selectedRoleId);
      }
      widget.onSuccess();
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Admin updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, ErrorHandler.getUserMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeactivate(bool activate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activate ? 'Activate Admin?' : 'Deactivate Admin?'),
        content: Text(
          activate
              ? 'This admin will regain access to the system.'
              : 'This admin will lose access to the system. Continue?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  activate ? VelocityColors.success : VelocityColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(employeeServiceProvider)
          .toggleAdminStatus(widget.admin.id, activate);
      widget.onSuccess();
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          activate ? 'Admin activated' : 'Admin deactivated',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.admin.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.admin.email,
                      style: const TextStyle(color: VelocityColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: VelocityColors.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: VelocityColors.primaryRed.withValues(alpha: 0.2)),
            ),
            child: Text(
              widget.admin.role.replaceAll('_', ' '),
              style: const TextStyle(
                color: VelocityColors.primaryRed,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_roles.isNotEmpty)
            DropdownButtonFormField<String?>(
              initialValue: _selectedRoleId,
              decoration: const InputDecoration(
                labelText: 'Assign Custom Role',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._roles.map((r) => DropdownMenuItem(
                      value: r.id as String,
                      child: Text(r.name.replaceAll('_', ' ')),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedRoleId = v),
            ),
          const SizedBox(height: 8),
          const Text('Permissions', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PermissionPicker(
                    availablePermissions: _systemPermissions,
                    selectedPermissions: _permissions,
                    onChanged: (p) => setState(() => _permissions = p),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmDeactivate(
                      !(widget.admin.isActive ?? true)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: (widget.admin.isActive ?? true)
                        ? VelocityColors.error
                        : VelocityColors.success,
                    side: BorderSide(
                      color: (widget.admin.isActive ?? true)
                          ? VelocityColors.error
                          : VelocityColors.success,
                    ),
                  ),
                  child: Text(
                    (widget.admin.isActive ?? true)
                        ? 'Deactivate'
                        : 'Activate',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePermissions,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VelocityColors.baseWhite,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
