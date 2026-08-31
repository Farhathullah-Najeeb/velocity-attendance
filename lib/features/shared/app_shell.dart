import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../auth/providers/auth_provider.dart';
import 'widgets/velocity_logo.dart';

import '../../core/router/app_router.dart';
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.router.replace(const LoginRoute());
            },
            child: const Text('Logout'),
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
      List<NavigationDestination> destinations) {
    final startIndex = isAdmin ? 4 : 3;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const VelocityLogo(height: 32),
                  const SizedBox(height: 24),
                  Text(
                    user?.name ?? 'Employee',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.role == 'SUPER_ADMIN' || user?.role == 'ADMIN'
                        ? 'Administrator'
                        : 'Staff Member',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
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
                        color: selectedIndex == i ? Theme.of(context).colorScheme.primary : Theme.of(context).unselectedWidgetColor,
                      ),
                      title: Text(
                        destinations[i].label,
                        style: TextStyle(
                          color: selectedIndex == i ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                          fontWeight: selectedIndex == i ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: selectedIndex == i,
                      onTap: () {
                        Navigator.pop(context); // close drawer
                        tabsRouter.setActiveIndex(i);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade600),
              title: Text(
                'Log Out',
                style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context); // close drawer
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
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note),
        label: 'Leaves',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.mark_email_unread_outlined),
        selectedIcon: Icon(Icons.mark_email_unread),
        label: 'Requests',
      ),
      const NavigationDestination(
        icon: Icon(Icons.timer_outlined),
        selectedIcon: Icon(Icons.timer),
        label: 'Overtime',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'My Profile',
      ),
    ];

    final List<NavigationDestination> adminDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Employees',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note),
        label: 'Leave Requests',
      ),
      const NavigationDestination(
        icon: Icon(Icons.warning_amber_outlined),
        selectedIcon: Icon(Icons.warning_amber),
        label: 'Exceptions',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Holidays & Settings',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: 'Reports',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'My Profile',
      ),
    ];

    final destinations = isAdmin ? adminDestinations : employeeDestinations;

    return AutoTabsRouter(
      routes: isAdmin
          ? const [
              AdminDashboardRoute(),
              AdminEmployeesRoute(),
              AdminApprovalsRoute(),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            if (isDesktop) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Row(
                  children: [
                    Container(
                      width: 250, // Fixed width for sidebar
                      color: Colors.white,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 48.0, bottom: 24.0),
                            child: VelocityLogo(height: 40),
                          ),
                          // User Profile Badge in Sidebar
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    user?.name.isNotEmpty == true
                                        ? user!.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.role ?? 'Role',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
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
                          const SizedBox(height: 16),
                          // Navigation Items
                          Expanded(
                            child: ListView.builder(
                              itemCount: destinations.length,
                              itemBuilder: (context, idx) {
                                final d = destinations[idx];
                                final isSelected = selectedIndex == idx;
                                return InkWell(
                                  onTap: () =>
                                      _onItemTapped(idx, isAdmin, tabsRouter),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary.withValues(
                                              alpha: 0.05,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? (d.selectedIcon as Icon?)
                                                        ?.icon ??
                                                    (d.icon as Icon).icon
                                              : (d.icon as Icon).icon,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          d.label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey.shade700,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Log Out button at bottom
                          InkWell(
                            onTap: _handleLogout,
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: child,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile Layout
            return Scaffold(
              key: _scaffoldKey,
              extendBody: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              drawer: _buildDrawer(context, user, isAdmin, selectedIndex, tabsRouter, destinations),
              appBar: AppBar(
                backgroundColor: selectedIndex == 0
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surface,
                iconTheme: Theme.of(context).appBarTheme.iconTheme,
                elevation: 0,
                centerTitle: selectedIndex != 0,
                title: selectedIndex == 0
                    ? const VelocityLogo(height: 28)
                    : Text(
                        destinations[selectedIndex].label,
                        style: TextStyle(
                          color: Theme.of(context).appBarTheme.foregroundColor ??
                              Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                leading: selectedIndex >= (isAdmin ? 4 : 4)
                    ? IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).appBarTheme.iconTheme?.color,
                        ),
                        onPressed: () => tabsRouter.setActiveIndex(0),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => context.router.push(const NotificationsRoute()),
                  ),
                ],
              ),
              body: child,
              bottomNavigationBar: selectedIndex < (isAdmin ? 4 : 4)
                  ? Builder(
                      builder: (context) {
                        // The nav pill is about 90px tall from the bottom.
                        return Container(
                          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: destinations.take(isAdmin ? 4 : 4).toList().asMap().entries.map((entry) {
                            final idx = entry.key;
                            final d = entry.value;
                            final isSelected = selectedIndex == idx;
                            final label = d.label == 'Leave Requests' ? 'Leaves' : d.label;
                            
                            return GestureDetector(
                              onTap: () => tabsRouter.setActiveIndex(idx),
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isSelected ? (d.selectedIcon as Icon).icon : (d.icon as Icon).icon,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        );
                      }
                    )
                  : null, // Hide bottom nav on secondary screens
            );
          },
        );
      },
    );
  }
}
