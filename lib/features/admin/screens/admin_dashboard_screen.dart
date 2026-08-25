import 'package:auto_route/auto_route.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/dashboard_header_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(adminServiceProvider).getDashboardStats();
});

@RoutePage()
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () =>
          const AppScaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => AppScaffold(
        body: Center(child: Text('Error loading dashboard: $err')),
      ),
      data: (stats) {
        return DashboardHeaderScaffold(
          headerHeight: 280.0,
          onRefresh: () async {
            ref.invalidate(adminStatsProvider);
          },
          headerContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const VelocityLogo(height: 28),
              // const SizedBox(height: 20),
              Text(
                'Welcome back, Admin!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here is the daily overview of staff and organizational attendance.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          bodyContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 600;
                    return GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: isDesktop ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isDesktop ? 1.5 : 1.15,
                      children: [
                        _RedesignedStatCard(
                          title: 'APPROVED EMPLOYEES',
                          count: stats['approvedEmployees'] ?? 0,
                          icon: Icons.people_outline,
                          color: Colors.blue.shade700,
                          subtitle: 'Active staff members',
                          isTrendUp: true,
                        ),
                        _RedesignedStatCard(
                          title: 'PENDING EMPLOYEES',
                          count: stats['pendingEmployees'] ?? 0,
                          icon: Icons.person_outline,
                          color: Colors.amber.shade700,
                          subtitle: 'Awaiting registration approval',
                          isTrendUp: false,
                        ),
                        _RedesignedStatCard(
                          title: 'PENDING LEAVES',
                          count: stats['pendingLeaves'] ?? 0,
                          icon: Icons.calendar_today_outlined,
                          color: Colors.purple.shade700,
                          subtitle: 'Leave applications to review',
                          isTrendUp: false,
                        ),
                        _RedesignedStatCard(
                          title: 'PENDING EXCEPTIONS',
                          count: stats['pendingAttendance'] ?? 0,
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          subtitle: 'Late-ins / early-outs pending review',
                          isTrendUp: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Management Control Center
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MANAGEMENT CONTROL CENTER',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ControlCenterCard(
                      icon: Icons.people_outline,
                      title: 'Employee Approvals',
                      subtitle:
                          'Review and approve pending registration requests.',
                      onTap: () => AutoTabsRouter.of(context).setActiveIndex(1),
                    ),
                    const SizedBox(height: 8),
                    _ControlCenterCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Leave Requests',
                      subtitle: 'Process employee leave logs and balances.',
                      onTap: () => AutoTabsRouter.of(context).setActiveIndex(2),
                    ),
                    const SizedBox(height: 8),
                    _ControlCenterCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Exception Requests',
                      subtitle:
                          'Review late-ins, early-outs and other exceptions.',
                      onTap: () => AutoTabsRouter.of(context).setActiveIndex(3),
                    ),
                    const SizedBox(height: 8),
                    _ControlCenterCard(
                      icon: Icons.settings_outlined,
                      title: 'Holidays & Settings',
                      subtitle:
                          'Configure office hours, grace periods & holidays.',
                      onTap: () => AutoTabsRouter.of(context).setActiveIndex(4),
                    ),
                    const SizedBox(height: 8),
                    _ControlCenterCard(
                      icon: Icons.analytics_outlined,
                      title: 'Attendance Reports',
                      subtitle: 'Export monthly or weekly logs to PDF & Excel.',
                      onTap: () => AutoTabsRouter.of(context).setActiveIndex(5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Portal Health Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat(
                          'hh:mm:ss a',
                        ).format(_currentTime).toLowerCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CURRENT OFFICE TIME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PORTAL HEALTH SUMMARY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      (() {
                        final isServerOnline = stats['isServerOnline'] == true;
                        final settings =
                            stats['settings'] as Map<String, dynamic>?;
                        final isGeoActive =
                            settings?['geofencingEnabled'] == true;
                        final radius = settings?['allowedRadiusMeters'] ?? 0;
                        final geoText = isGeoActive
                            ? 'ACTIVE (Radius: ${radius}m)'
                            : 'INACTIVE';

                        return Column(
                          children: [
                            _HealthRow(
                              label: 'Backend Server Status:',
                              value: isServerOnline ? 'ONLINE' : 'OFFLINE',
                              valueColor: isServerOnline
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _HealthRow(
                              label: 'GPS Geo-Fencing:',
                              value: geoText,
                              valueColor: isGeoActive
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _HealthRow(
                              label: 'Pending Tasks:',
                              value:
                                  '${(stats['pendingEmployees'] ?? 0) + (stats['pendingLeaves'] ?? 0) + (stats['pendingAttendance'] ?? 0)} Requests',
                              valueColor: Colors.black54,
                            ),
                          ],
                        );
                      })(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}

class _RedesignedStatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isTrendUp;

  const _RedesignedStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.isTrendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Top Accent Border
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(color: color),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Icon Badge
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      // Trend Chip
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isTrendUp ? Icons.trending_up : Icons.remove,
                          color: color,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlCenterCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ControlCenterCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _HealthRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
