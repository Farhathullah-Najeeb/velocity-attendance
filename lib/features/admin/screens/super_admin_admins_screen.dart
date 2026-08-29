import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/user.dart';
import '../../employees/services/employee_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/states.dart';
import 'admin_create_admin_sheet.dart';
import 'admin_edit_admin_sheet.dart';

final superAdminAdminsProvider = FutureProvider.autoDispose<List<User>>((ref) {
  return ref.watch(employeeServiceProvider).getAdmins();
});

@RoutePage()
class SuperAdminAdminsScreen extends ConsumerWidget {
  const SuperAdminAdminsScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopLayout(context, ref);
        }
        return _buildMobileLayout(context, ref);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(superAdminAdminsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          error: ErrorHandler.getUserMessage(e),
          onRetry: () => ref.invalidate(superAdminAdminsProvider),
        ),
        data: (admins) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrators',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage super admins and admins for the portal.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: VelocityColors.baseWhite,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          constraints: const BoxConstraints(maxWidth: 600),
builder: (_) => AdminCreateAdminSheet(
                            onSuccess: () => ref.invalidate(superAdminAdminsProvider),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Administrator'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VelocityColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: admins.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Administrators',
                          message: 'Create your first admin to help manage the organization.',
                          icon: Icons.admin_panel_settings_outlined,
                          actionLabel: 'Create Admin',
                          onAction: () {},
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                dataRowMinHeight: 70,
                                dataRowMaxHeight: 70,
                                columns: const [
                                  DataColumn(label: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('PERMISSIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: admins.map((admin) {
                                  final isActive = admin.isActive ?? true;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: VelocityColors.primaryRed.withValues(alpha: 0.1),
                                              foregroundColor: VelocityColors.primaryRed,
                                              child: Text(admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A', style: const TextStyle(fontWeight: FontWeight.w700)),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(admin.email, style: const TextStyle(color: Colors.black87))),
                                      DataCell(_Badge(label: admin.role.replaceAll('_', ' '), color: VelocityColors.primaryRed)),
                                      DataCell(_Badge(label: isActive ? 'Active' : 'Inactive', color: isActive ? VelocityColors.success : VelocityColors.error)),
                                      DataCell(
                                        admin.permissions != null && admin.permissions!.isNotEmpty
                                            ? _Badge(label: '${admin.permissions!.length} permissions', color: VelocityColors.textDark)
                                            : const Text('-'),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          color: Colors.blue.shade700,
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: VelocityColors.baseWhite,
                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                              constraints: const BoxConstraints(maxWidth: 600),
builder: (_) => AdminEditAdminSheet(
                                                admin: admin,
                                                onSuccess: () => ref.invalidate(superAdminAdminsProvider),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(superAdminAdminsProvider);

    return AppScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: VelocityColors.baseWhite,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            constraints: const BoxConstraints(maxWidth: 600),
builder: (_) => AdminCreateAdminSheet(
              onSuccess: () => ref.invalidate(superAdminAdminsProvider),
            ),
          );
        },
        backgroundColor: VelocityColors.primaryRed,
        foregroundColor: VelocityColors.baseWhite,
        child: const Icon(Icons.person_add),
      ),
      body: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async => ref.invalidate(superAdminAdminsProvider),
        child: adminsAsync.when(
          loading: () => const LoadingStateWidget(),
          error: (e, _) => ErrorStateWidget(
            error: ErrorHandler.getUserMessage(e),
            onRetry: () => ref.invalidate(superAdminAdminsProvider),
          ),
          data: (admins) {
            if (admins.isEmpty) {
              return EmptyStateWidget(
                title: 'No Administrators',
                message:
                    'Create your first admin to help manage the organization.',
                icon: Icons.admin_panel_settings_outlined,
                actionLabel: 'Create Admin',
                onAction: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: VelocityColors.baseWhite,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    constraints: const BoxConstraints(maxWidth: 600),
builder: (_) => AdminCreateAdminSheet(
                      onSuccess: () =>
                          ref.invalidate(superAdminAdminsProvider),
                    ),
                  );
                },
              );
            }

            return ListView.builder(
              padding: AppScaffold.getScrollPadding(
                context,
                basePadding: const EdgeInsets.all(16),
              ),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                final isActive = admin.isActive ?? true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: VelocityColors.surfaceLight),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: VelocityColors.baseWhite,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        constraints: const BoxConstraints(maxWidth: 600),
builder: (_) => AdminEditAdminSheet(
                          admin: admin,
                          onSuccess: () =>
                              ref.invalidate(superAdminAdminsProvider),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: VelocityColors.primaryRed
                                .withValues(alpha: 0.1),
                            foregroundColor: VelocityColors.primaryRed,
                            child: Text(
                              admin.name.isNotEmpty
                                  ? admin.name[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  admin.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  admin.email,
                                  style: const TextStyle(
                                    color: VelocityColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _Badge(
                                      label: admin.role.replaceAll('_', ' '),
                                      color: VelocityColors.primaryRed,
                                    ),
                                    _Badge(
                                      label: isActive ? 'Active' : 'Inactive',
                                      color: isActive
                                          ? VelocityColors.success
                                          : VelocityColors.error,
                                    ),
                                    if (admin.permissions != null &&
                                        admin.permissions!.isNotEmpty)
                                      _Badge(
                                        label:
                                            '${admin.permissions!.length} permissions',
                                        color: VelocityColors.textDark,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: VelocityColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
