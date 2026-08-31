import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../auth/providers/auth_provider.dart';
import 'widgets/velocity_logo.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/velocity_colors.dart';
import '../../models/user.dart';
import 'widgets/notification_badge.dart';

@RoutePage()
class AppShellScreen extends ConsumerStatefulWidget {
  const AppShellScreen({super.key});

  @override
  ConsumerState<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends ConsumerState<AppShellScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index, bool isAdmin, TabsRouter tabsRouter) {
    tabsRouter.setActiveIndex(index);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VelocityColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: VelocityColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your session?',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.router.replace(const LoginRoute());
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    User? user,
    bool isAdmin,
    int selectedIndex,
    TabsRouter tabsRouter,
    List<NavigationDestination> destinations,
  ) {
    final startIndex = isAdmin ? 4 : 3;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const VelocityLogo(height: 32),
                  const SizedBox(height: 20),
                  Text(
                    user?.name ?? 'Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user?.role == 'SUPER_ADMIN' || user?.role == 'ADMIN'
                          ? 'Administrator'
                          : 'Staff Member',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (int i = startIndex; i < destinations.length; i++)
                    ListTile(
                      leading: Icon(
                        (destinations[i].icon as Icon).icon,
                        color: selectedIndex == i
                            ? VelocityColors.primaryRed
                            : const Color(0xFF64748B),
                      ),
                      title: Text(
                        destinations[i].label,
                        style: TextStyle(
                          color: selectedIndex == i
                              ? VelocityColors.primaryRed
                              : const Color(0xFF1E293B),
                          fontWeight: selectedIndex == i
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      selected: selectedIndex == i,
                      onTap: () {
                        Navigator.pop(context);
                        tabsRouter.setActiveIndex(i);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: VelocityColors.danger,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: VelocityColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isSuperAdmin = user?.role == 'SUPER_ADMIN';
    final isAdmin = user?.role == 'ADMIN' || isSuperAdmin;

    final List<NavigationDestination> employeeDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note_rounded),
        label: 'Leaves',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history_rounded),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.mark_email_unread_outlined),
        selectedIcon: Icon(Icons.mark_email_unread_rounded),
        label: 'Requests',
      ),
      const NavigationDestination(
        icon: Icon(Icons.timer_outlined),
        selectedIcon: Icon(Icons.timer_rounded),
        label: 'Overtime',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'My Profile',
      ),
    ];

    final List<NavigationDestination> adminDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description_rounded),
        label: 'Requests',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people_rounded),
        label: 'Employees',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note_rounded),
        label: 'Leave Requests',
      ),
      const NavigationDestination(
        icon: Icon(Icons.warning_amber_outlined),
        selectedIcon: Icon(Icons.warning_amber_rounded),
        label: 'Exceptions',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Holidays & Settings',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics_rounded),
        label: 'Reports',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'My Profile',
      ),
    ];

    final destinations = isAdmin ? adminDestinations : employeeDestinations;

    return AutoTabsRouter(
      routes: isAdmin
          ? const [
              AdminDashboardRoute(),
              AdminApprovalsRoute(),
              AdminEmployeesRoute(),
              EmployeeLeavesRoute(),
              AdminAttendanceApprovalsRoute(),
              AdminSettingsRoute(),
              AdminReportsRoute(),
              ProfileRoute(),
            ]
          : const [
              EmployeeDashboardRoute(),
              EmployeeLeavesRoute(),
              EmployeeHistoryRoute(),
              EmployeeRequestsRoute(),
              EmployeeOvertimeRoute(),
              ProfileRoute(),
            ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        final selectedIndex = tabsRouter.activeIndex;

        if (selectedIndex < 0 || selectedIndex >= destinations.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              tabsRouter.setActiveIndex(0);
            }
          });
        }

        final safeIndex =
            (selectedIndex >= 0 && selectedIndex < destinations.length)
                ? selectedIndex
                : 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 850;

            if (isDesktop) {
              return Scaffold(
                backgroundColor: VelocityColors.background,
                body: Row(
                  children: [
                    // Desktop Sidebar: 60% Red accents, 40% Deep Obsidian Slate
                    Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          right: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 36.0, bottom: 20.0),
                            child: VelocityLogo(height: 38),
                          ),

                          // User Profile Badge in Sidebar
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF334155),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE53935),
                                        Color(0xFFC62828),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE53935)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.role ?? 'Role',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const NotificationBadge(size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Navigation Items with Velocity Red Accent
                          Expanded(
                            child: ListView.builder(
                              itemCount: destinations.length,
                              itemBuilder: (context, idx) {
                                final d = destinations[idx];
                                final isSelected = safeIndex == idx;
                                final iconData = isSelected
                                    ? ((d.selectedIcon as Icon?)?.icon ??
                                        (d.icon as Icon).icon)
                                    : (d.icon as Icon).icon;
                                return _SidebarNavItem(
                                  icon: iconData!,
                                  label: d.label,
                                  isSelected: isSelected,
                                  onTap: () =>
                                      _onItemTapped(idx, isAdmin, tabsRouter),
                                );
                              },
                            ),
                          ),

                          // Log Out button at bottom
                          InkWell(
                            onTap: _handleLogout,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.all(18),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: VelocityColors.danger
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: VelocityColors.danger
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: VelocityColors.danger,
                                    size: 18,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: VelocityColors.danger,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              );
            }

            // Mobile Layout with Modern Dock
            return Scaffold(
              key: _scaffoldKey,
              extendBody: true,
              backgroundColor: VelocityColors.background,
              drawer: _buildDrawer(
                context,
                user,
                isAdmin,
                safeIndex,
                tabsRouter,
                destinations,
              ),
              appBar: AppBar(
                backgroundColor: VelocityColors.baseWhite,
                iconTheme:
                    const IconThemeData(color: VelocityColors.textPrimary),
                elevation: 0,
                centerTitle: safeIndex != 0,
                title: safeIndex == 0
                    ? const VelocityLogo(height: 28)
                    : Text(
                        destinations[safeIndex].label,
                        style: const TextStyle(
                          color: VelocityColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                leading: safeIndex >= (isAdmin ? 4 : 4)
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: VelocityColors.textPrimary,
                        ),
                        onPressed: () => tabsRouter.setActiveIndex(0),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: VelocityColors.textPrimary,
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: VelocityColors.textPrimary,
                    ),
                    onPressed: () =>
                        context.router.push(const NotificationsRoute()),
                  ),
                ],
              ),
              body: child,
              bottomNavigationBar: safeIndex < (isAdmin ? 4 : 4)
                  ? Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 14.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: destinations
                            .take(isAdmin ? 4 : 4)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final idx = entry.key;
                          final d = entry.value;
                          final isSelected = safeIndex == idx;
                          final label = d.label == 'Leave Requests'
                              ? 'Leaves'
                              : d.label;

                          return GestureDetector(
                            onTap: () => tabsRouter.setActiveIndex(idx),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFFE53935),
                                                Color(0xFFC62828),
                                              ],
                                            )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? (d.selectedIcon as Icon).icon
                                          : (d.icon as Icon).icon,
                                      color: isSelected
                                          ? Colors.white
                                          : VelocityColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? VelocityColors.primaryRed
                                          : VelocityColors.textSubtle,
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFFF1F0), Color(0xFFFFE4E6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.isSelected
                ? null
                : (_hovered
                    ? const Color(0xFFF8FAFC)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFFECDD3)
                  : (_hovered
                      ? const Color(0xFFE2E8F0)
                      : Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? const Color(0xFFE53935).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? const Color(0xFFE53935)
                      : (_hovered
                          ? const Color(0xFF0F172A)
                          : VelocityColors.textSubtle),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? const Color(0xFFC62828)
                      : (_hovered
                          ? const Color(0xFF0F172A)
                          : VelocityColors.textSecondary),
                  fontWeight:
                      widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              if (widget.isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
