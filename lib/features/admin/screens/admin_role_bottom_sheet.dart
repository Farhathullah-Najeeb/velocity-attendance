import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_colors.dart';
import '../services/roles_service.dart';
import '../../../models/role.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../shared/widgets/permission_picker.dart';

class AdminRoleBottomSheet extends ConsumerStatefulWidget {
  final Role? existingRole;
  final VoidCallback onSuccess;

  const AdminRoleBottomSheet({
    super.key,
    this.existingRole,
    required this.onSuccess,
  });

  @override
  ConsumerState<AdminRoleBottomSheet> createState() =>
      _AdminRoleBottomSheetState();
}

class _AdminRoleBottomSheetState extends ConsumerState<AdminRoleBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<String> _permissions = [];
  List<String> _systemPermissions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRole != null) {
      _nameCtrl.text = widget.existingRole!.name;
      _descCtrl.text = widget.existingRole!.description ?? '';
      _permissions = List.from(widget.existingRole!.permissions);
    }
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final perms = await ref.read(rolesServiceProvider).getSystemPermissions();
      if (mounted) setState(() => _systemPermissions = perms);
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Role name is required');
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (widget.existingRole == null) {
        await ref.read(rolesServiceProvider).createRole(
              _nameCtrl.text.trim(),
              _descCtrl.text.trim(),
              _permissions,
            );
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Role created successfully');
        }
      } else {
        await ref.read(rolesServiceProvider).updateRole(
              widget.existingRole!.id,
              _nameCtrl.text.trim(),
              _descCtrl.text.trim(),
              _permissions,
            );
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Role updated successfully');
        }
      }
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existingRole == null ? 'Create Role' : 'Edit Role',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: VelocityColors.secondaryBlack,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Role Name (e.g. MANAGER)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Permissions',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PermissionPicker(
              availablePermissions: _systemPermissions,
              selectedPermissions: _permissions,
              onChanged: (p) => setState(() => _permissions = p),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VelocityColors.baseWhite,
                      ),
                    )
                  : const Text('Save Role'),
            ),
          ),
        ],
      ),
    );
  }
}
