import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../employees/services/employee_service.dart';
import '../services/roles_service.dart';
import '../../shared/widgets/permission_picker.dart';

class AdminCreateAdminSheet extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const AdminCreateAdminSheet({super.key, required this.onSuccess});

  @override
  ConsumerState<AdminCreateAdminSheet> createState() =>
      _AdminCreateAdminSheetState();
}

class _AdminCreateAdminSheetState extends ConsumerState<AdminCreateAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _roleType = 'ADMIN';
  String? _customRoleId;
  List<String> _permissions = [];
  List<String> _systemPermissions = [];
  List<dynamic> _roles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(employeeServiceProvider).createAdmin(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _roleType,
          );
      // Fetch newly created admin list to get ID — assign permissions if any
      final admins = await ref.read(employeeServiceProvider).getAdmins();
      final created = admins.firstWhere(
        (a) => a.email.toLowerCase() == _emailCtrl.text.trim().toLowerCase(),
        orElse: () => admins.last,
      );
      if (_customRoleId != null) {
        await ref
            .read(employeeServiceProvider)
            .assignAdminRole(created.id, _customRoleId);
      }
      if (_permissions.isNotEmpty) {
        await ref
            .read(employeeServiceProvider)
            .assignAdminPermissions(created.id, _permissions);
      }
      widget.onSuccess();
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Admin created successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, ErrorHandler.getUserMessage(e));
      }
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
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create Administrator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: VelocityColors.secondaryBlack,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Minimum 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _roleType,
                    decoration: const InputDecoration(
                      labelText: 'Admin Type',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                      DropdownMenuItem(
                          value: 'SUPER_ADMIN', child: Text('Super Admin')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _roleType = v);
                    },
                  ),
                  if (_roles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _customRoleId,
                      decoration: const InputDecoration(
                        labelText: 'Custom Role (Optional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('None')),
                        ..._roles.map((r) => DropdownMenuItem(
                              value: r.id as String,
                              child: Text(r.name.replaceAll('_', ' ')),
                            )),
                      ],
                      onChanged: (v) => setState(() => _customRoleId = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Direct Permissions (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 280,
                    child: PermissionPicker(
                      availablePermissions: _systemPermissions,
                      selectedPermissions: _permissions,
                      onChanged: (p) => setState(() => _permissions = p),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VelocityColors.baseWhite,
                        ),
                      )
                    : const Text('CREATE ADMIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
