import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import 'package:flutter_app/features/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../employees/services/employee_service.dart';
import '../../../models/user.dart';
import '../../shared/widgets/states.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/roles_service.dart';
import '../../../models/role.dart';
import 'admin_role_bottom_sheet.dart';

final employeesProvider = FutureProvider.family.autoDispose<List<User>, String>(
  (ref, status) {
    return ref.watch(employeeServiceProvider).getEmployees(status: status);
  },
);

@RoutePage()
class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() =>
      _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isSuperAdmin = user?.role == 'SUPER_ADMIN';
    final tabCount = isSuperAdmin ? 5 : 3;

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return DefaultTabController(
      length: tabCount,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                const Tab(text: 'Approved'),
                const Tab(text: 'Pending Approvals'),
                const Tab(text: 'All'),
                if (isSuperAdmin) const Tab(text: 'Administrators'),
                if (isSuperAdmin) const Tab(text: 'Custom Roles'),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  children: [
                    const _EmployeeList(
                      status: 'APPROVED',
                      key: PageStorageKey('APPROVED'),
                    ),
                    const _EmployeeList(
                      status: 'PENDING',
                      key: PageStorageKey('PENDING'),
                    ),
                    const _EmployeeList(
                      status: 'ALL',
                      key: PageStorageKey('ALL'),
                    ),
                    if (isSuperAdmin)
                      const _AdminList(key: PageStorageKey('ADMINS')),
                    if (isSuperAdmin)
                      const _RoleList(key: PageStorageKey('ROLES')),
                  ],
                ),
                Positioned(
                  bottom: isDesktop ? 16 : 106,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final result = await context.router.push(
                        const RegisterEmployeeRoute(),
                      );
                      if (result == true) {
                        ref.invalidate(employeesProvider);
                      }
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Icon(Icons.person_add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeList extends ConsumerWidget {
  final String status;
  const _EmployeeList({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider(status));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(employeesProvider);
      },
      child: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Employees',
              message: 'There are no employees in this category.',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: AppScaffold.getScrollPadding(
              context,
              basePadding: const EdgeInsets.all(16),
            ),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return _EmployeeCard(emp: emp, statusType: status);
            },
          );
        },
        loading: () => const LoadingStateWidget(),
        error: (err, stack) => ErrorStateWidget(
          error: err.toString(),
          onRetry: () => ref.invalidate(employeesProvider(status)),
        ),
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  final User emp;
  final String statusType;

  const _EmployeeCard({required this.emp, required this.statusType});

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Employee?'),
        content: const Text(
          'Are you sure you want to reject this employee? This action is destructive and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.error,
              foregroundColor: VelocityColors.baseWhite,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(employeeServiceProvider).rejectEmployee(emp.id);
                ref.invalidate(employeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Employee rejected.'),
                      backgroundColor: VelocityColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ErrorHandler.getUserMessage(e)),
                      backgroundColor: VelocityColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'REJECT',
              style: TextStyle(color: VelocityColors.baseWhite),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApproved = emp.isApproved == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          onTap: () async {
            // Edit
            final result = await context.router.push(
              EmployeeProfileEditRoute(employee: emp),
            );
            if (result == true) {
              ref.invalidate(employeesProvider);
            }
          },
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: Theme.of(context).colorScheme.primary,
            radius: 24,
            child: Text(
              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          title: Text(
            emp.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                emp.email,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      emp.role,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (emp.department != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      emp.department!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).unselectedWidgetColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          isThreeLine: true,
          trailing: isApproved
              ? IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).unselectedWidgetColor,
                  ),
                  onPressed: () async {
                    final result = await context.router.push(
                      EmployeeProfileEditRoute(employee: emp),
                    );
                    if (result == true) {
                      ref.invalidate(employeesProvider);
                    }
                  },
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Approve Employee',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: VelocityColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: VelocityColors.success.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          color: VelocityColors.success,
                          size: 20,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(employeeServiceProvider)
                              .approveEmployee(emp.id);
                          ref.invalidate(employeesProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Employee approved.'),
                                backgroundColor: VelocityColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ErrorHandler.getUserMessage(e)),
                                backgroundColor: VelocityColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Reject Employee',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: VelocityColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: VelocityColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: VelocityColors.error,
                          size: 20,
                        ),
                      ),
                      onPressed: () => _showDeleteConfirm(context, ref),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

final adminsProvider = FutureProvider.autoDispose<List<User>>((ref) {
  return ref.watch(employeeServiceProvider).getAdmins();
});

class _AdminList extends ConsumerStatefulWidget {
  const _AdminList({super.key});
  @override
  ConsumerState<_AdminList> createState() => _AdminListState();
}

class _AdminListState extends ConsumerState<_AdminList> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminsProvider);
    return state.when(
      data: (admins) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: admins.length,
        itemBuilder: (ctx, i) {
          final adm = admins[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  radius: 22,
                  child: Text(
                    adm.name.isNotEmpty ? adm.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  adm.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      adm.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Text(
                        adm.role,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Switch(
                  value: adm.isActive ?? true,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) async {
                    await ref
                        .read(employeeServiceProvider)
                        .toggleAdminStatus(adm.id, v);
                    ref.invalidate(adminsProvider);
                  },
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const LoadingStateWidget(),
      error: (e, s) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(adminsProvider),
      ),
    );
  }
}

final rolesProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(rolesServiceProvider).getRoles();
});

class _RoleList extends ConsumerStatefulWidget {
  const _RoleList({super.key});
  @override
  ConsumerState<_RoleList> createState() => _RoleListState();
}

class _RoleListState extends ConsumerState<_RoleList> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolesProvider);
    return state.when(
      data: (roles) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => AdminRoleBottomSheet(
                      onSuccess: () => ref.invalidate(rolesProvider),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('CREATE NEW ROLE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: roles.length,
              itemBuilder: (ctx, i) {
                final role = roles[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => AdminRoleBottomSheet(
                          existingRole: role,
                          onSuccess: () => ref.invalidate(rolesProvider),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.name.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 8,
                                  children: role.permissions.map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                      child: Text(
                                        p.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            tooltip: 'Delete Role',
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: VelocityColors.error.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: VelocityColors.error.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: VelocityColors.error,
                                size: 20,
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Role?'),
                                  content: Text(
                                    'Are you sure you want to delete role "${role.name.replaceAll('_', ' ')}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: VelocityColors.error,
                                        foregroundColor:
                                            VelocityColors.baseWhite,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await ref
                                      .read(rolesServiceProvider)
                                      .deleteRole(role.id);
                                  ref.invalidate(rolesProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Role deleted successfully',
                                        ),
                                        backgroundColor:
                                            VelocityColors.primaryRed,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ErrorHandler.getUserMessage(e),
                                        ),
                                        backgroundColor: VelocityColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      loading: () => const LoadingStateWidget(),
      error: (e, s) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(rolesProvider),
      ),
    );
  }
}
