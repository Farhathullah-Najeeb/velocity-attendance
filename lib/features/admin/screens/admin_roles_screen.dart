import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/role.dart';
import '../services/roles_service.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/states.dart';
import 'admin_role_bottom_sheet.dart';

final adminRolesListProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(rolesServiceProvider).getRoles();
});

@RoutePage()
class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, Role role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role?'),
        content: Text(
          'Are you sure you want to delete "${role.name.replaceAll('_', ' ')}"? Users assigned this role may lose permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(rolesServiceProvider).deleteRole(role.id);
                ref.invalidate(adminRolesListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Role deleted'),
                      backgroundColor: VelocityColors.primaryRed,
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(adminRolesListProvider);

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
            builder: (_) => AdminRoleBottomSheet(
              onSuccess: () => ref.invalidate(adminRolesListProvider),
            ),
          );
        },
        backgroundColor: VelocityColors.primaryRed,
        foregroundColor: VelocityColors.baseWhite,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async => ref.invalidate(adminRolesListProvider),
        child: rolesAsync.when(
          loading: () => const LoadingStateWidget(),
          error: (e, _) => ErrorStateWidget(
            error: ErrorHandler.getUserMessage(e),
            onRetry: () => ref.invalidate(adminRolesListProvider),
          ),
          data: (roles) {
            if (roles.isEmpty) {
              return EmptyStateWidget(
                title: 'No Custom Roles',
                message:
                    'Create roles with specific permissions to assign to employees and admins.',
                icon: Icons.badge_outlined,
                actionLabel: 'Create Role',
                onAction: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: VelocityColors.baseWhite,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => AdminRoleBottomSheet(
                      onSuccess: () => ref.invalidate(adminRolesListProvider),
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
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
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
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => AdminRoleBottomSheet(
                          existingRole: role,
                          onSuccess: () =>
                              ref.invalidate(adminRolesListProvider),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  role.name.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: VelocityColors.error,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, ref, role),
                              ),
                            ],
                          ),
                          if (role.description != null &&
                              role.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              role.description!,
                              style: const TextStyle(
                                color: VelocityColors.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: role.permissions.map((p) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: VelocityColors.primaryRed.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: VelocityColors.primaryRed.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  p.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: VelocityColors.textDark,
                                  ),
                                ),
                              );
                            }).toList(),
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
