import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
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

final employeesProvider =
    FutureProvider.family.autoDispose<List<User>, String>((ref, status) {
  return ref.watch(employeeServiceProvider).getEmployees(status: status);
});

final adminsProvider = FutureProvider.autoDispose<List<User>>((ref) {
  return ref.watch(employeeServiceProvider).getAdmins();
});

final rolesProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(rolesServiceProvider).getRoles();
});

@RoutePage()
class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() =>
      _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  int _selectedTab = 0; // 0: Employees (Approved), 1: Pending, 2: Admins, 3: Roles
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isSuperAdmin = user?.role == 'SUPER_ADMIN';
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 32 : 16,
          isDesktop ? 28 : 20,
          isDesktop ? 32 : 16,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. PAGE HEADER & CTA
            // =================================================================
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'User Directory Management',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure settings, checkout rules, and account approvals for employees and administrators.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildRegisterButton(context, ref),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'User Directory Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure settings, checkout rules, and account approvals for staff.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildRegisterButton(context, ref),
                ],
              ),
            const SizedBox(height: 20),

            // =================================================================
            // 2. MAIN DIRECTORY CARD CONTAINER
            // =================================================================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Search Bar & Tab Toggle Filter Row ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 750;

                        final searchField = Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                size: 19,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search employees by name, email or department...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 16,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            onPressed: () => setState(
                                                () => _searchQuery = ''),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        final tabPills = Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize:
                                isNarrow ? MainAxisSize.max : MainAxisSize.min,
                            children: [
                              _buildPill(
                                label: 'Employees',
                                icon: Icons.people_alt_outlined,
                                isSelected: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                              const SizedBox(width: 4),
                              _buildPill(
                                label: 'Pending Approvals',
                                icon: Icons.pending_actions_outlined,
                                isSelected: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1),
                              ),
                              if (isSuperAdmin) ...[
                                const SizedBox(width: 4),
                                _buildPill(
                                  label: 'Admins',
                                  icon: Icons.admin_panel_settings_outlined,
                                  isSelected: _selectedTab == 2,
                                  onTap: () => setState(() => _selectedTab = 2),
                                ),
                                const SizedBox(width: 4),
                                _buildPill(
                                  label: 'Custom Roles',
                                  icon: Icons.vpn_key_outlined,
                                  isSelected: _selectedTab == 3,
                                  onTap: () => setState(() => _selectedTab = 3),
                                ),
                              ],
                            ],
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: tabPills,
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: searchField),
                              const SizedBox(width: 16),
                              tabPills,
                            ],
                          );
                        }
                      },
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // --- Table Content based on active tab ---
                  if (_selectedTab == 0)
                    _EmployeeTable(
                      status: 'APPROVED',
                      search: _searchQuery,
                      isDesktop: isDesktop,
                    )
                  else if (_selectedTab == 1)
                    _EmployeeTable(
                      status: 'PENDING',
                      search: _searchQuery,
                      isDesktop: isDesktop,
                    )
                  else if (_selectedTab == 2)
                    _AdminTable(
                      search: _searchQuery,
                      isDesktop: isDesktop,
                    )
                  else
                    _RoleManagerView(
                      isDesktop: isDesktop,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await context.router.push(
            const RegisterEmployeeRoute(),
          );
          if (result == true) {
            ref.invalidate(employeesProvider);
            ref.invalidate(adminsProvider);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text(
          'Register Employee',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VelocityColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3. EMPLOYEE TABLE COMPONENT (Matches the exact sleek layout in screenshot)
// =============================================================================
class _EmployeeTable extends ConsumerWidget {
  final String status;
  final String search;
  final bool isDesktop;

  const _EmployeeTable({
    required this.status,
    required this.search,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider(status));

    return employeesAsync.when(
      data: (employees) {
        final filtered = employees.where((emp) {
          if (search.trim().isEmpty) return true;
          final q = search.toLowerCase();
          return emp.name.toLowerCase().contains(q) ||
              emp.email.toLowerCase().contains(q) ||
              (emp.department ?? '').toLowerCase().contains(q) ||
              emp.role.toLowerCase().contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: EmptyStateWidget(
              title: 'No Staff Records Found',
              message: 'No employees found matching the search criteria.',
              icon: Icons.people_outline_rounded,
            ),
          );
        }

        if (isDesktop) {
          return Column(
            children: [
              // Header Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'EMPLOYEE NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'DEPARTMENT & ROLES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'CHECKOUT RULE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'ACCOUNT STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        'ACTIONS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, i) {
                  final emp = filtered[i];
                  return _EmployeeRowDesktop(emp: emp, status: status);
                },
              ),
            ],
          );
        }

        // Mobile Card List
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final emp = filtered[i];
            return _EmployeeCardMobile(emp: emp, status: status);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(60.0),
        child: Center(
          child: CircularProgressIndicator(color: VelocityColors.primaryRed),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(40.0),
        child: ErrorStateWidget(
          error: err.toString(),
          onRetry: () => ref.invalidate(employeesProvider(status)),
        ),
      ),
    );
  }
}

// =============================================================================
// 4. DESKTOP ROW (Matches the exact screenshot row columns)
// =============================================================================
class _EmployeeRowDesktop extends ConsumerStatefulWidget {
  final User emp;
  final String status;

  const _EmployeeRowDesktop({required this.emp, required this.status});

  @override
  ConsumerState<_EmployeeRowDesktop> createState() =>
      _EmployeeRowDesktopState();
}

class _EmployeeRowDesktopState extends ConsumerState<_EmployeeRowDesktop> {
  bool _hovered = false;

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Employee Registration?'),
        content: const Text(
          'Are you sure you want to reject this employee? This action cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(employeeServiceProvider)
                    .rejectEmployee(widget.emp.id);
                ref.invalidate(employeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Employee rejected.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ErrorHandler.getUserMessage(e)),
                      backgroundColor: VelocityColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject Registration'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.rule_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Checkout Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checkout rules configured for ${widget.emp.name}:',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Standard Checkout Rule (Shift timings apply with grace period regularization)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.emp;
    final isApproved = emp.isApproved == true;
    final isActive = emp.isActive ?? true;

    final initial = emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'U';
    final dept = (emp.department != null && emp.department!.isNotEmpty)
        ? emp.department!.toUpperCase()
        : 'GENERAL';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        color: _hovered ? const Color(0xFFF8FAFC) : Colors.transparent,
        child: Row(
          children: [
            // --- 1. Employee Name with Signature Red Avatar ---
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFE53935).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      emp.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. Email Address ---
            Expanded(
              flex: 3,
              child: Text(
                emp.email,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // --- 3. Department & Roles Capsule ---
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      dept,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. Checkout Rule Capsule Button ---
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _showCheckoutRulesDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Standard Checkout',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 5. Account Status Pill ---
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? (isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFDC2626)
                                  .withValues(alpha: 0.12))
                          : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isApproved
                            ? (isActive
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.25)
                                : const Color(0xFFDC2626)
                                    .withValues(alpha: 0.25))
                            : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      isApproved
                          ? (isActive ? 'ACTIVE' : 'INACTIVE')
                          : 'PENDING',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isApproved
                            ? (isActive
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626))
                            : const Color(0xFFD97706),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 6. Actions (Edit, Role Shield, Power Deactivate) ---
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isApproved) ...[
                    // Edit Button
                    IconButton(
                      tooltip: 'Edit Profile',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () async {
                        final res = await context.router.push(
                          EmployeeProfileEditRoute(employee: emp),
                        );
                        if (res == true) {
                          ref.invalidate(employeesProvider);
                        }
                      },
                    ),
                    const SizedBox(width: 14),

                    // Role / Shield Button
                    IconButton(
                      tooltip: 'Role Permissions',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () {
                        _showCheckoutRulesDialog(context);
                      },
                    ),
                    const SizedBox(width: 14),

                    // Power / Toggle Status Button
                    IconButton(
                      tooltip: isActive
                          ? 'Deactivate Account'
                          : 'Activate Account',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.power_settings_new_rounded,
                        size: 19,
                        color: isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFDC2626),
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(employeeServiceProvider)
                              .toggleAdminStatus(emp.id, !isActive);
                          ref.invalidate(employeesProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ErrorHandler.getUserMessage(e)),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ] else ...[
                    // Approve Action
                    IconButton(
                      tooltip: 'Approve Registration',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
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
                              const SnackBar(
                                content: Text('Employee approved!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ErrorHandler.getUserMessage(e)),
                                backgroundColor: VelocityColors.danger,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    // Reject Action
                    IconButton(
                      tooltip: 'Reject Registration',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      onPressed: () => _showDeleteConfirm(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 5. MOBILE CARD COMPONENT
// =============================================================================
class _EmployeeCardMobile extends ConsumerWidget {
  final User emp;
  final String status;

  const _EmployeeCardMobile({required this.emp, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApproved = emp.isApproved == true;
    final initial = emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emp.email,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                onPressed: () async {
                  final res = await context.router.push(
                    EmployeeProfileEditRoute(employee: emp),
                  );
                  if (res == true) ref.invalidate(employeesProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  emp.department ?? 'GENERAL',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isApproved ? 'ACTIVE' : 'PENDING',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isApproved
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. ADMINISTRATORS TABLE
// =============================================================================
class _AdminTable extends ConsumerWidget {
  final String search;
  final bool isDesktop;

  const _AdminTable({required this.search, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminsProvider);

    return adminsAsync.when(
      data: (admins) {
        final filtered = admins.where((adm) {
          if (search.trim().isEmpty) return true;
          final q = search.toLowerCase();
          return adm.name.toLowerCase().contains(q) ||
              adm.email.toLowerCase().contains(q);
        }).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          itemBuilder: (ctx, i) {
            final adm = filtered[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        VelocityColors.primaryRed.withValues(alpha: 0.12),
                    foregroundColor: VelocityColors.primaryRed,
                    radius: 18,
                    child: Text(
                      adm.name.isNotEmpty ? adm.name[0].toUpperCase() : 'A',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adm.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          adm.email,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      adm.role,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: adm.isActive ?? true,
                    activeThumbColor: VelocityColors.primaryRed,
                    onChanged: (v) async {
                      await ref
                          .read(employeeServiceProvider)
                          .toggleAdminStatus(adm.id, v);
                      ref.invalidate(adminsProvider);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: CircularProgressIndicator(color: VelocityColors.primaryRed),
        ),
      ),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(adminsProvider),
      ),
    );
  }
}

// =============================================================================
// 7. ROLES VIEW
// =============================================================================
class _RoleManagerView extends ConsumerWidget {
  final bool isDesktop;

  const _RoleManagerView({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return rolesAsync.when(
      data: (roles) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Custom System Roles & Permissions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VelocityColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => AdminRoleBottomSheet(
                          onSuccess: () => ref.invalidate(rolesProvider),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Role'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roles.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final r = roles[i];
                return ListTile(
                  title: Text(
                    r.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    r.description ?? 'Custom permission set',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: CircularProgressIndicator(color: VelocityColors.primaryRed),
        ),
      ),
      error: (e, _) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(rolesProvider),
      ),
    );
  }
}
